import 'dart:async';

import 'package:animations/animations.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/models/filters.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/core/presentation/screens/loggable_details/loggable_details_screen.dart';
import 'package:super_logger/core/presentation/screens/home/widgets/card_date_list.dart';
import 'package:super_logger/core/presentation/widgets/animated_log_details_list.dart';
import 'package:super_logger/core/presentation/widgets/base_main_card.dart';
import 'package:super_logger/core/presentation/widgets/base.dart';
import 'package:super_logger/core/presentation/widgets/development_warning.dart';
import 'package:super_logger/features/counter/counter_loggable_controller.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';
import 'package:super_logger/utils/id_generator.dart';

import 'models/counter_properties.dart';
import 'presentation/counter_value_edit_widget.dart';
import 'presentation/counter_properties_form.dart';

class CounterUiHelper extends BaseLoggableUiHelper {
  @override
  LoggableType get type => LoggableType.counter;

  @override
  Widget getGeneralConfigForm(
      {MappableObject? originalProperties,
      required ValueEitherValidOrErrController<MappableObject> propertiesController}) {
    return EditCounterPropertiesForm(
      counterProperties: originalProperties as CounterProperties?,
      propertiesController: propertiesController,
    );
  }

  Widget _getCardValue(
      DateLog dateLog, LoggableController loggableController, bool isCardSelected) {
    final properties = loggableController.loggable.loggableProperties as CounterProperties;

    return Builder(builder: (context) {
      if (properties.suffix.isNotEmpty || properties.prefix.isEmpty) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            if (properties.prefix.isNotEmpty)
              Text(properties.prefix + " ",
                  style: Theme.of(context)
                      .textTheme
                      .headline6!
                      .copyWith(color: Theme.of(context).colorScheme.primary)),
            PageTransitionSwitcher(
              duration: const Duration(milliseconds: 250),
              reverse: (loggableController as CounterLoggableController).currentTotalCount >
                  loggableController.previousTotalCount,
              child: Text(
                loggableController.currentTotalCount.toString(),
                key: ValueKey(loggableController.currentTotalCount),
                style: Theme.of(context)
                    .textTheme
                    .headline4!
                    .copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              transitionBuilder: (child, animation, secondaryAnimation) {
                return SharedAxisTransition(
                  fillColor: Colors.transparent,
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  child: child,
                  transitionType: SharedAxisTransitionType.vertical,
                );
              },
            ),
            if (properties.suffix.isNotEmpty)
              Text(" " + properties.suffix,
                  style: Theme.of(context)
                      .textTheme
                      .headline6!
                      .copyWith(color: Theme.of(context).colorScheme.primary)),
          ],
        );
      } else {
        return PageTransitionSwitcher(
          duration: const Duration(milliseconds: 250),
          reverse: (loggableController as CounterLoggableController).currentTotalCount >
              loggableController.previousTotalCount,
          child: Text(
            loggableController.currentTotalCount.toString(),
            key: ValueKey(loggableController.currentTotalCount),
            style: Theme.of(context)
                .textTheme
                .headline4!
                .copyWith(color: Theme.of(context).colorScheme.primary),
          ),
          transitionBuilder: (child, animation, secondaryAnimation) {
            return SharedAxisTransition(
              fillColor: Colors.transparent,
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
              transitionType: SharedAxisTransitionType.vertical,
            );
          },
        );
      }
    });
  }

  Widget _getCardDetailsLog(DateLog? dateLog, LoggableController controller, bool isCardSelected) {
    assert(dateLog == null || dateLog is DateLog<int>);
    return CardDetailsLogBase(
      details: dateLog != null ? AnimatedLogDetailList(dateLog: dateLog, maxEntries: 5) : null,
    );
  }

  @override
  Widget getTileTitleWidget(Log log, LoggableController controller) {
    return FutureBuilder<DateLog>(
        future: controller.getCachedDateLog(log.dateAsISO8601),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text(
              "Loading...",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }

          if (!snapshot.hasData) {
            return Text(
              context.l10n.counterErrorOcurred,
              style: const TextStyle(
                color: Colors.redAccent,
              ),
            );
          }

          List<Log> logs = snapshot.data!.logs;

          int logIndex = -1;
          for (int i = 0; i < logs.length; i++) {
            if (log.id == logs[i].id) {
              logIndex = i;
            }
          }
          if (logIndex == -1) {
            return Text(
              context.l10n.counterLogNotFound,
              style: const TextStyle(
                color: Colors.redAccent,
              ),
            );
          }

          return Text(CounterUseCases.totalCountAtIndex(snapshot.data as DateLog<int>, logIndex)
              .toString());
        });
  }

  @override
  Widget getEditEntryValueWidget(
      MappableObject properties, ValueEitherController valueController, dynamic logValue,
      {bool forComposite = false, bool forDialog = false}) {
    return CounterValueEditWidget(
        controller: valueController as ValueEitherController<int>,
        counterProperties: properties as CounterProperties,
        logValue: logValue as int?);
  }

  // @override
  // Widget getEditEntryWidget(LoggableController controller, Log log) {
  //   throw UnimplementedError();
  // }

  Widget? _getPrimaryCardButton(LoggableController controller) {
    return Builder(builder: (context) {
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
    });
  }

  Widget? _getSecondaryCardButton(LoggableController controller, OnLogDelete onLogDelete) {
    final counterProperties = controller.loggable.loggableProperties as CounterProperties;
    if (!counterProperties.showMinusButton) return null;
    return StreamBuilder<DateLog?>(
      stream: controller.currentDateLog,
      builder: (context, snapshot) {
        return MainCardButton(
          loggableController: controller,
          //color: Theme.of(context).colorScheme.secondary,
          color: Colors.red.withAlpha(200),
          //shadowColor: const Color(0x40A22219),
          //shadowColor: Theme.of(context).colorScheme.error.withAlpha(100),
          icon: Icons.remove,
          onTap: () async {
            if (snapshot.hasData && snapshot.data != null) {
              Log lastLog = snapshot.data!.logs.last;
              // delete and send event to main controller
              if (counterProperties.minusButtonBehavior == MinusButtonBehavior.deleteLastEntry) {
                onLogDelete(lastLog, controller.loggable);
                await controller.deleteLog(lastLog);
              }
              // just add -1
              else if (counterProperties.minusButtonBehavior == MinusButtonBehavior.minusOne) {
                await controller.addLog(
                  Log<int>(
                    id: generateId(),
                    timestamp: DateTime.now(),
                    value: -1,
                    note: "",
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  // Color _getPrimaryColor(BaseLoggable loggable) {
  //   return Colors.blue;
  // }

  @override
  Widget getMainCard({
    Key? key,
    required Loggable loggable,
    required DateTime date,
    required CardState state,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
    required void Function(Loggable p1) onNoLogs,
    required OnLogDelete onLogDeleted,
  }) {
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
      secondaryButton: isToday ? _getSecondaryCardButton : null,
      //color: _getPrimaryColor(loggable).withAlpha(20),
    );
  }

  @override
  Future<Log<Object>?> newLog(BuildContext context, LoggableController controller) async {
    // just increase by one for now
    return Log<int>(
      id: generateId(),
      timestamp: DateTime.now(),
      value: 1,
      note: "",
    );
  }

  @override
  Widget getDisplayLogValueWidget(dynamic logValue,
      {LogDisplayWidgetSize size = LoggableUiHelper.defaultLogDisplaySize,
      MappableObject? properties}) {
    return Text(logValue.toString());
  }

  @override
  Widget getLogFilterForm(
      LogValueFilterController controller, MappableObject properties) {
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
  Widget? getDateLogFilterForm(
     DateLogValueFilterController controller, MappableObject properties) {
    return null;
  }
}
