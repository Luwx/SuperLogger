import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/datelog.dart';

import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/presentation/screens/home/widgets/card_date_list.dart';
import 'package:super_logger/core/presentation/widgets/animated_log_details_list.dart';
import 'package:super_logger/core/presentation/widgets/base.dart';
import 'package:super_logger/core/presentation/widgets/base_main_card.dart';
import 'package:super_logger/features/number/models/number_properties.dart';
import 'package:super_logger/features/number/number_loggable_controller.dart';

import 'package:super_logger/features/number/number_ui_helper.dart';
import 'package:super_logger/utils/extensions.dart';


class NumberMainCardWrapper extends StatelessWidget {
  const NumberMainCardWrapper(
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
  final NumberUiHelper uiHelper;

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
      secondaryButton: null,
    );
  }

  Widget _getCardValue(
      DateLog dateLog, LoggableController loggableController, bool isCardSelected) {
    NumberProperties properties =
        loggableController.loggable.loggableProperties as NumberProperties;

    String number = properties.showTotalCount
        ? (dateLog as DateLog<double>)
            .logs
            .map((log) => log.value)
            .reduce((value, element) => element + value)
            .formatWithPrecision4
        : (dateLog.logs.last.value as double).formatWithPrecision4;

    return Builder(builder: (context) {
      return Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (properties.prefix.isNotEmpty)
                Text(
                  properties.prefix + " ",
                  style: Theme.of(context)
                      .textTheme
                      .headline6!
                      .copyWith(color: context.colors.primary),
                ),
              PageTransitionSwitcher(
                duration: const Duration(milliseconds: 400),
                reverse: (loggableController as ValueLoggableController).currentTotalCount >
                    (loggableController).previousTotalCount,
                child: Text(
                  number,
                  key: ValueKey(number),
                  style: Theme.of(context)
                      .textTheme
                      .headline4!
                      .copyWith(color: context.colors.primary),
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
                Text(
                  " " + properties.suffix,
                  style: Theme.of(context)
                      .textTheme
                      .headline6!
                      .copyWith(color: context.colors.primary.withOpacity(0.86)),
                ),
            ],
          ),
          const SizedBox(
            width: 16,
          ),
          Expanded(
            child: RepaintBoundary(
              child: ShaderMask(
                shaderCallback: (rect) {
                  double fadeSizePercent = 10 / rect.width;
                  return LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.topRight,
                    stops: [
                      0,
                      fadeSizePercent,
                      1 - fadeSizePercent,
                      1,
                    ],
                    colors: const [
                      Colors.transparent,
                      Colors.white,
                      Colors.white,
                      Colors.transparent
                    ],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: CustomPaint(
                  painter: NumberDateLogPainter(
                      datelog: dateLog as DateLog<double>,
                      lineColor: context.colors.primary.withOpacity(0.7)),
                  child: const SizedBox(
                    height: 30,
                  ),
                ),
              ),
            ),
          )
        ],
      );
    });
  }

  Widget _getCardDetailsLog(DateLog? dateLog, LoggableController controller, bool isCardSelected) {
    assert(dateLog == null || dateLog is DateLog<double>);
    return CardDetailsLogBase(
      details: dateLog != null
          ? AnimatedLogDetailList(
              dateLog: dateLog,
              maxEntries: 5,
              mapper: (context, log) {
                final properties = controller.loggable.loggableProperties as NumberProperties;
                String prefix = properties.prefix;
                String suffix = properties.suffix;
                if (prefix.isNotEmpty) prefix = prefix + " ";
                if (suffix.isNotEmpty) suffix = " " + suffix;

                double value = log.value;

                if (properties.showTotalCount) {
                  int index = dateLog.logs.indexOf(log);
                  String total = "";

                  // most likely a deleted log, so we take the value of the last log and then sum
                  // value with the deleted log
                  // this code is fragile since it depends on the animated_log_details_list impl
                  if (index == -1) {
                    index = dateLog.logs.length - 1;
                    total = (NumberUseCases.totalCountAtIndex(dateLog as DateLog<double>, index) +
                            value)
                        .formatWithPrecision4;
                  } else {
                    total = NumberUseCases.totalCountAtIndex(dateLog as DateLog<double>, index)
                        .formatWithPrecision4;
                  }

                  final auxTextColor = value >= 0 ? Colors.green[800]! : Colors.red;

                  return RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodySmall,
                      children: [
                        if (prefix.isNotEmpty)
                          TextSpan(
                            text: prefix,
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        TextSpan(text: total, style: Theme.of(context).textTheme.bodyMedium),
                        TextSpan(
                          text: suffix,
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                        const TextSpan(text: " ("),
                        TextSpan(
                          text: (value >= 0 ? '+' : '-'),
                          style: TextStyle(color: auxTextColor),
                        ),
                        TextSpan(
                          text: prefix,
                          style: TextStyle(
                            color: auxTextColor.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        TextSpan(
                          text: value.toString(),
                          style: TextStyle(color: auxTextColor),
                        ),
                        TextSpan(
                          text: suffix,
                          style: TextStyle(
                            color: auxTextColor.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const TextSpan(text: ")"),
                      ],
                    ),
                  );
                } else {
                  return RichText(
                    text: TextSpan(
                      style: TextStyle(color: context.colors.onBackground),
                      children: [
                        if (prefix.isNotEmpty)
                          TextSpan(
                            text: prefix,
                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        TextSpan(text: value.formatWithPrecision4),
                        TextSpan(
                          text: suffix,
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  );
                }
              },
            )
          : null,
    );
  }

  Widget? _getPrimaryCardButton(LoggableController controller) {
    return Builder(builder: (context) {
      return MainCardButton(
        loggableController: controller,
        color: context.colors.primary,
        shadowColor: null, //const Color(0x501B59F3),
        //shadowColor: context.colors.primaryVariant.withAlpha(100),
        // icon: Icons.add,
        onTap: () async {
          final log = await uiHelper.newLog(context, controller);
          if (log != null) {
            controller.addLog(log);
          }
        },
      );
    });
  }
}

class NumberDateLogPainter extends CustomPainter {
  late Paint _linePaint;
  late Paint _pointPaint;
  DateLog<double> datelog;

  double scaleBetween(
      double unscaledNum, double minAllowed, double maxAllowed, double min, double max) {
    return (maxAllowed - minAllowed) * (unscaledNum - min) / (max - min) + minAllowed;
  }

  NumberDateLogPainter({required this.datelog, required Color lineColor}) {
    _linePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = lineColor;
    _pointPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..strokeWidth = 1
      ..color = lineColor;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (datelog.logs.length > 60) {
      _linePaint = _linePaint..strokeWidth = 1;
      if (datelog.logs.isEmpty || datelog.logs.length == 1) return;
      double max = datelog.logs.map((log) => log.value).reduce(math.max);
      double min = datelog.logs.map((log) => log.value).reduce(math.min);
      double spacing = size.width / datelog.logs.length;
      double currentX = 1;
      Path path = Path();
      for (int i = 0; i < datelog.logs.length; i++) {
        final log = datelog.logs[i];
        double currentY = size.height - scaleBetween(log.value, 0, size.height, min, max);
        if (i == 0) {
          //canvas.drawLine(Offset(0, 0), Offset(currentX, currentY), _linePaint);
        } else {
          double previousY =
              size.height - scaleBetween(datelog.logs[i - 1].value, 0, size.height, min, max);

          canvas.drawLine(
              Offset(currentX - spacing, previousY), Offset(currentX, currentY), _linePaint);
        }
        currentX += spacing;
      }
      canvas.drawPath(path, _linePaint);
      return;
    }

    if (datelog.logs.isEmpty) return;

    final values = datelog.logs.map((log) => log.value).toIList();

    final path = Path();

    final yMin = values.reduce(math.min);
    final yMax = values.reduce(math.max);
    final yHeight = yMax - yMin;
    final xAxisStep = size.width / values.length;
    var xValue = 1.0;
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final yValue = yHeight == 0 ? (0.5 * size.height) : ((yMax - value) / yHeight) * size.height;
      if (xValue == 1.0) {
        path.moveTo(xValue, yValue);
      } else {
        final previousValue = values[i - 1];
        final xPrevious = xValue - xAxisStep;
        final yPrevious =
            yHeight == 0 ? (0.5 * size.height) : ((yMax - previousValue) / yHeight) * size.height;
        final controlPointX = xPrevious + (xValue - xPrevious) / 2;

        // how smooth the curve looks
        final controlPointXIncrement = 0; //(xValue - xPrevious) / 2;

        // HERE is the main line of code making your line smooth
        // print(
        //     'controlPointx: $controlPointX, yPrevious: $yPrevious, yValue: $yValue, xValue: $xValue');

        if (values.length < 40) {
          canvas.drawCircle(Offset(xValue, yValue), 2, _pointPaint);
        }

        path.cubicTo(controlPointX - controlPointXIncrement / 4, yPrevious,
            controlPointX + controlPointXIncrement / 4, yValue, xValue, yValue);
      }
      xValue += xAxisStep;
    }
    canvas.drawPath(path, _linePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
