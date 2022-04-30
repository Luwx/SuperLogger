import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/presentation/screens/home/widgets/card_date_list.dart';
import 'package:super_logger/core/presentation/widgets/animated_log_details_list.dart';
import 'package:super_logger/core/presentation/widgets/base.dart';
import 'package:super_logger/core/presentation/widgets/base_main_card.dart';
import 'package:super_logger/features/counter/counter_loggable_controller.dart';
import 'package:super_logger/features/counter/counter_ui_helper.dart';
import 'package:super_logger/features/counter/models/counter_properties.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/id_generator.dart';

class CounterMainCardWrapper extends StatelessWidget {
  const CounterMainCardWrapper(
      {Key? key,
      required this.loggable,
      required this.date,
      required this.state,
      required this.onTap,
      required this.onLongPress,
      required this.onNoLogs,
      required this.onLogDeleted,
      required this.uiHelper,
      required})
      : super(key: key);

  final Loggable loggable;
  final CardState state;
  final DateTime date;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final void Function(Loggable) onNoLogs;
  final OnLogDelete onLogDeleted;
  final CounterUiHelper uiHelper;

  @override
  Widget build(BuildContext context) {
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
    );
  }

  Widget _getCardValue(
      DateLog dateLog, LoggableController loggableController, bool isCardSelected) {
    final properties = loggableController.loggable.loggableProperties as CounterProperties;

    final totalCounts = (loggableController as CounterLoggableController)
        .updateTotalCounts(dateLog as DateLog<int>);

    return Builder(
      builder: (context) {
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
                reverse: totalCounts.isIncreasing,
                child: Text(
                  totalCounts.current.toString(),
                  key: ValueKey(totalCounts.current),
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
            reverse: totalCounts.isIncreasing,
            child: Text(
              totalCounts.current.toString(),
              key: ValueKey(totalCounts.current),
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
      },
    );
  }

  Widget _getCardDetailsLog(DateLog? dateLog, LoggableController controller, bool isCardSelected) {
    assert(dateLog == null || dateLog is DateLog<int>);
    return CardDetailsLogBase(
      details: dateLog != null ? AnimatedLogDetailList(dateLog: dateLog, maxEntries: 5) : null,
    );
  }

  Widget? _getPrimaryCardButton(LoggableController controller) {
    return Builder(builder: (context) {
      return MainCardButton(
        loggableController: controller,
        color: Theme.of(context).colorScheme.primary,
        shadowColor: null, //const Color(0x501B59F3),
        //shadowColor: Theme.of(context).colorScheme.primaryVariant.withAlpha(100),
        //icon: Icons.add,
        onTap: () async {
          final log = await uiHelper.newLog(context, controller);
          if (log != null) {
            await controller.addLog(log);
          }
        },
      );
    });
  }

  Widget? _getSecondaryCardButton(LoggableController controller, Stream<DateLog?> stream) {
    final counterProperties = controller.loggable.loggableProperties as CounterProperties;
    if (!counterProperties.showMinusButton) return null;
    return StreamBuilder<DateLog?>(
      stream: stream,
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
                onLogDeleted(lastLog, controller.loggable);
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
}
