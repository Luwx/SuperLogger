import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:super_logger/core/presentation/screens/home/home_screen.dart';
import 'package:super_logger/utils/extensions.dart';

class DayPickerSlider extends StatelessWidget {
  const DayPickerSlider({
    Key? key,
    required this.scrollController,
    required this.nOfDays,
    required this.pageController,
    required this.logCountManager,
  }) : super(key: key);

  final ScrollController scrollController;
  final int nOfDays;
  final PageController pageController;
  final LogCountManager logCountManager;

  Widget markerWidget(int logCount, Color color) {
    if (logCount == 0) {
      return const SizedBox();
    } else {
      double opacity = ((logCount.clamp(0, 100) / 100) * 0.76) + 0.24;
      double size = opacity > 0.4 ? (opacity > 0.9 ? 7 : 6) : 5;
      return Center(
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: color.withOpacity(opacity),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.only(top: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SizedBox(
      height: 76,
      child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: nOfDays,
          reverse: true,
          itemBuilder: (context, index) {
            bool selected = false;
            final displayDate = now.subtract(Duration(days: index));
            final Color textColor = displayDate.isToday
                ? Theme.of(context).appBarTheme.foregroundColor ?? Colors.white
                : Theme.of(context).appBarTheme.foregroundColor?.withAlpha(220) ?? Colors.white;

            int? logCount = logCountManager.getCountSync(displayDate);
            return Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 2, 2, 6),
                    child: Material(
                      color: Colors.transparent,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () {
                          pageController.jumpToPage(
                            index,
                          );
                          //duration: kThemeAnimationDuration * 1.5, curve: Curves.ease);
                        },
                        splashFactory: InkRipple.splashFactory,
                        child: Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            //mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                displayDate.month != now.month
                                    ? DateFormat(DateFormat.ABBR_MONTH).format(displayDate)
                                    : "",
                                style: TextStyle(
                                    color: textColor.withAlpha(100),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w300),
                              ),
                              Text(
                                DateFormat(DateFormat.ABBR_WEEKDAY, Platform.localeName)
                                    .format(displayDate),
                                style: TextStyle(
                                    color: textColor, fontSize: 11, fontWeight: FontWeight.w300),
                              ),
                              const SizedBox(
                                height: 2,
                              ),
                              Text(
                                displayDate.day.toString(),
                                style: TextStyle(
                                    color: textColor,
                                    fontSize: 18,
                                    fontWeight: displayDate.isToday ? FontWeight.w600 : null),
                              ),
                              SizedBox(
                                height: 11,
                                child: logCount != null
                                    ? markerWidget(logCount, textColor)
                                    : FutureBuilder<int>(
                                        future: logCountManager.getCountAsync(displayDate),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            int count = snapshot.data!;
                                            return markerWidget(count, textColor);
                                          } else {
                                            return const SizedBox();
                                          }
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                      animation: pageController,
                      builder: (context, child) {
                        int currentPage = 0;
                        double diff = 0;
                        if (pageController.positions.isNotEmpty) {
                          currentPage = pageController.page?.toInt() ?? 0;
                          selected = currentPage == index;
                          diff = (pageController.page ?? 0) - currentPage;
                        } else {
                          selected = index == 0;
                        }

                        if (!selected) {
                          return const SizedBox.shrink();
                        }

                        return FractionalTranslation(
                          translation: Offset(1 * -diff, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selected
                                  ? Theme.of(context).appBarTheme.foregroundColor?.withAlpha(32)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.fromLTRB(2, 2, 2, 6),
                          ),
                        );
                      }),
                ),
              ],
            );
          }),
    );
  }
}
