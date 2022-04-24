import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/main_factory.dart';

import 'package:super_logger/features/composite/models/base_loggable_for_composite.dart';
import 'package:super_logger/features/composite/models/composite_log.dart';
import 'package:super_logger/features/composite/models/composite_properties.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';

enum _MenuOptions { dissmiss }

class CompositeLogInput extends StatefulWidget {
  const CompositeLogInput({
    Key? key,
    required this.controller,
    required this.compositeProperties,
    this.forDialog = true,
    this.forInputForm = true,
  }) : super(key: key);
  final CompositeProperties compositeProperties;
  final ValueEitherController<CompositeLog> controller;
  final bool forDialog;
  final bool forInputForm;

  @override
  _CompositeLogInputState createState() => _CompositeLogInputState();
}

class _CompositeLogInputState extends State<CompositeLogInput> {
  final List<CompositeEntry> _logsWithDeletedCategories = [];
  final List<_BaseLoggableAndController> _loggableAndControllers = [];

  late bool _showChooseLoggableButton;

  void _loggableControllerListener() {
    List<CompositeEntry> entryList = [];
    bool isValid = true;
    String? errorMsg;

    if (_loggableAndControllers.isEmpty) {
      widget.controller.setErrorValue("Cannot have empty log");
      return;
    }

    for (int i = 0; i < _loggableAndControllers.length; i++) {
      final shouldContinue = _loggableAndControllers[i].when(
        single: (singleLoggableAndController) {
          if (singleLoggableAndController.widgetAndController.controller != null) {
            if (singleLoggableAndController.widgetAndController.controller!.isSetUp) {
              final value = singleLoggableAndController.widgetAndController.controller!.value.fold(
                (error) {
                  errorMsg = error;
                  return null;
                },
                (validValue) => validValue,
              );

              if (value == null) {
                isValid = false;
                return false;
              }

              entryList.add(
                CompositeSingleEntry(
                    loggableId: singleLoggableAndController.loggableId,
                    type: singleLoggableAndController.type,
                    value: value),
              );
              return true;
            } else {
              //throw Exception("Controller is not set up");
              return false;
            }
          } else {
            // deleted loggable
            // just add along
            final logRemains = _logsWithDeletedCategories.firstWhere(
                (element) => element.loggableId == _loggableAndControllers[i].loggableId);

            entryList.add(
              logRemains.when(
                singleEntry: (singleEntry) {
                  return CompositeSingleEntry(
                      loggableId: singleEntry.loggableId,
                      type: singleEntry.type,
                      value: singleEntry.value);
                },
                // not necessary?
                multiEntry: (multiEntry) {
                  return CompositeMultiEntry(
                      loggableId: multiEntry.loggableId,
                      type: multiEntry.type,
                      values: multiEntry.values);
                },
              ),
            );

            return true;
          }
        },
        multi: (multi) {
          if (multi.loggable != null) {
            List<dynamic> values = [];
            for (final widgetAndController in multi.widgetAndController) {
              if (widgetAndController.controller!.isSetUp) {
                final value = widgetAndController.controller!.value.fold(
                  (error) {
                    errorMsg = error;
                    return null;
                  },
                  (validValue) => validValue,
                );

                if (value == null) {
                  isValid = false;
                  return false;
                }

                values.add(value);
              } else {
                throw Exception("Controller ${widgetAndController.controller} is not set up");
                //return true;
              }
            }

            entryList.add(
              CompositeMultiEntry(
                  loggableId: multi.loggableId, type: multi.type, values: values.lock),
            );
            return true;
          } else {
            // deleted loggable
            // just add along
            final logRemains = _logsWithDeletedCategories.firstWhere(
                (element) => element.loggableId == _loggableAndControllers[i].loggableId);

            entryList.add(
              logRemains.when(
                singleEntry: (singleEntry) {
                  return CompositeSingleEntry(
                      loggableId: singleEntry.loggableId,
                      type: singleEntry.type,
                      value: singleEntry.value);
                },
                // not necessary?
                multiEntry: (multiEntry) {
                  return CompositeMultiEntry(
                      loggableId: multiEntry.loggableId,
                      type: multiEntry.type,
                      values: multiEntry.values);
                },
              ),
            );
            return true;
          }
        },
      );
      if (!shouldContinue) break;
    }

    if (isValid) {
      widget.controller.setRightValue(CompositeLog(entryList: entryList.lock));
    } else {
      widget.controller.setErrorValue(errorMsg ?? "invalid");
    }
  }

  void _addLoggableAndController(
    LoggableForComposite loggable,
    LoggableUiHelper uiHelper,
    ValueEitherController<dynamic> valueController, {
    logValue,
  }) {
    // dummy value
    final widgetAndController =
        _WidgetAndController(displayWidget: const SizedBox.shrink(), controller: valueController);

    _BaseLoggableAndController loggableAndController = loggable.isArrayable
        ? _MultiLoggableAndController(
            loggableId: loggable.id,
            loggable: loggable,
            type: loggable.type,
            widgetAndController: [widgetAndController],
          )
        : _SingleLoggableAndController(
            loggable: loggable,
            loggableId: loggable.id,
            type: loggable.type,
            widgetAndController: widgetAndController,
          );

    _loggableAndControllers.add(loggableAndController);

    // TODO: Refactor the logic and use some "getLatestValue" method instead of this broadcast aproach
    // Why actually add the editLogValue widget here and not there at the top?
    // When building the editWidget (right now bellow), in its initState, the value is imediatly broadcasted
    // throught the valueController, and the _loggableControllerListener will receive the signal (not the value)
    // however, since it doesnt have this widgetAndController available yet, the value will be lost in the broadcast chain
    // thus we need to add the loggableAndController first and then add the editWidget latter
    widgetAndController.displayWidget = uiHelper.getEditEntryValueWidget(
        loggable.properties, valueController, logValue,
        forDialog: widget.forDialog, forComposite: true);
  }

  @override
  void initState() {
    super.initState();

    // mount only categories that are present in the log
    if (widget.controller.isSetUp) {
      final logs = widget.controller.value.fold(
        (l) => null, // not used ?
        (r) => r,
      );

      if (logs != null) {

        // was created as part of a OR group
        // we enable the option to change the loggable
        if (widget.compositeProperties.isOrGroup && logs.entryList.length == 1) {
          //_showChooseLoggableButton = true;
        }

        for (final log in logs.entryList) {
          LoggableForComposite? loggable = widget.compositeProperties.loggables
              .firstWhereOrNull((cat) => cat.id == log.loggableId);

          if (loggable == null) {
            log.when(
              singleEntry: (singleEntry) {
                _logsWithDeletedCategories.add(singleEntry);
                _loggableAndControllers.add(
                  _SingleLoggableAndController(
                    loggableId: log.loggableId,
                    loggable: null,
                    type: log.type,
                    widgetAndController: _WidgetAndController(
                        displayWidget: Text(singleEntry.value.toString()), controller: null),
                  ),
                );
              },
              multiEntry: (multiEntry) {
                _loggableAndControllers.add(
                  _MultiLoggableAndController(
                    loggableId: log.loggableId,
                    loggable: null,
                    type: log.type,
                    widgetAndController: multiEntry.values
                        .map((e) => _WidgetAndController(
                            displayWidget: Text(e.toString()), controller: null))
                        .toList(),
                  ),
                );
              },
            );
          } else {
            log.when(
              singleEntry: (singleEntry) {
                final uiHelper = locator.get<MainFactory>().getUiHelper(loggable.type);
                final ValueEitherController valueController =
                    locator.get<MainFactory>().createValueController(loggable.type);

                valueController.addListener(_loggableControllerListener);
                var logValue = singleEntry.value;

                _addLoggableAndController(loggable, uiHelper, valueController, logValue: logValue);
              },
              multiEntry: (multiEntry) {
                final uiHelper = locator.get<MainFactory>().getUiHelper(loggable.type);
                List<_WidgetAndController> widgetAndControllerList = [];
                for (final value in multiEntry.values) {
                  final ValueEitherController valueController =
                      locator.get<MainFactory>().createValueController(loggable.type);
                  valueController.addListener(_loggableControllerListener);

                  widgetAndControllerList.add(
                    _WidgetAndController(
                        displayWidget: uiHelper.getEditEntryValueWidget(
                            loggable.properties, valueController, value,
                            forDialog: widget.forDialog, forComposite: true),
                        controller: valueController),
                  );
                }
                _loggableAndControllers.add(_MultiLoggableAndController(
                    loggable: loggable,
                    type: loggable.type,
                    loggableId: loggable.id,
                    widgetAndController: widgetAndControllerList));
              },
            );
          }
        }
      }
    }
    // load categories from properties
    else {
      for (int i = 0; i < widget.compositeProperties.loggables.length; i++) {
        LoggableForComposite loggable = widget.compositeProperties.loggables[i];
        if (loggable.isDismissible && loggable.isHiddenByDefault) continue;
        final uiHelper = locator.get<MainFactory>().getUiHelper(loggable.type);
        final ValueEitherController valueController =
            locator.get<MainFactory>().createValueController(loggable.type);

        valueController.addListener(_loggableControllerListener);

        _addLoggableAndController(loggable, uiHelper, valueController);
      }
      widget.controller.setErrorValue("Form is not filled", notify: false);
    }
  }

  @override
  void dispose() {
    for (var loggableAndController in _loggableAndControllers) {
      loggableAndController.when(
        single: (single) {
          single.widgetAndController.controller?.dispose();
        },
        multi: (multi) {
          for (final widgetAndController in multi.widgetAndController) {
            widgetAndController.controller?.dispose();
          }
        },
      );
    }
    widget.controller.removeListener(_loggableControllerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showAddButton = widget.compositeProperties.loggables.any(
      (cat) => !_loggableAndControllers.map((e) => e.loggableId).toList().contains(cat.id),
    );

    // starts with true, then we'll perform a series of checks to test if it still the case
    bool showSideBySide = true;
    if (widget.compositeProperties.displaySideBySide == false ||
        widget.compositeProperties.canShowSubCatsSideBySide == false ||
        _loggableAndControllers.length < 2) {
      showSideBySide = false;
    }

    // expensive?
    List<Widget> displayWidgets = [];
    for (final loggableAndController in _loggableAndControllers) {
      loggableAndController.when(
        single: (single) {
          if (single.loggable == null) {
            showSideBySide = false;
          }
          displayWidgets.add(entryAndAction(
              Container(
                key: ValueKey(single.loggableId),
                margin: single.loggable?.type == LoggableType.composite
                    ? const EdgeInsets.only(bottom: 16)
                    : null,
                padding: single.loggable?.type == LoggableType.composite
                    ? const EdgeInsets.symmetric(horizontal: 16)
                    : null,
                decoration: single.loggable?.type == LoggableType.composite
                    ? BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withAlpha(16),
                        borderRadius:
                            BorderRadius.circular(widget.compositeProperties.level == 0 ? 16 : 12),
                      )
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: single.loggable?.type == LoggableType.composite ? 4 : 0,
                        ),
                        single.widgetAndController.displayWidget,
                        SizedBox(
                          height: single.loggable?.type == LoggableType.composite ? 0 : 8,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              single.loggable,
              single.loggableId,
              single.loggable == null ? "Deleted Loggable" : single.loggable!.title));
        },
        multi: (multi) {
          showSideBySide = false;
          List<Widget> group = [];
          for (int i = 0; i < multi.widgetAndController.length; i++) {
            // final widgetAndController in multi.widgetAndController
            group.add(multi.widgetAndController[i].displayWidget);

            // dont add the divider to a single item or the last item
            if (multi.widgetAndController.length != 1 &&
                i != multi.widgetAndController.length - 1) {
              group.add(const Divider(
                thickness: 1,
              ));
            }
          }
          displayWidgets.add(
            Column(
              key: ValueKey(multi.loggableId),
              mainAxisSize: MainAxisSize.min,
              children: [
                entryAndAction(
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: multi.loggable?.type == LoggableType.composite ? 0 : 16),
                      decoration: BoxDecoration(
                          color: widget.compositeProperties.level == 0
                              ? Theme.of(context).colorScheme.primary.withAlpha(12)
                              : null,
                          borderRadius: BorderRadius.circular(
                              widget.compositeProperties.level == 0 ? 16 : 12),
                          border: Border.all(
                              width: 2,
                              color: Theme.of(context).colorScheme.primary.withAlpha(32))),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: multi.loggable?.type == LoggableType.composite ? 4 : 0,
                          ),
                          ...group,
                          // if (multi.loggable?.type == LoggableType.composite)
                          //   const SizedBox(
                          //     height: 4,
                          //   ),
                        ],
                      ),
                    ),
                    multi.loggable,
                    multi.loggableId,
                    multi.loggable == null ? "Deleted Loggable" : multi.loggable!.title),
                const SizedBox(
                  height: 8,
                )
              ],
            ),
          );
        },
      );
    }

    final bool shouldHaveBackground = !widget.forDialog && widget.compositeProperties.level == 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shouldHaveBackground)
          Text(
            "Entries",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground.withAlpha(180),
              fontSize: 16,
              //fontWeight: FontWeight.w400,
            ),
          ),
        if (shouldHaveBackground)
          const SizedBox(
            height: 11,
          ),
        Container(
          padding:
              shouldHaveBackground ? const EdgeInsets.symmetric(horizontal: 16, vertical: 2) : null,
          decoration: shouldHaveBackground
              ? BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(16),
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showSideBySide)
                // at this point it should be guaranteed that displayWidgets has 2 elements
                Row(
                  children: [
                    Expanded(child: displayWidgets[0]),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(child: displayWidgets[1]),
                  ],
                )
              else
                ...displayWidgets,
              if (shouldHaveBackground)
                const SizedBox(
                  height: 11,
                ),
              if (showAddButton)
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final remainingCategories = widget.compositeProperties.loggables
                          .where((cat) => !_loggableAndControllers
                              .map((e) => e.loggableId)
                              .toList()
                              .contains(cat.id))
                          .toList();
                      _showAddLoggableDialog(context, remainingCategories);
                    },
                    label: Text(context.l10n.addLoggable),
                  ),
                )
            ],
          ),
        ),
      ],
    );
  }

  Widget entryAndAction(
    Widget child,
    LoggableForComposite? loggable,
    String loggableId,
    String title,
  ) {
    if (loggable?.isArrayable == true) {
      _loggableAndControllers
          .firstWhereOrNull((element) => element.loggableId == loggable!.id)
          ?.when(
              single: (_) {},
              multi: (multi) => title = title + " (${multi.widgetAndController.length})");
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          //mainAxisSize: MainAxisSize.min,
          //mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  title,
                  style: loggable == null
                      ? const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        )
                      : widget.forInputForm || !widget.forDialog
                          //? Theme.of(context).textTheme.titleMedium
                          ? TextStyle(
                              color: Color.lerp(Theme.of(context).colorScheme.onBackground,
                                      Theme.of(context).colorScheme.primary, 0.4)!
                                  .withOpacity(0.7),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            )
                          : null,
                ),
              ),
            ),
            if (loggable != null && loggable.isArrayable)
              IconButton(
                onPressed: () {
                  setState(() {
                    _addNewArrayableEntry(loggable);
                  });
                },
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            if (loggable != null && loggable.isDismissible)
              PopupMenuButton<_MenuOptions>(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.primary,
                ),
                elevation: 16,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (selectedOption) {
                  switch (selectedOption) {
                    case _MenuOptions.dissmiss:
                      setState(() {
                        _loggableAndControllers
                            .removeWhere((element) => element.loggableId == loggableId);
                        _loggableControllerListener();
                      });
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Text(context.l10n.dismissLoggable),
                    value: _MenuOptions.dissmiss,
                  ),
                ],
              )
          ],
        ),
        child,
      ],
    );
  }

  void _addNewArrayableEntry(LoggableForComposite loggable) {
    final loggableAndController = _loggableAndControllers
            .firstWhere((catAndController) => catAndController.loggableId == loggable.id)
        as _MultiLoggableAndController;

    final uiHelper = locator.get<MainFactory>().getUiHelper(loggable.type);
    final ValueEitherController valueController =
        locator.get<MainFactory>().createValueController(loggable.type);

    valueController.addListener(_loggableControllerListener);

    // multi at this point ?
    // add new item
    loggableAndController.widgetAndController.add(_WidgetAndController(
        displayWidget: uiHelper.getEditEntryValueWidget(loggable.properties, valueController, null,
            forDialog: widget.forDialog, forComposite: true),
        controller: valueController));
  }

  void _showAddLoggableDialog(context, List<LoggableForComposite> categories) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return alert dialog object

        List<SimpleDialogOption> options = [];

        for (final loggable in categories) {
          options.add(SimpleDialogOption(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(loggable.title),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    loggable.type.name,
                    style: Theme.of(context).textTheme.caption,
                  )
                ],
              ),
            ),
            onPressed: () async {
              final uiHelper = locator.get<MainFactory>().getUiHelper(loggable.type);
              final ValueEitherController valueController =
                  locator.get<MainFactory>().createValueController(loggable.type);
              valueController.addListener(_loggableControllerListener);
              setState(() {
                _addLoggableAndController(loggable, uiHelper, valueController);
              });
              Navigator.pop(context);
            },
          ));
        }

        return SimpleDialog(
          title: Text(context.l10n.chooseExistingLoggable),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          children: options,
        );
      },
    );
  }
}

abstract class _BaseLoggableAndController {
  LoggableForComposite? loggable;
  String loggableId;
  LoggableType type;
  _BaseLoggableAndController({
    required this.loggable,
    required this.loggableId,
    required this.type,
  });

  R when<R>(
      {required R Function(_SingleLoggableAndController) single,
      required R Function(_MultiLoggableAndController) multi});
}

class _SingleLoggableAndController extends _BaseLoggableAndController {
  _WidgetAndController widgetAndController;

  _SingleLoggableAndController({
    required LoggableForComposite? loggable,
    required LoggableType type,
    required String loggableId,
    required this.widgetAndController,
  }) : super(loggable: loggable, type: type, loggableId: loggableId);

  @override
  R when<R>(
      {required R Function(_SingleLoggableAndController) single,
      required R Function(_MultiLoggableAndController) multi}) {
    return single(this);
  }
}

class _MultiLoggableAndController extends _BaseLoggableAndController {
  List<_WidgetAndController> widgetAndController;

  _MultiLoggableAndController({
    required LoggableForComposite? loggable,
    required LoggableType type,
    required String loggableId,
    required this.widgetAndController,
  }) : super(loggable: loggable, type: type, loggableId: loggableId);

  @override
  R when<R>(
      {required R Function(_SingleLoggableAndController) single,
      required R Function(_MultiLoggableAndController) multi}) {
    return multi(this);
  }
}

class _WidgetAndController {
  Widget displayWidget;

  /// Will be null when loggable is null
  ValueEitherController? controller;

  _WidgetAndController({
    required this.displayWidget,
    required this.controller,
  });
}
