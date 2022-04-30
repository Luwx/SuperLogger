import 'dart:ui';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_factory.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/core/models/loggable_settings.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/core/presentation/theme/dimensions.dart';
import 'package:super_logger/features/composite/models/base_loggable_for_composite.dart';
import 'package:super_logger/features/composite/models/composite_properties.dart';
import 'package:super_logger/features/composite/models/computations.dart';
import 'package:super_logger/features/composite/presentation/composite_properties_form/edit_calculation_form.dart';

import 'package:super_logger/locator.dart';
import 'package:fpdart/fpdart.dart' show Right;
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/id_generator.dart';
import 'package:super_logger/utils/value_controller.dart';

class EditCompositePropertiesForm extends StatefulWidget {
  final CompositeProperties? compositeProperties;
  //final ValueController<BaseLoggable<List<Map<String, dynamic>>>>? controller;
  final ValueEitherValidOrErrController<MappableObject> controller;

  const EditCompositePropertiesForm({Key? key, this.compositeProperties, required this.controller})
      : super(key: key);

  @override
  _EditCompositePropertiesFormState createState() => _EditCompositePropertiesFormState();
}

class _EditCompositePropertiesFormState extends State<EditCompositePropertiesForm> {
  bool _showSubCatsSideBySideToggleTile = false;

  CompositeProperties get _currentProperties {
    return widget.controller.valueNoValidation as CompositeProperties;
  }

  void _setProperties(CompositeProperties properties) {
    _showSubCatsSideBySideToggleTile = properties.canShowSubCatsSideBySide;
    widget.controller.setValue(Right(properties));
  }

  @override
  void initState() {
    super.initState();
    if (!widget.controller.isSetUp) {
      if (widget.compositeProperties != null) {
        widget.controller.setValue(Right(widget.compositeProperties!));

        if (widget.compositeProperties!.canShowSubCatsSideBySide) {
          _showSubCatsSideBySideToggleTile = true;
        }
      } else {
        widget.controller.setValue(
          Right(CompositeProperties.defaults()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            height: 12,
          ),
          SwitchListTile(
            value: _currentProperties.isOrGroup,
            title: Text("Is OR group"),
            onChanged: (val) {
              setState(() {
                _setProperties(_currentProperties.copyWith(isOrGroup: val));
              });
            },
          ),
          AnimatedCrossFade(
            firstChild: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  value: _currentProperties.displaySideBySide,
                  title: Text(context.l10n.showSideBySide),
                  onChanged: (val) {
                    setState(() {
                      _setProperties(_currentProperties.copyWith(displaySideBySide: val));
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    enabled: _currentProperties.displaySideBySide,
                    initialValue: _currentProperties.sideBySideDelimiter,
                    decoration: InputDecoration(
                      isDense: true,
                      label: Text(context.l10n.delimiter),
                    ),
                    onChanged: (s) {
                      setState(() {
                        _setProperties(
                          _currentProperties.copyWith(sideBySideDelimiter: s),
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
              ],
            ),
            secondChild: const SizedBox(
              width: double.maxFinite,
            ),
            crossFadeState: _showSubCatsSideBySideToggleTile
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: kThemeAnimationDuration,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.loggables,
                  style: Theme.of(context).textTheme.headline6,
                ),
                Expanded(
                  child: Container(),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _showAddLoggableDialog(context);
                  },
                  label: Text(context.l10n.addLoggable),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Material(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              // child: ListView.builder(
              //   //clipBehavior: null,
              //   itemBuilder: buildItem,
              //   shrinkWrap: true,
              //   itemCount: _currentProperties.categories.length,
              // ),
              child: ReorderableListView.builder(
                physics: const ClampingScrollPhysics(),
                itemBuilder: buildItem,
                itemCount: _currentProperties.loggables.length,
                onReorder: (oldIndex, newIndex) {
                  // why this if? stupid bug: https://github.com/flutter/flutter/issues/24786
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }

                  final categories = _currentProperties.loggables.unlock;
                  final loggable = categories.removeAt(oldIndex);
                  categories.insert(newIndex, loggable);
                  _setProperties(
                    _currentProperties.copyWith(
                      loggables: categories.lock,
                    ),
                  );
                },
                proxyDecorator: (Widget child, int index, Animation<double> animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (BuildContext context, Widget? child) {
                      final double animValue = Curves.easeInOut.transform(animation.value);
                      final double elevation = lerpDouble(0, 6, animValue)!;
                      return Material(
                        borderRadius: BorderRadius.circular(12),
                        color: Color.lerp(Theme.of(context).colorScheme.primary,
                            Theme.of(context).scaffoldBackgroundColor, 0.94 + 0.06 * animValue),
                        elevation: elevation,
                        child: child,
                      );
                    },
                    child: child,
                  );
                },
                shrinkWrap: true,
              ),
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.calculations,
                  style: Theme.of(context).textTheme.headline6,
                ),
                Expanded(
                  child: Container(),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  onPressed: _currentProperties.loggables.isNotEmpty
                      ? () {
                          _showAddComputationDialog(context);
                        }
                      : null,
                  label: Text(context.l10n.addCalculation),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Material(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _currentProperties.calculations.length,
                itemBuilder: (context, index) {
                  final computation = _currentProperties.calculations[index];
                  return ListTile(
                    title: Text(computation.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () async {
                            final editedCalculation = await Navigator.push<NumericCalculation>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditCalculationForm(
                                    computation: _currentProperties.calculations[index],
                                    index: index,
                                    properties: _currentProperties),
                              ),
                            );

                            if (editedCalculation != null) {
                              _setProperties(
                                _currentProperties.copyWith(
                                  calculations:
                                      _currentProperties.calculations.put(index, editedCalculation),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _setProperties(
                                _currentProperties.copyWith(
                                    calculations: _currentProperties.calculations.removeAt(index)),
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return GestureDetector(
      key: ValueKey(_currentProperties.loggables[index].id),
      child: ListTile(
        title: Wrap(
          //crossAxisAlignment: CrossAxisAlignment.end,
          //alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(_currentProperties.loggables[index].title),
            const SizedBox(
              width: 10,
            ),
            Text(
              _currentProperties.loggables[index].type.name,
              style: Theme.of(context).textTheme.caption,
            )
          ],
        ),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[Text((index + 1).toString())],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final loggable = _currentProperties.loggables[index];
                  final uiHelper = locator.get<MainFactory>().getUiHelper(loggable.type);

                  FocusScope.of(context).unfocus();
                  final LoggableForComposite? newLoggable = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditChildLoggable(
                        loggable: loggable,
                        loggableType: loggable.type,
                        uiHelper: uiHelper,
                        level: _currentProperties.level,
                      ),
                    ),
                  );

                  if (newLoggable != null) {
                    setState(() {
                      final currentList = _currentProperties.loggables.unlock;
                      currentList[index] = newLoggable;
                      _setProperties(_currentProperties.copyWith(loggables: currentList.lock));
                    });
                  }
                }),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  String id = _currentProperties.loggables[index].id;
                  _setProperties(
                    _currentProperties.copyWith(
                      loggables:
                          _currentProperties.loggables.where((cat) => cat.id != id).toIList(),
                    ),
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLoggableDialog(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return alert dialog object

        List<SimpleDialogOption> options = [];

        List<LoggableFactory> factories = locator
            .get<MainFactory>()
            .getFactories()
            .where((catFactory) => CompositeProperties.supportedTypes.contains(catFactory.type))
            .toList();

        // no nested composite categories beyond maximum level
        factories.removeWhere((element) =>
            element.type == LoggableType.composite &&
            _currentProperties.level >
                (CompositeProperties.maximumLevel - 1).clamp(0, CompositeProperties.maximumLevel));

        for (final loggableFactory in factories) {
          options.add(SimpleDialogOption(
            child: ListTile(
              //contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              visualDensity: VisualDensity.compact,
              leading: Icon(loggableFactory.getLoggableTypeDescription().icon),
              title: Text(loggableFactory.getLoggableTypeDescription().title),
            ),
            onPressed: () async {
              final LoggableForComposite? newLoggable = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditChildLoggable(
                    loggableType: loggableFactory.type,
                    uiHelper: loggableFactory.getUiHelper(),
                    level: _currentProperties.level,
                  ),
                ),
              );

              if (newLoggable != null) {
                setState(() {
                  _setProperties(
                    _currentProperties.copyWith(
                      loggables: _currentProperties.loggables.add(newLoggable),
                    ),
                  );
                });
              }
              Navigator.pop(context);
            },
          ));
        }

        return SimpleDialog(
          title: Text(context.l10n.chooseLoggableType),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          children: options,
        );
      },
    );
  }

  void _showAddComputationDialog(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return alert dialog object

        List<SimpleDialogOption> options = [];

        for (final computationType in NumericOperationType.values) {
          options.add(
            SimpleDialogOption(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(computationType.name),
              ),
              onPressed: () async {
                final newComputation = await Navigator.push<NumericCalculation>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditCalculationForm(
                      computation: NumericCalculation.makeEmpty(),
                      index: null,
                      properties: _currentProperties,
                    ),
                  ),
                );

                if (newComputation != null) {
                  setState(
                    () {
                      _setProperties(
                        _currentProperties.copyWith(
                          calculations: _currentProperties.calculations.add(newComputation),
                        ),
                      );
                    },
                  );
                }
                Navigator.pop(context);
              },
            ),
          );
        }

        return SimpleDialog(
          title: Text(context.l10n.chooseLoggableType),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          children: options,
        );
      },
    );
  }
}

class EditChildLoggable extends StatefulWidget {
  const EditChildLoggable(
      {Key? key,
      required this.loggableType,
      required this.uiHelper,
      this.loggable,
      required this.level})
      : super(key: key);

  final LoggableType loggableType;
  final LoggableForComposite? loggable;
  final LoggableUiHelper uiHelper;
  final int level;

  @override
  State<EditChildLoggable> createState() => _EditChildLoggableState();
}

class _EditChildLoggableState extends State<EditChildLoggable> {
  bool _titleValid = true;
  late TextEditingController _titleController;

  late final ValueEitherValidOrErrController<MappableObject> _loggablePropertiesController;

  late bool _isArrayable;
  late bool _isDismissible;
  late bool _hiddenByDefault;
  late bool _hideDisplayTitle;

  MappableObject? _nestedCompositePropertiesInitialValue;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.loggable?.title);
    _loggablePropertiesController = ValueEitherValidOrErrController<MappableObject>();
    _isArrayable = widget.loggable?.isArrayable ?? false;
    _isDismissible = widget.loggable?.isDismissible ?? false;
    _hiddenByDefault = widget.loggable?.isHiddenByDefault ?? false;
    _hideDisplayTitle = widget.loggable?.hideTitle ?? false;

    if (widget.loggableType == LoggableType.composite && widget.loggable == null) {
      _nestedCompositePropertiesInitialValue =
          CompositeProperties.defaults().copyWith(level: widget.level + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.loggable == null ? context.l10n.createSubLoggable : widget.loggable!.title),
        actions: [
          TextButton(
            onPressed: () {
              if (_titleController.text.isEmpty) {
                setState(() {
                  _titleValid = false;
                });
                return;
              }

              if (_loggablePropertiesController.isSetUp) {
                _loggablePropertiesController.value.fold(
                  (l) => null, // TODO: show error
                  (properties) {
                    // this settings will not be used by the loggable
                    // so it's value doesn't matter
                    LoggableSettings settings = const LoggableSettings(
                      pinned: false,
                      maxEntriesPerDay: 5,
                      symbol: '',
                      color: null,
                    );

                    Navigator.pop(
                      context,
                      LoggableForComposite(
                        id: widget.loggable?.id ?? generateId(),
                        title: _titleController.text,
                        type: widget.loggableType,
                        properties: properties,
                        isArrayable: _isArrayable,
                        isHiddenByDefault: _hiddenByDefault,
                        isDismissible: _isDismissible,
                        hideTitle: _hideDisplayTitle,
                      ),
                    );
                  },
                );
              }
            },
            child: Text(
              context.l10n.save,
              style: TextStyle(
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          //mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: AppDimens.defaultSpacing,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.defaultSpacing),
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                    label: Text(context.l10n.loggableTitle),
                    errorText: _titleValid ? null : context.l10n.chooseAName),
                onChanged: (value) {
                  if (value.isEmpty) {
                    setState(() {
                      _titleValid = false;
                    });
                  } else if (!_titleValid && value.isNotEmpty) {
                    setState(() {
                      _titleValid = true;
                    });
                  }
                },
              ),
            ),
            SwitchListTile(
              value: _isArrayable,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 22),
              secondary: const Icon(Icons.list_rounded),
              title: Text(context.l10n.multipleEntries),
              onChanged: (value) {
                setState(() {
                  _isArrayable = value;
                });
              },
            ),
            SwitchListTile(
              value: _isDismissible,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 22),
              secondary: const Icon(Icons.cancel_outlined),
              title: Text(context.l10n.dismissible),
              onChanged: (value) {
                setState(() {
                  _isDismissible = value;
                  if (!value) {
                    _hiddenByDefault = false;
                  }
                });
              },
            ),
            SwitchListTile(
              value: _hiddenByDefault,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 22),
              secondary: const Icon(Icons.visibility_off),
              title: Text(context.l10n.hiddenByDefault),
              onChanged: _isDismissible
                  ? (value) {
                      setState(() {
                        _hiddenByDefault = value;
                      });
                    }
                  : null,
            ),
            SwitchListTile(
              value: _hideDisplayTitle,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 22),
              secondary: const Icon(Icons.visibility_off),
              title: Text(context.l10n.hideTitle),
              onChanged: (value) {
                setState(() {
                  _hideDisplayTitle = value;
                });
              },
            ),
            const SizedBox(
              height: 16,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                child: Text(
                  context.l10n.loggableConfiguration,
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 22),
              child: widget.uiHelper.getGeneralConfigForm(
                originalProperties:
                    _nestedCompositePropertiesInitialValue ?? widget.loggable?.properties,
                propertiesController: _loggablePropertiesController,
              ),
            ),
            const SizedBox(
              height: 22,
            ),
          ],
        ),
      ),
    );
  }
}
