import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';

import 'package:super_logger/core/models/filters.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/features/composite/models/composite_log.dart';
import 'package:super_logger/features/composite/models/composite_properties.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';

Widget _getEditWidget({
  required _CompositeLogFilterType filterType,
  required ValueEitherController<_CompositeLogFilter> controller,
  required CompositeProperties properties,
  ValueFilter? filter,
}) {
  switch (filterType) {
    case _CompositeLogFilterType.containsLoggable:
      if (filter != null) controller.setRightValue(filter as _CompositeLogFilter, notify: false);
      return SelectContainsLoggable(
          properties: properties,
          controller: controller as ValueEitherController<_ContainsCategoriesFilter>);
    case _CompositeLogFilterType.nestedLoggable:
      return Container();
  }
}

class _FilterControllerAndEditWidget {
  _CompositeLogFilterType type;
  ValueEitherController<_CompositeLogFilter> filterController;
  Widget editFilter;
  _FilterControllerAndEditWidget({
    required this.type,
    required this.filterController,
    required this.editFilter,
  });
}

enum _CompositeLogFilterType { containsLoggable, nestedLoggable }

abstract class _CompositeLogFilter implements ValueFilter {
  _CompositeLogFilterType get type;
}

class _ContainsCategoriesFilter implements _CompositeLogFilter {
  final IList<String> loggableIdList;
  _ContainsCategoriesFilter(this.loggableIdList);

  @override
  bool shouldRemove(dynamic value) {
    final currentLogIdList = (value as CompositeLog).entryList.map((e) => e.loggableId);
    return loggableIdList.any((id) => currentLogIdList.contains(id) == false);
  }

  @override
  _CompositeLogFilterType get type => _CompositeLogFilterType.containsLoggable;
}

class _NestedLoggableFilter implements _CompositeLogFilter {
  final String loggableId;
  final IList<ValueFilter> filters;
  final bool removeIfNotExists;
  _NestedLoggableFilter(this.loggableId, this.filters, this.removeIfNotExists);
  @override
  bool shouldRemove(dynamic value) {
    return false;
  }

  @override
  _CompositeLogFilterType get type => _CompositeLogFilterType.nestedLoggable;
}

class CompositeFilterForm extends StatefulWidget {
  const CompositeFilterForm({Key? key, required this.controller, required this.properties})
      : super(key: key);
  final ValueEitherController<ValueFilter> controller;
  final CompositeProperties properties;

  @override
  _CompositeFilterFormState createState() => _CompositeFilterFormState();
}

class _CompositeFilterFormState extends State<CompositeFilterForm> {
  //final List<ValueEitherController<_CompositeLogFilter>> _filterControllerList = [];

  final List<_FilterControllerAndEditWidget> _filterControllerAndWidget = [];

  void _filtersControllerListener() {
    IList<ValueFilter> filters = <ValueFilter>[].lock;
    String? errorMsg;
    for (final controllerAndWidget in _filterControllerAndWidget) {
      final filter = controllerAndWidget.filterController.value.fold(
        (l) {
          errorMsg = l;
          return null;
        },
        (r) => r,
      );
      if (filter == null) {
        break;
      }

      filters = filters.add(filter);
    }

    setState(() {
      if (errorMsg != null) {
        widget.controller.setErrorValue(errorMsg!);
      } else {
        //widget.controller.setRightValue(filters);
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // reuse the value
    if (widget.controller.isSetUp) {
      widget.controller.value.fold(
        (l) => null,
        (r) {
          for (final filter in []) {
            final type = (filter as _CompositeLogFilter).type;
            late final ValueEitherController<_CompositeLogFilter> controller;
            switch (type) {
              case _CompositeLogFilterType.containsLoggable:
                controller = ValueEitherController<_ContainsCategoriesFilter>();
                break;
              case _CompositeLogFilterType.nestedLoggable:
                controller = ValueEitherController<_NestedLoggableFilter>();
                break;
            }
            controller.addListener(_filtersControllerListener);
            _filterControllerAndWidget.add(
              _FilterControllerAndEditWidget(
                type: type,
                filterController: controller,
                editFilter: _getEditWidget(
                    filterType: type,
                    controller: controller,
                    filter: filter,
                    properties: widget.properties),
              ),
            );
          }
        },
      );
    } else {
      widget.controller.setErrorValue("no value", notify: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_filterControllerAndWidget.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                final controller = ValueEitherController<_ContainsCategoriesFilter>();
                controller.addListener(_filtersControllerListener);
                _filterControllerAndWidget.add(
                  _FilterControllerAndEditWidget(
                    type: _CompositeLogFilterType.containsLoggable,
                    filterController: controller,
                    editFilter: _getEditWidget(
                        filterType: _CompositeLogFilterType.containsLoggable,
                        controller: controller,
                        //filter: _ContainsCategoriesFilter(<String>[].lock),
                        properties: widget.properties),
                  ),
                );
              });
            },
            child: Text(context.l10n.addFilter),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: _filterControllerAndWidget.map(
          (controllerAndWidget) {
            return _getEditWidget(
                filterType: controllerAndWidget.type,
                controller: controllerAndWidget.filterController,
                properties: widget.properties);
            //return controllerAndWidget.editFilter;
          },
        ).toList(),
      );
    }
  }
}

class SelectContainsLoggable extends StatefulWidget {
  const SelectContainsLoggable({
    Key? key,
    required this.properties,
    required this.controller,
  }) : super(key: key);
  final CompositeProperties properties;
  final ValueEitherController<_ContainsCategoriesFilter> controller;

  @override
  State<SelectContainsLoggable> createState() => _SelectContainsLoggableState();
}

class _SelectContainsLoggableState extends State<SelectContainsLoggable> {
  late IList<String> _loggableIdList;

  @override
  void initState() {
    super.initState();
    if (widget.controller.isSetUp) {
      _loggableIdList =
          widget.controller.value.fold((l) => <String>[].lock, (r) => r.loggableIdList);
    } else {
      _loggableIdList = <String>[].lock;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Contains loggable",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.properties.loggables.map((loggable) {
              return SwitchListTile(
                  //dense: true,
                  //controlAffinity: ListTileControlAffinity.leading,
                  value: _loggableIdList.contains(loggable.id),
                  title: Text(loggable.title),
                  onChanged: (shouldContain) {
                    //onChanged(loggable.id, s);
                    //if (shouldContain == null) return;
                    if (shouldContain) {
                      if (_loggableIdList.contains(loggable.id) == false) {
                        _loggableIdList = _loggableIdList.add(loggable.id);
                        if (_loggableIdList.length == widget.properties.loggables.length) {
                          widget.controller.setErrorValue(
                              "All categories are selected, no filter will be applied");
                        } else {
                          widget.controller
                              .setRightValue(_ContainsCategoriesFilter(_loggableIdList));
                        }
                      }
                    } else {
                      if (_loggableIdList.contains(loggable.id)) {
                        _loggableIdList = _loggableIdList.removeWhere((id) => id == loggable.id);
                        if (_loggableIdList.isEmpty) {
                          widget.controller.setErrorValue("No loggable selected");
                        } else {
                          widget.controller
                              .setRightValue(_ContainsCategoriesFilter(_loggableIdList));
                        }
                      }
                    }
                  });
            }).toList(),
          ),
        ),
      ],
    );
  }
}
