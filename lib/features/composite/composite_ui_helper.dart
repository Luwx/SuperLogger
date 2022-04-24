import 'package:animations/animations.dart';
import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/core/models/filters.dart';
import 'package:super_logger/core/presentation/screens/loggable_details/loggable_details_screen.dart';
import 'package:super_logger/core/presentation/screens/home/widgets/card_date_list.dart';
import 'package:super_logger/core/presentation/widgets/development_warning.dart';
import 'package:super_logger/features/composite/models/base_loggable_for_composite.dart';
import 'package:super_logger/features/composite/models/composite_log.dart';
import 'package:super_logger/features/composite/models/computations.dart';
import 'package:super_logger/features/composite/presentation/add_button_with_confirmation.dart';
import 'package:super_logger/features/composite/presentation/composite_filter_form.dart';
import 'package:super_logger/features/composite/presentation/composite_input_form.dart';
import 'package:super_logger/features/composite/models/composite_properties.dart';
import 'package:super_logger/features/composite/presentation/composite_add_log_dialog.dart';
import 'package:super_logger/features/composite/presentation/composite_log_input.dart';
import 'package:super_logger/features/composite/presentation/composite_properties_form/composite_properties_form.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/core/presentation/widgets/animated_log_details_list.dart';
import 'package:super_logger/core/presentation/widgets/base_main_card.dart';
import 'package:super_logger/core/presentation/widgets/base.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/id_generator.dart';
import 'package:super_logger/utils/value_controller.dart';

class CompositeUiHelper extends BaseLoggableUiHelper {
  @override
  Widget getGeneralConfigForm(
      {MappableObject? originalProperties,
      required ValueEitherValidOrErrController<MappableObject> propertiesController}) {
    return EditCompositePropertiesForm(
      compositeProperties: originalProperties as CompositeProperties?,
      controller: propertiesController,
    );
  }

  Widget? _getPrimaryCardButton(LoggableController controller) {
    return Builder(builder: (context) {
      if ((controller.loggable.loggableProperties as CompositeProperties).loggables.length >= 3) {
        return AddButtonWithConfirmation(controller: controller);
      } else {
        return MainCardButton(
          loggableController: controller,
          color: Theme.of(context).colorScheme.primary,
          shadowColor: null, //const Color(0x501B59F3),
          //shadowColor: Theme.of(context).colorScheme.primaryVariant.withAlpha(100),
          //icon: Icons.add,
          onTap: () async {
            final log = await newLog(context, controller);
            if (log != null) {
              await controller.addLog(log);
            }
          },
        );
      }
    });
  }

  @override
  Widget getEditEntryValueWidget(
      MappableObject properties, ValueEitherController valueController, dynamic logValue,
      {bool forComposite = false, bool forDialog = false}) {
    if (logValue != null) valueController.setRightValue(logValue);
    return CompositeLogInput(
        forDialog: forDialog,
        compositeProperties: properties as CompositeProperties,
        controller: valueController as ValueEitherController<CompositeLog>);
  }

  Widget _logWidget(
      CompositeLog logValue, CompositeProperties properties, LogDisplayWidgetSize size) {
    final entries = logValue.entryList;
    final widgetList = <Widget>[];

    bool showSideBySide = true;
    if (properties.displaySideBySide == false ||
        properties.canShowSubCatsSideBySide == false ||
        entries.length < 2) {
      showSideBySide = false;
    }

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final entryLoggable = properties.loggables.firstWhereOrNull(
        (loggable) => loggable.id == entry.loggableId,
      );

      if (entryLoggable == null ||
          entry.when(singleEntry: (singleEntry) => false, multiEntry: (multi) => true)) {
        showSideBySide = false;
      }

      LoggableUiHelper? uiHelper;
      if (entryLoggable != null) {
        uiHelper = locator.get<MainFactory>().getUiHelper(entryLoggable.type);
      }

      //print(logValue.toMap());

      if (entry.type == LoggableType.composite) {
        widgetList.add(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                (entryLoggable?.title ?? "DELETED CATEGORY") + ": ",
                style: TextStyle(
                  color: entryLoggable == null ? Colors.redAccent : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                    left: entry.when(singleEntry: (_) => 11, multiEntry: (_) => 2), top: 5),
                child: entry.when(
                  singleEntry: (singleEntry) =>
                      uiHelper?.getDisplayLogValueWidget(singleEntry.value,
                          properties: entryLoggable!.properties, size: size) ??
                      Text(singleEntry.value.toString()),
                  multiEntry: (multiEntry) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: multiEntry.values
                        .map(
                          (value) => Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Table(
                              //defaultColumnWidth: IntrinsicColumnWidth(),
                              columnWidths: const {
                                0: FixedColumnWidth(16), // fixed to 100 width
                                1: FlexColumnWidth(),
                              },
                              children: [
                                TableRow(children: [
                                  TableCell(
                                    verticalAlignment: TableCellVerticalAlignment.fill,
                                    child: Align(
                                      alignment: Alignment.topRight,
                                      child: Builder(builder: (context) {
                                        return Container(
                                          width: 2,
                                          margin: const EdgeInsets.fromLTRB(0, 2, 6, 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onBackground
                                                .withOpacity(0.32),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                  uiHelper?.getDisplayLogValueWidget(value,
                                          properties: entryLoggable!.properties, size: size) ??
                                      Text(
                                        value.toString(),
                                      )
                                ]),
                              ],
                            ),
                            // child: Row(
                            //   //mainAxisSize: MainAxisSize.min,
                            //   crossAxisAlignment: CrossAxisAlignment.start,
                            //   children: <Widget>[
                            //     const Padding(
                            //       padding: EdgeInsets.only(top: 2.0),
                            //       child: Text("1 "),
                            //     ),
                            //     Expanded(
                            //       child: Builder(builder: (context) {
                            //         return ClipRRect(
                            //           borderRadius: BorderRadius.circular(6),
                            //           child: Container(
                            //             padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                            //             //margin: const EdgeInsets.all(2),
                            //             decoration: BoxDecoration(
                            //               color:
                            //                   Theme.of(context).colorScheme.primary.withAlpha(16),
                            //               border: Border(
                            //                 left: BorderSide(
                            //                   color: Theme.of(context)
                            //                       .colorScheme
                            //                       .onBackground
                            //                       .withOpacity(0.3),
                            //                   width: 3.0,
                            //                 ),
                            //               ),
                            //             ),
                            //             child: uiHelper?.getDisplayLogValueWidget(value,
                            //                     properties: entryLoggable!.properties) ??
                            //                 Text(
                            //                   value.toString(),
                            //                 ),
                            //           ),
                            //         );
                            //       }),
                            //     )
                            //   ],
                            // ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              )
            ],
          ),
        );
      } else {
        widgetList.add(
          Wrap(
            //crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((entryLoggable?.hideTitle ?? true) == false)
                Text(
                  (entryLoggable?.title ?? "DELETED CATEGORY") + ": ",
                  style: TextStyle(
                    color: entryLoggable == null ? Colors.redAccent : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              entry.when(
                singleEntry: (singleEntry) =>
                    uiHelper?.getDisplayLogValueWidget(singleEntry.value,
                        properties: entryLoggable!.properties, size: size) ??
                    Text(singleEntry.value.toString()),
                multiEntry: (multiEntry) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: multiEntry.values
                      .map(
                        (value) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text("  • "),
                            uiHelper?.getDisplayLogValueWidget(value,
                                    properties: entryLoggable!.properties, size: size) ??
                                Text(
                                  value.toString(),
                                )
                          ],
                        ),
                      )
                      .toList(),
                ),
              )
            ],
          ),
        );
      }
    }

    List<Widget> computationWidgetList = [];

    for (final computation in properties.calculations) {
      computationWidgetList.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              computation.name + ": ",
              style: const TextStyle(
                color: Colors.green,
              ),
            ),
            Text(computation.performComputation(logValue, properties)?.formatWithPrecision4 ??
                "Error")
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: showSideBySide
          ? [
              Wrap(
                children: <Widget>[
                  widgetList[0],
                  Text(properties.sideBySideDelimiter),
                  widgetList[1],
                ],
              ),
              ...computationWidgetList
            ]
          : widgetList + computationWidgetList,
    );
  }

  Widget _getCardDetailsLog(DateLog? dateLog, LoggableController controller, bool isCardSelected) {
    assert(dateLog == null || dateLog is DateLog<CompositeLog>);

    return CardDetailsLogBase(
      details: dateLog != null
          ? AnimatedLogDetailList(
              dateLog: dateLog,
              maxEntries: 5,
              mapper: (context, log) {
                if ((controller.loggable.loggableProperties as CompositeProperties).level == 0) {
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _logWidget(
                          log.value,
                          controller.loggable.loggableProperties as CompositeProperties,
                          LogDisplayWidgetSize.small),
                    ),
                  );
                } else {
                  return _logWidget(
                      log.value,
                      controller.loggable.loggableProperties as CompositeProperties,
                      LogDisplayWidgetSize.small);
                }
              },
            )
          : null,
    );
  }

  Widget _getCardValue(
      DateLog? dateLog, LoggableController loggableController, bool isCardSelected) {
    if (dateLog != null) {
      Log<CompositeLog> log = dateLog.logs.last as Log<CompositeLog>;

      // final CompositeProperties properties =
      //     loggableController.loggable.loggableProperties as CompositeProperties;

      final displayWidget = isCardSelected
          ? _logWidget(
              log.value,
              loggableController.loggable.loggableProperties as CompositeProperties,
              LogDisplayWidgetSize.medium)
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: _logWidget(
                    log.value,
                    loggableController.loggable.loggableProperties as CompositeProperties,
                    LogDisplayWidgetSize.medium),
              ),
            );

      return PageTransitionSwitcher(
        duration: kThemeAnimationDuration * 2,
        layoutBuilder: (List<Widget> entries) {
          return Stack(
            children: entries,
            alignment: Alignment.topCenter,
          );
        },
        transitionBuilder:
            (Widget child, Animation<double> animation, Animation<double> secondaryAnimation) {
          return FadeThroughTransition(
            fillColor: Colors.transparent,
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: SizedBox(
          key: ValueKey(log.hashCode),
          child: displayWidget,
        ),
      );

      // overflows...
      // return ConstrainedBox(
      //   constraints: const BoxConstraints(maxHeight: 250),
      //   child: _logWidget(
      //       lastLogVal, loggableController.loggable.loggableProperties as CompositeProperties),
      // );

    } else {
      return const Text("No data");
    }
  }

  @override
  Widget getMainCard(
      {Key? key,
      required Loggable loggable,
      required DateTime date,
      required CardState state,
      required VoidCallback onTap,
      required VoidCallback onLongPress,
      required void Function(Loggable p1) onNoLogs,
      required OnLogDelete onLogDeleted}) {
    bool isToday = date.isToday;
    return BaseMainCard(
      key: key,
      loggable: loggable,
      date: date,
      state: state,
      onTap: onTap,
      onLongPress: onLongPress,
      onNoLogs: onNoLogs,
      onLogDeleted: onLogDeleted,
      cardValue: _getCardValue,
      cardLogDetails: _getCardDetailsLog,
      primaryButton: isToday ? _getPrimaryCardButton : null,
      secondaryButton: null, //isToday ? _getSecondaryCardButton : null,
      //color: _getPrimaryColor(loggable).withAlpha(20),
    );
  }

  @override
  Widget getTileTitleWidget(Log log, LoggableController controller) {
    return Align(
      alignment: Alignment.centerLeft,
      child: _logWidget(log.value, controller.loggable.loggableProperties as CompositeProperties,
          LogDisplayWidgetSize.medium),
    );
  }

  @override
  Future<Log<Object>?> newLog(BuildContext context, LoggableController<Object> controller) async {
    CompositeProperties properties = controller.loggable.loggableProperties as CompositeProperties;

    CompositeLog? result;

    if (properties.loggables.length >= 3) {
      result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              CompositeInputForm(compositeProperties: properties, title: controller.loggable.title),
        ),
      );
    } else {
      result = await showDialog<CompositeLog>(
        context: context,
        builder: (context) {
          return CompositeDialog(
            compositeProperties: properties,
            title: controller.loggable.title,
          );
        },
      );
    }

    if (result == null) return null;
    return Log<CompositeLog>(id: generateId(), timestamp: DateTime.now(), value: result, note: "");
  }

  @override
  LoggableType get type => LoggableType.composite;

  @override
  Widget getDisplayLogValueWidget(dynamic logValue,
      {LogDisplayWidgetSize size = LoggableUiHelper.defaultLogDisplaySize,
      MappableObject? properties}) {
    return _logWidget(
      logValue,
      properties != null
          ? properties as CompositeProperties
          : CompositeProperties.defaults(),
      size,
    );
  }

  @override
  Widget getLogFilterForm(LogValueFilterController controller, MappableObject properties) {
    // return CompositeFilterForm(
    //   controller: controller,
    //   properties: properties as CompositeProperties,
    // );
    return const DevelopmentWarning();
  }

  @override
  Widget? getLogSortForm(
      ValueEitherValidOrErrController<CompareLogs> controller, MappableObject properties) {
    return null;
  }

  @override
  Widget? getDateLogSortForm(
      ValueEitherValidOrErrController<CompareDateLogs> controller, MappableObject properties) {
    return null;
  }

  @override
  Widget? getDateLogFilterForm(DateLogValueFilterController controller, MappableObject properties) {
    return null;
  }
}
