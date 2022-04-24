import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/models/filters.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/utils/extensions.dart';

enum GraphTimePeriod {
  /// 24 hours, starting form 00:00
  day,

  /// 7 days, starting from monday
  week,

  /// amount of days depends..
  month,

  /// last six months
  sixMonths,

  /// current year
  year,

  /// last five yars
  fiveYears,

  custom
}

enum GraphValueType { individual, cumulative }

class CategoryStatistics extends StatefulWidget {
  const CategoryStatistics({Key? key, required this.controller}) : super(key: key);
  final LoggableController controller;

  @override
  _CategoryStatisticsState createState() => _CategoryStatisticsState();
}

class _CategoryStatisticsState extends State<CategoryStatistics> {
  int _weekOffset = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Log>>(
      stream: widget.controller.getAllLogsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        //_calculateLogAmount(logs);

        return GraphLogs(logs: snapshot.data!, controller: widget.controller);
      },
    );
  }
}

List<Log> filterByDate(List<Log> logs, DateLimits limits) {
  // make the max date inclusive
  if (limits.maxDate.hour == 0 && limits.maxDate.minute == 0 && limits.maxDate.second == 0) {
    limits = DateLimits(
      maxDate: limits.maxDate.add(const Duration(days: 1)),
      minDate: limits.minDate,
    );
  }

  List<Log> filteredLogs = [];
  // we expect the log list to be sorted by the date in descending order
  // so we stop after we find the first log in which the date is before the min limit
  for (final log in logs) {
    if (log.timestamp.isAfter(limits.minDate) && log.timestamp.isBefore(limits.maxDate)) {
      filteredLogs.add(log);
    }
  }
  return filteredLogs;
}

Map<String, List<Log>> groupByPeriod(
    {required GraphTimePeriod period, required List<Log> logs, required int offset}) {
  Map<String, List<Log>> groupMap = {};

  final now = DateTime.now();
  final todayMidnight = DateTime.parse(now.asISO8601);
  final tomorrowMidnight = todayMidnight.add(const Duration(days: 1));

  switch (period) {

    // 24 hours
    case GraphTimePeriod.day:
      final dateLimits = DateLimits(
        maxDate: tomorrowMidnight.subtract(Duration(days: offset)),
        minDate: todayMidnight.subtract(Duration(days: offset)),
      );

      for (int i = 0; i < 24; i++) {
        groupMap.putIfAbsent(i.toString(), () => []);
      }
      for (final log in logs) {
        if (log.timestamp.isBefore(dateLimits.maxDate) &&
            log.timestamp.isAfter(dateLimits.minDate)) {
          groupMap[log.timestamp.hour.toString()]!.add(log);
        } else if (log.timestamp.isBefore(dateLimits.minDate)) {
          break;
        }
      }
      return groupMap;

    case GraphTimePeriod.week:
      final int currentWeekday = now.weekday; // 3 quarta
      final int distanceNextWeek = 7 - currentWeekday;
      final int distanceStartWeek = (1 - currentWeekday).abs();

      final dateLimits = DateLimits(
        maxDate: todayMidnight.add(Duration(days: distanceNextWeek + 7 * offset)),
        minDate: todayMidnight
            .subtract(Duration(days: distanceStartWeek))
            .add(Duration(days: 7 * offset)),
      );

      for (int i = 1; i <= 7; i++) {
        groupMap.putIfAbsent(i.toString(), () => []);
      }

      for (final log in logs) {
        if (log.timestamp.isBefore(dateLimits.maxDate) &&
            log.timestamp.isAfter(dateLimits.minDate)) {
          groupMap[log.timestamp.weekday.toString()]!.add(log);
        } else if (log.timestamp.isBefore(dateLimits.minDate)) {
          break;
        }
      }
      return groupMap;
    case GraphTimePeriod.month:
      // TODO: Handle this case.
      break;
    case GraphTimePeriod.sixMonths:
      // TODO: Handle this case.
      break;
    case GraphTimePeriod.year:
      // TODO: Handle this case.
      break;
    case GraphTimePeriod.fiveYears:
      // TODO: Handle this case.
      break;
    case GraphTimePeriod.custom:
      // TODO: Handle this case.
      break;
  }

  return groupMap;
}

class GraphLogs extends StatefulWidget {
  const GraphLogs({Key? key, required this.logs, required this.controller}) : super(key: key);
  final List<Log> logs;
  final LoggableController controller;

  @override
  State<GraphLogs> createState() => _GraphLogsState();
}

class _GraphLogsState extends State<GraphLogs> {
  GraphTimePeriod _period = GraphTimePeriod.week;
  GraphValueType _type = GraphValueType.individual;
  int _offset = 0;

  @override
  Widget build(BuildContext context) {
    final endPeriod = DateTime.now();

    //List<int> values;

    final group = groupByPeriod(period: _period, logs: widget.logs, offset: _offset);

    List<FlSpot> points = [];
    switch (_type) {
      case GraphValueType.individual:
        for (int i = 0; i < group.entries.length; i++) {
          final entry = group.entries.toList()[i];
          points.add(FlSpot(i.toDouble(), entry.value.length.toDouble()));
        }
        break;
      case GraphValueType.cumulative:
        int total = 0;
        for (int i = 0; i < group.entries.length; i++) {
          final entry = group.entries.toList()[i];
          total += entry.value.length;
          points.add(FlSpot(i.toDouble(), total.toDouble()));
        }
        break;
    }

    // the most expensive of graphs..
    // time sensitive individual cumulative (7 days)
    // List<Log> validLogs = [];
    // for (final log in logs) {
    //   String date = log.dateAsISO8601;
    //   int? val = valuesMap[date];
    //   if (val != null) {
    //     validLogs.add(log);
    //   }
    // }
    // int total = 0;
    // validLogs = validLogs.reversed.toList();
    // for (final log in validLogs) {
    //   points.add(FlSpot(log.timestamp.millisecondsSinceEpoch / 1000, total.toDouble()));
    //   total++;
    // }

    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.onPrimary,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              TextButton(
                onPressed: _offset > 0
                    ? () {
                        setState(() {
                          if (_offset >= 1) {
                            _offset--;
                          }
                        });
                      }
                    : null,
                child: Text(context.l10n.decrease),
              ),
              Text(
                _offset.toString(),
                style: const TextStyle(
                  fontSize: 24,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _offset++;
                  });
                },
                child: Text(context.l10n.increase),
              )
            ],
          ),
        ),
        Container(
          color: Theme.of(context).backgroundColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SwitchListTile(
                title: Text(context.l10n.cumulative),
                value: _type == GraphValueType.cumulative,
                onChanged: (isCumulative) {
                  setState(() {
                    if (isCumulative) {
                      _type = GraphValueType.cumulative;
                    } else {
                      _type = GraphValueType.individual;
                    }
                  });
                },
              ),
              RadioListTile(
                title: Text(context.l10n.dayPeriod),
                value: GraphTimePeriod.day,
                groupValue: _period,
                onChanged: (period) {
                  setState(() {
                    if (period != null) _period = period as GraphTimePeriod;
                  });
                },
              ),
              RadioListTile(
                title: const Text("week period"),
                value: GraphTimePeriod.week,
                groupValue: _period,
                onChanged: (period) {
                  setState(() {
                    if (period != null) _period = period as GraphTimePeriod;
                  });
                },
              ),
            ],
          ),
        ),
        LineChartSample2(
          data: points,
          initialDate: endPeriod,
          bottomInterval: _period == GraphTimePeriod.day
              ? 3
              : _period == GraphTimePeriod.week
                  ? 1
                  : null,
          bottomLabel: (val) {
            String text = "";

            switch (_period) {
              case GraphTimePeriod.day:
                text = val.toInt().toString() + "h";
                break;
              case GraphTimePeriod.week:
                // TODO: Handle this case.
                break;
              default:
                text = val.toInt().toString();
            }

            return Text(text);
          },
        ),
      ],
    );
  }
}

class BarChartSample1 extends StatefulWidget {
  final List<Color> availableColors = const [
    Colors.purpleAccent,
    Colors.yellow,
    Colors.lightBlue,
    Colors.orange,
    Colors.pink,
    Colors.redAccent,
  ];

  const BarChartSample1({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => BarChartSample1State();
}

class BarChartSample1State extends State<BarChartSample1> {
  final Color barBackgroundColor = Colors.black26;
  final Duration animDuration = const Duration(milliseconds: 250);

  int touchedIndex = -1;

  bool isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                const SizedBox(
                  height: 38,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: BarChart(
                      mainBarData(),
                      swapAnimationDuration: animDuration,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: const Color(0xff0f4a3c),
                ),
                onPressed: () {
                  setState(() {
                    isPlaying = !isPlaying;
                    if (isPlaying) {
                      refreshState();
                    }
                  });
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  BarChartGroupData makeGroupData(
    int x,
    double y, {
    bool isTouched = false,
    Color barColor = Colors.white,
    double width = 12,
    List<int> showTooltips = const [],
  }) {
    return BarChartGroupData(
      barsSpace: 1,
      x: x,
      barRods: [
        BarChartRodData(
          toY: isTouched ? y + 1 : y,
          color: isTouched
              ? Theme.of(context).colorScheme.primary.lighten(50)
              : Theme.of(context).colorScheme.primary.lighten(30),
          width: 30,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            //toY: 20,
            color: barBackgroundColor,
          ),
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }

  List<BarChartGroupData> showingGroups() => List.generate(7, (i) {
        switch (i) {
          case 0:
            return makeGroupData(0, 5, isTouched: i == touchedIndex);
          case 1:
            return makeGroupData(1, 6.5, isTouched: i == touchedIndex);
          case 2:
            return makeGroupData(2, 5, isTouched: i == touchedIndex);
          case 3:
            return makeGroupData(3, 7.5, isTouched: i == touchedIndex);
          case 4:
            return makeGroupData(4, 9, isTouched: i == touchedIndex);
          case 5:
            return makeGroupData(5, 11.5, isTouched: i == touchedIndex);
          case 6:
            return makeGroupData(6, 6.5, isTouched: i == touchedIndex);
          default:
            return throw Error();
        }
      });

  BarChartData mainBarData() {
    return BarChartData(
      barTouchData: BarTouchData(
        // touchTooltipData: BarTouchTooltipData(
        //     tooltipBgColor: Colors.blueGrey,
        //     getTooltipItem: (group, groupIndex, rod, rodIndex) {
        //       String weekDay;
        //       switch (group.x.toInt()) {
        //         case 0:
        //           weekDay = 'Monday';
        //           break;
        //         case 1:
        //           weekDay = 'Tuesday';
        //           break;
        //         case 2:
        //           weekDay = 'Wednesday';
        //           break;
        //         case 3:
        //           weekDay = 'Thursday';
        //           break;
        //         case 4:
        //           weekDay = 'Friday';
        //           break;
        //         case 5:
        //           weekDay = 'Saturday';
        //           break;
        //         case 6:
        //           weekDay = 'Sunday';
        //           break;
        //         default:
        //           throw Error();
        //       }
        //       return BarTooltipItem(
        //         weekDay + '\n',
        //         const TextStyle(
        //           color: Colors.white,
        //           fontWeight: FontWeight.bold,
        //           fontSize: 18,
        //         ),
        //         children: <TextSpan>[
        //           TextSpan(
        //             text: (rod.toY - 1).toString(),
        //             style: const TextStyle(
        //               color: Colors.yellow,
        //               fontSize: 16,
        //               fontWeight: FontWeight.w500,
        //             ),
        //           ),
        //         ],
        //       );
        //     }),
        touchCallback: (FlTouchEvent event, barTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                barTouchResponse == null ||
                barTouchResponse.spot == null) {
              touchedIndex = -1;
              return;
            }
            touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
          });
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: getTitles,
            reservedSize: 38,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      barGroups: showingGroups(),
      gridData: FlGridData(show: false),
    );
  }

  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('M', style: style);
        break;
      case 1:
        text = const Text('T', style: style);
        break;
      case 2:
        text = const Text('W', style: style);
        break;
      case 3:
        text = const Text('T', style: style);
        break;
      case 4:
        text = const Text('F', style: style);
        break;
      case 5:
        text = const Text('S', style: style);
        break;
      case 6:
        text = const Text('S', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }
    return Padding(padding: const EdgeInsets.only(top: 16), child: text);
  }

  // BarChartData randomData() {
  //   return BarChartData(
  //     barTouchData: BarTouchData(
  //       enabled: false,
  //     ),
  //     titlesData: FlTitlesData(
  //       show: true,
  //       bottomTitles: AxisTitles(
  //         sideTitles: SideTitles(
  //           showTitles: true,
  //           getTitlesWidget: getTitles,
  //           reservedSize: 38,
  //         ),
  //       ),
  //       leftTitles: AxisTitles(
  //         sideTitles: SideTitles(
  //           showTitles: false,
  //         ),
  //       ),
  //       topTitles: AxisTitles(
  //         sideTitles: SideTitles(
  //           showTitles: false,
  //         ),
  //       ),
  //       rightTitles: AxisTitles(
  //         sideTitles: SideTitles(
  //           showTitles: false,
  //         ),
  //       ),
  //     ),
  //     borderData: FlBorderData(
  //       show: false,
  //     ),
  //     barGroups: List.generate(7, (i) {
  //       switch (i) {
  //         case 0:
  //           return makeGroupData(0, Random().nextInt(15).toDouble() + 6,
  //               barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)]);
  //         case 1:
  //           return makeGroupData(1, Random().nextInt(15).toDouble() + 6,
  //               barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)]);
  //         case 2:
  //           return makeGroupData(2, Random().nextInt(15).toDouble() + 6,
  //               barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)]);
  //         case 3:
  //           return makeGroupData(3, Random().nextInt(15).toDouble() + 6,
  //               barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)]);
  //         case 4:
  //           return makeGroupData(4, Random().nextInt(15).toDouble() + 6,
  //               barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)]);
  //         case 5:
  //           return makeGroupData(5, Random().nextInt(15).toDouble() + 6,
  //               barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)]);
  //         case 6:
  //           return makeGroupData(6, Random().nextInt(15).toDouble() + 6,
  //               barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)]);
  //         default:
  //           return throw Error();
  //       }
  //     }),
  //     gridData: FlGridData(show: false),
  //   );
  // }

  Future<dynamic> refreshState() async {
    setState(() {});
    await Future<dynamic>.delayed(animDuration + const Duration(milliseconds: 50));
    if (isPlaying) {
      await refreshState();
    }
  }
}

//------------------
//
//
//
//
class LineChartSample2 extends StatefulWidget {
  const LineChartSample2(
      {Key? key,
      required this.data,
      required this.initialDate,
      this.bottomLabel,
      this.sideLabel,
      this.bottomInterval,
      this.sideInterval})
      : super(key: key);

  final List<FlSpot> data;
  final DateTime initialDate;

  final Widget Function(double)? bottomLabel;
  final Widget Function(double)? sideLabel;

  final int? bottomInterval;
  final int? sideInterval;

  @override
  _LineChartSample2State createState() => _LineChartSample2State();
}

class _LineChartSample2State extends State<LineChartSample2> {
  List<Color> gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];

  bool showAvg = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: <Widget>[
          Container(
            height: 200,
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(18),
                ),
                //color: Color(0xff232d37),
                color: Colors.black26),
            child: Padding(
              padding: const EdgeInsets.only(right: 18.0, left: 12.0, top: 24, bottom: 12),
              child: LineChart(
                showAvg ? avgData() : mainData(),
              ),
            ),
          ),
          // SizedBox(
          //   width: 60,
          //   height: 34,
          //   child: TextButton(
          //     onPressed: () {
          //       setState(() {
          //         showAvg = !showAvg;
          //       });
          //     },
          //     child: Text(
          //       'avg',
          //       style: TextStyle(
          //           fontSize: 12, color: showAvg ? Colors.white.withOpacity(0.5) : Colors.white),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  // Widget bottomTitleWidgets(double value, TitleMeta meta) {
  //   const style = TextStyle(
  //     color: Color(0xff68737d),
  //     fontWeight: FontWeight.bold,
  //     fontSize: 16,
  //   );
  //   Widget text;
  //   switch (value.toInt()) {
  //     case 1:
  //       text = Text(
  //           DateFormat(DateFormat.NUM_MONTH_DAY)
  //               .format(widget.initialDate.subtract(const Duration(days: 5))),
  //           style: style);
  //       break;
  //     case 3:
  //       text = Text(
  //           DateFormat(DateFormat.NUM_MONTH_DAY)
  //               .format(widget.initialDate.subtract(const Duration(days: 3))),
  //           style: style);
  //       break;
  //     case 5:
  //       text = Text(
  //           DateFormat(DateFormat.NUM_MONTH_DAY)
  //               .format(widget.initialDate.subtract(const Duration(days: 1))),
  //           style: style);
  //       break;
  //     default:
  //       text = const Text('', style: style);
  //       break;
  //   }
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    if (widget.bottomLabel != null) {
      return widget.bottomLabel!(value);
    }

    // const style = TextStyle(
    //   color: Color(0xff68737d),
    //   fontWeight: FontWeight.bold,
    //   fontSize: 16,
    // );

    Widget text;
    text = Text(meta.formattedValue);

    return Padding(child: text, padding: const EdgeInsets.only(top: 8.0));
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    if (widget.sideLabel != null) {
      return widget.sideLabel!(value);
    }

    const style = TextStyle(
      color: Color(0xff67727d),
      fontWeight: FontWeight.bold,
      fontSize: 15,
    );
    //String text;
    // switch (value.toInt()) {
    //   case 1:
    //     text = '10K';
    //     break;
    //   case 3:
    //     text = '30k';
    //     break;
    //   case 5:
    //     text = '50k';
    //     break;
    //   default:
    //     return Container();
    // }
    if (widget.data.isNotEmpty && widget.data.map((spot) => spot.y).reduce(max) + 10 == value) {
      return const SizedBox.shrink();
    }
    return Text(value.toInt().toString(), style: style, textAlign: TextAlign.left);
  }

  LineChartData mainData() {
    double minX = 0;
    double maxX = 0;
    double maxY = 10;
    if (widget.data.isNotEmpty) {
      minX = widget.data[0].x;
      maxX = widget.data[widget.data.length - 1].x;
      maxY = widget.data.map((spot) => spot.y).reduce(max) + 10;
    }
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        //horizontalInterval: 1,
        //verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.white12,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.white12,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: widget.bottomInterval?.toDouble(),
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: widget.sideInterval?.toDouble(),
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 42,
          ),
        ),
      ),
      borderData:
          FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
      minX: minX,
      maxX: maxX,
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: widget.data,
          isCurved: false,
          preventCurveOverShooting: true,
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors.map((color) => color.withOpacity(0.3)).toList(),
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ],
    );
  }

  LineChartData avgData() {
    return LineChartData(
      lineTouchData: LineTouchData(enabled: false),
      gridData: FlGridData(
        show: false,
        drawHorizontalLine: false,
        verticalInterval: 1,
        horizontalInterval: 1,
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Theme.of(context).colorScheme.primary.darken(20),
            strokeWidth: 1,
          );
        },
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            //getTitlesWidget: bottomTitleWidgets,
            //interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 80,
            //interval: 1,
          ),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData:
          FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: 6,
      lineBarsData: [
        LineChartBarData(
          spots: const [
            FlSpot(0, 3.44),
            FlSpot(1, 3.44),
            FlSpot(2, 3.44),
            FlSpot(3, 3.44),
            FlSpot(4, 3.44),
            FlSpot(5, 3.44),
            FlSpot(6, 3.44),
          ],
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              ColorTween(begin: gradientColors[0], end: gradientColors[1]).lerp(0.2)!,
              ColorTween(begin: gradientColors[0], end: gradientColors[1]).lerp(0.2)!,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                ColorTween(begin: gradientColors[0], end: gradientColors[1])
                    .lerp(0.2)!
                    .withOpacity(0.1),
                ColorTween(begin: gradientColors[0], end: gradientColors[1])
                    .lerp(0.2)!
                    .withOpacity(0.1),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ],
    );
  }
}
