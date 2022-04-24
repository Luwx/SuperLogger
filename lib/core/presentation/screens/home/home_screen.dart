import 'dart:async';
import 'dart:io';

import 'package:animations/animations.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:super_logger/core/presentation/screens/home/widgets/day_picker_slider.dart';
import 'package:super_logger/core/presentation/screens/select_new_loggable_type/select_new_loggable_type_screen.dart';
import 'package:super_logger/core/presentation/screens/template_loggables/template_loggables_screen.dart';

import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/main_controller.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/presentation/screens/home/widgets/card_date_list.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/core/models/loggable.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MainController mainController = locator.get<MainController>();

  final _logCountManager = LogCountManager();

  int nOfDays = 100;
  bool _loading = false;

  final Map<Loggable, List<Log>> _deletedLogs = {};
  bool _waitingForDeletion = false;
  bool _refreshCardListWhenRestoringDeletedLogs = false;

  final ValueNotifier<int> _currentPage = ValueNotifier(0);

  final ValueNotifier<bool> _showCalendar = ValueNotifier(false);

  int _lastPage = 0;
  int _intpage = 0;

  int _firstVisibleIndex = 0;
  int _lastVisibleIndex = 4;
  int _weekItemWidth = 60;

  //final ValueNotifier<bool> _displayFabText = ValueNotifier(true);

  late PageController _pageController;
  ScrollController _weekDaySliderScrollController = ScrollController();

  final PageController _tabController = PageController();

  // used to refresh the card list when the date changes (midnight)
  late Timer _timer;

  DateTime _previousDateTime = DateTime.now();

  void _checkTime(Timer _) {
    if (!_previousDateTime.isToday) {
      setState(() {
        _previousDateTime = DateTime.now();
      });
    } else {
      _previousDateTime = DateTime.now();
    }
  }

  void _toggleShowCalendar() {
    _showCalendar.value = !_showCalendar.value;
    // update the week day slider scroll value
    if (_showCalendar.value == false) {
      _weekDaySliderScrollController =
          ScrollController(initialScrollOffset: (_intpage - 2) * _weekItemWidth.toDouble());
      _weekDaySliderScrollController.addListener(_scrollListenerWithItemCount);
    }
  }

  // // use this one if the listItem's height is known
  // // or width in case of a horizontal list
  // void scrollListenerWithItemHeight() {
  //   int itemHeight = 60; // including padding above and below the list item
  //   double scrollOffset = scrollController.offset;
  //   int firstVisibleItemIndex =
  //       scrollOffset < itemHeight ? 0 : ((scrollOffset - itemHeight) / itemHeight).ceil();
  //   print(firstVisibleItemIndex);
  // }

  // use this if total item count is known
  void _scrollListenerWithItemCount() {
    int itemCount = nOfDays;
    double scrollOffset = _weekDaySliderScrollController.position.pixels;
    double viewportHeight = _weekDaySliderScrollController.position.viewportDimension;
    double scrollRange = _weekDaySliderScrollController.position.maxScrollExtent -
        _weekDaySliderScrollController.position.minScrollExtent;
    int firstVisibleItemIndex = (scrollOffset / (scrollRange + viewportHeight) * itemCount).floor();
    int lastVisibleItemIndex =
        ((scrollOffset + viewportHeight) / (scrollRange + viewportHeight) * itemCount).floor();
    _weekItemWidth = (scrollRange + viewportHeight) ~/ itemCount;
    _firstVisibleIndex = firstVisibleItemIndex;
    _lastVisibleIndex = lastVisibleItemIndex;
  }

  void _onLogDeleted(Log log, Loggable loggable) {
    //_deletedLogs.add(LogWithCategory(log: log, loggable: loggable));
    if (_deletedLogs[loggable] == null) {
      _deletedLogs[loggable] = [log];
    } else {
      _deletedLogs[loggable]!.add(log);
    }

    int totalLogsDeleted = 0;
    for (final entry in _deletedLogs.entries) {
      totalLogsDeleted += entry.value.length;
    }

    if (_waitingForDeletion) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
    } else {
      _waitingForDeletion = true;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(
          content: Text(context.l10n.deletedLogsMessage(totalLogsDeleted)),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: context.l10n.undo,
            onPressed: () async {
              // restore logs
              bool refresh = _refreshCardListWhenRestoringDeletedLogs;
              if (refresh) {
                setState(() {
                  _loading = true;
                });
              }
              List<Future<void>> futures = [];
              for (final entry in _deletedLogs.entries) {
                var loggableController =
                    locator.get<MainFactory>().makeLoggableController(entry.key);
                futures.add(loggableController.addLogs(entry.value));
              }
              await Future.wait(futures);

              if (refresh) {
                // give it at least a frame for the loading widget to build
                // this way the widget tree containing the card list will be completely rebuild with
                // the restored logs
                WidgetsBinding.instance?.addPostFrameCallback((_) async {
                  setState(() {
                    _loading = false;
                  });
                });
              }
              _deletedLogs.clear();
              _waitingForDeletion = false;
              _refreshCardListWhenRestoringDeletedLogs = false;
            },
          ),
        ))
        .closed
        .then((reason) {
      if (reason != SnackBarClosedReason.action && reason != SnackBarClosedReason.remove) {
        _deletedLogs.clear();
        //_refreshCardListWhenRestoringDeletedLogs = false; // TODO: WHY?
      }
      if (reason != SnackBarClosedReason.remove) {
        _waitingForDeletion = false;
        _refreshCardListWhenRestoringDeletedLogs = false;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    _timer = Timer.periodic(const Duration(seconds: 10), _checkTime);

    _pageController.addListener(() {
      if (_pageController.positions.isNotEmpty) {
        _currentPage.value = _pageController.page!.round();
        int _currentIntPage = _pageController.page!.toInt();
        if (_currentIntPage != _intpage) {
          bool forward = _currentIntPage > _intpage;
          _intpage = _currentIntPage;
          if (_intpage + 1 >= _lastVisibleIndex || _intpage - 1 <= _firstVisibleIndex) {
            double offset = (_intpage - (forward ? 2 : 2)) * _weekItemWidth.toDouble();

            // the widget that uses _scrollController (pick week day) could be hidden
            // and the _scrollController could be without views
            if (_weekDaySliderScrollController.positions.isNotEmpty) {
              _weekDaySliderScrollController.animateTo(offset,
                  duration: kThemeAnimationDuration * 1.5, curve: Curves.easeInOutCubic);
            } else {
              print("week slider dead");
            }
          }
        }
      }
    });

    _weekDaySliderScrollController.addListener(_scrollListenerWithItemCount);
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return StreamBuilder<List<Loggable>>(
      stream: mainController.loggablesStream,
      builder: (context, snapshot) {
        bool isLoading = snapshot.connectionState == ConnectionState.waiting || _loading;
        bool noData = !snapshot.hasData;
        // Local dragStartDetail.
        DragStartDetails? dragStartDetails;
        // Current drag instance - should be instantiated on overscroll and updated alongside.
        Drag? drag;
        return Scaffold(
          appBar: AppBar(
            title: ValueListenableBuilder<int>(
              valueListenable: _currentPage,
              builder: (context, page, child) {
                bool reverse = page > _lastPage;
                if (page != _lastPage) {
                  _lastPage = page;
                }

                final displayDate = _previousDateTime.subtract(Duration(days: page));
                String title = "";
                if (page == 0) {
                  title = context.l10n.today;
                } else if (page == 1) {
                  title = context.l10n.yesterday;
                } else {
                  title = DateFormat(DateFormat.MONTH_DAY, Platform.localeName).format(displayDate);
                }

                Widget subTitleLogCount;

                // since it's today, use a stream builder and get the lastest value realtime
                if (displayDate.isToday) {
                  subTitleLogCount = StreamBuilder<int>(
                    stream: mainController.getSingleDateAndLogCount(displayDate.asISO8601),
                    builder: (context, snapshot) {
                      return AnimatedSize(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerLeft,
                        curve: Curves.easeOutCubic,
                        duration: const Duration(milliseconds: 300),
                        child: snapshot.hasData
                            ? _logCounterAppBarSubtitle(snapshot.data!)
                            : const SizedBox.shrink(),
                      );
                    },
                  );
                }
                // use cache instead
                else {
                  int? logCount = _logCountManager.getCountSync(displayDate);
                  subTitleLogCount = logCount == null
                      ? FutureBuilder<int>(
                          future: _logCountManager.getCountAsync(displayDate),
                          builder: (context, snapshot) {
                            return snapshot.hasData
                                ? _logCounterAppBarSubtitle(snapshot.data!)
                                : const SizedBox.shrink();
                          },
                        )
                      : _logCounterAppBarSubtitle(logCount);
                }

                Widget appearAnim(Widget widget) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    // from 0 - 250 we just display noting, and then from
                    // 250-500 is the actual animation
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      if (value < 0.5) return const SizedBox(width: double.maxFinite);
                      value = Curves.easeOutCubic.transform((value - 0.5) * 2);
                      return Transform.translate(
                        offset: Offset(0, 8 * (1 - value)),
                        child: Opacity(
                          opacity: (value).clamp(0, 1),
                          child: widget,
                        ),
                      );
                    },
                  );
                }

                return PageTransitionSwitcher(
                  duration: const Duration(milliseconds: 250),
                  reverse: reverse,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    key: ValueKey(page),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title),
                        if (displayDate.isToday == false)
                          AnimatedSize(
                            alignment: Alignment.centerLeft,
                            clipBehavior: Clip.none,
                            duration: kThemeAnimationDuration,
                            child: appearAnim(subTitleLogCount),
                          )
                        else
                          appearAnim(subTitleLogCount)
                      ],
                    ),
                  ),
                  transitionBuilder: (child, animation, secondaryAnimation) {
                    return SharedAxisTransition(
                      fillColor: Colors.transparent,
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      child: child,
                      transitionType: SharedAxisTransitionType.horizontal,
                    );
                  },
                );
              },
            ),
            actions: [
              // IconButton(
              //   onPressed: () =>
              //       Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumSubscription())),
              //   icon: const Icon(Icons.workspace_premium),
              // ),
              IconButton(
                onPressed: () {
                  _toggleShowCalendar();
                },
                icon: const Icon(Icons.calendar_month),
              ),
              // Builder(
              //   builder: (context) {
              //     return IconButton(
              //       onPressed: () async {
              //         context.push('/premiumSubscription');
              //       },
              //       icon: const Icon(Icons.settings),
              //     );
              //   },
              // ),
            ],
          ),
          drawerEnableOpenDragGesture: false,
          backgroundColor: AppBarTheme.of(context).backgroundColor,
          body: Column(
            //mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ValueListenableBuilder<bool>(
                  valueListenable: _showCalendar,
                  builder: (context, showCalendar, child) {
                    return AnimatedSize(
                      alignment: Alignment.topCenter,
                      duration: kThemeAnimationDuration * 1.5,
                      curve: Curves.easeInOutCubic,
                      child: PageTransitionSwitcher(
                        duration: kThemeAnimationDuration * 1.5,
                        layoutBuilder: (List<Widget> entries) {
                          return Stack(
                            children: entries,
                            alignment: Alignment.topCenter,
                          );
                        },
                        transitionBuilder: (Widget child, Animation<double> animation,
                            Animation<double> secondaryAnimation) {
                          return FadeThroughTransition(
                            fillColor: Colors.transparent,
                            animation: animation,
                            secondaryAnimation: secondaryAnimation,
                            child: child,
                          );
                        },
                        child: showCalendar
                            ? ValueListenableBuilder<int>(
                                valueListenable: _currentPage,
                                builder: (context, val, child) {
                                  final now = DateTime.now();
                                  final textColor = Theme.of(context).appBarTheme.foregroundColor;
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Calendar(
                                        selectedDay: now.subtract(Duration(days: val)),
                                        textColor: textColor!,
                                        isDarkMode: isDarkMode,
                                        logCountManager: _logCountManager,
                                        nOfDays: nOfDays,
                                        onDaySelected: (date) {
                                          _pageController.jumpToPage(
                                              (now.difference(date).inDays).clamp(0, nOfDays));
                                        },
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.all(0),
                                        onPressed: () => _toggleShowCalendar(),
                                        icon: Icon(
                                          Icons.keyboard_arrow_up,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              )
                            : DayPickerSlider(
                                logCountManager: _logCountManager,
                                scrollController: _weekDaySliderScrollController,
                                nOfDays: nOfDays,
                                pageController: _pageController,
                                //currentPage: _currentPage,
                              ),
                      ),
                    );
                  }),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  duration: kThemeAnimationDuration * 4,
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 1, end: 0),
                  builder: (context, val, child) {
                    return Transform.translate(
                      offset: Offset(0, 48 * val),
                      child: Opacity(
                        opacity: 1 - val,
                        child: child,
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Hero(
                      tag: "dfy",
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                        ),
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : noData
                                ? Center(child: Text(context.l10n.noData))
                                : NotificationListener(
                                    onNotification: (notification) {
                                      // if (notification is ScrollStartNotification) {
                                      //   dragStartDetails = notification.dragDetails;
                                      // }
                                      // if (notification is OverscrollNotification) {
                                      //   if (notification.depth == 0) {
                                      //     if (dragStartDetails != null) {
                                      //       drag = _tabController.position
                                      //           .drag(dragStartDetails!, () {});
                                      //       if (notification.dragDetails != null) {
                                      //         final details = notification.dragDetails;
                                      //         final changed = DragUpdateDetails(
                                      //           globalPosition: Offset(
                                      //             details!.globalPosition.dx,
                                      //             details.globalPosition.dy,
                                      //           ),
                                      //           delta: Offset(
                                      //               details.delta.dx * 1.5, details.delta.dy),
                                      //           primaryDelta: details.delta.dx * 1.5,
                                      //         );
                                      //         drag!.update(changed);
                                      //       }
                                      //     }
                                      //   }
                                      // } else if (notification is ScrollEndNotification) {
                                      //   drag?.cancel();
                                      // } else if (notification is ScrollUpdateNotification) {
                                      //   if (notification.dragDetails != null &&
                                      //       notification.dragDetails!.delta.dx > 0) {
                                      //     drag?.cancel();
                                      //   }
                                      // }
                                      return true;
                                    },
                                    child: PageView.builder(
                                      controller: _pageController,
                                      physics: const ClampingScrollPhysics(),
                                      itemCount: nOfDays,
                                      reverse: true,
                                      itemBuilder: (context, index) {
                                        final date = DateTime.now().subtract(Duration(days: index));
                                        return CardDateList(
                                          key: ValueKey(date.asISO8601),
                                          loadedCategories: snapshot.data!,
                                          onLogDeleted: _onLogDeleted,
                                          onNoLogs: () {
                                            _refreshCardListWhenRestoringDeletedLogs = true;
                                          },
                                          date: date,
                                          index: index,
                                          pageController: _pageController,
                                          onRefresh: () async {
                                            setState(() {
                                              _loading = true;
                                            });
                                            await Future.delayed(const Duration(milliseconds: 500));
                                            _logCountManager.clear();
                                            setState(() {
                                              _loading = false;
                                            });
                                          },
                                          // onFlickDown: () => _showNavBar = false,
                                          // onFlickUp: () => _showNavBar = true,
                                        );
                                      },
                                    ),
                                  ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
          drawer: Drawer(
            child: Column(
              // Important: Remove any padding from the ListView.
              //padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_circle,
                                size: 32,
                                color: context.colors.onPrimary,
                              ),
                              Text(
                                ' Super ',
                                style: TextStyle(
                                  color: context.colors.onPrimary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 24,
                                ),
                              ),
                              Text(
                                'Logger',
                                style: TextStyle(
                                  color: context.colors.onPrimary,
                                  fontWeight: FontWeight.w300,
                                  fontSize: 24,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.list),
                  title: Text(context.l10n.myLoggables),
                  onTap: () {
                    if (noData || isLoading) return;
                    Navigator.pop(context);
                    context.go('/loggables');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.my_library_add),
                  title: Text(context.l10n.loggableTemplates),
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (context) => const TemplateLoggablesScreen()));

                    setState(() {
                      _loading = true;
                    });

                    await Future.delayed(const Duration(milliseconds: 200));
                    setState(() {
                      _loading = false;
                    });
                  },
                ),
                const Spacer(),
              ],
            ),
          ),

          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add_circle_rounded, size: 32),
            onPressed: !isLoading ? () => _addLoggable(context, snapshot.data!) : null,
          ),

          // floatingActionButton: FloatingActionButton(
          //   heroTag: null,
          //   child: const Hero(tag: "flogo", child: FlutterLogo()),
          //   onPressed: () {
          //     Navigator.of(context).push(PageRouteBuilder(
          //         barrierColor: Colors.black26,
          //         opaque: false,
          //         barrierDismissible: true,
          //         pageBuilder: (BuildContext context, _, __) {
          //           return Container(
          //             width: 150,
          //             height: 150,
          //             child: Hero(
          //               tag: "flogo",
          //               child: FlutterLogo(),
          //             ),
          //           );
          //         }));
          //     // showGeneralDialog(
          //     //   barrierLabel: "Label",
          //     //   barrierDismissible: true,
          //     //   barrierColor: Colors.black.withOpacity(0.5),
          //     //   transitionDuration: Duration(milliseconds: 700),
          //     //   context: context,
          //     //   pageBuilder: (context, anim1, anim2) {
          //     //     return Align(
          //     //       alignment: Alignment.bottomCenter,
          //     //       child: Container(
          //     //         height: 300,
          //     //         child: const SizedBox.expand(child: Hero(tag: "flogo", child: FlutterLogo())),
          //     //         margin: const EdgeInsets.only(bottom: 50, left: 12, right: 12),
          //     //         decoration: BoxDecoration(
          //     //           color: Colors.white,
          //     //           borderRadius: BorderRadius.circular(40),
          //     //         ),
          //     //       ),
          //     //     );
          //     //   },
          //     //   transitionBuilder: (context, anim1, anim2, child) {
          //     //     return SlideTransition(
          //     //       position: Tween(begin: Offset(0, 1), end: Offset(0, 0)).animate(anim1),
          //     //       child: child,
          //     //     );
          //     //   },
          //     // );
          //   },
          // ),

          // floatingActionButton: ValueListenableBuilder<bool>(
          //     valueListenable: _displayFabText,
          //     builder: (context, shouldDisplay, child) {
          //       if (shouldDisplay) {
          //         return FloatingActionButton.extended(
          //           onPressed: () {},
          //           label: Text("Add Event"),
          //           icon: const Icon(Icons.add),
          //         );
          //       } else {
          //         return FloatingActionButton(
          //           onPressed: () {},
          //           child: const Icon(Icons.add),
          //         );
          //       }
          //     }),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          // bottomNavigationBar: Material(
          //   color: Theme.of(context).scaffoldBackgroundColor,
          //   elevation: 4,
          //   child: Padding(
          //     padding: const EdgeInsets.all(8.0),
          //     child: GNav(
          //       padding: const EdgeInsets.all(16),
          //       //backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          //       tabBackgroundColor: Theme.of(context).primaryColor.withOpacity(0.12),
          //       rippleColor: context.colors.primary.withOpacity(0.12),
          //       tabs: const [
          //         GButton(
          //           gap: 8,
          //           icon: Icons.home,
          //           text: "home",
          //         ),
          //         GButton(
          //           gap: 8,
          //           icon: Icons.list,
          //           text: "loggables",
          //         ),
          //         GButton(
          //           gap: 8,
          //           icon: Icons.favorite,
          //           iconColor: Colors.transparent,
          //           backgroundColor: Colors.transparent,
          //         ),
          //         GButton(
          //           gap: 8,
          //           icon: Icons.trending_down,
          //           text: "statistics",
          //         ),
          //         GButton(
          //           gap: 8,
          //           icon: Icons.settings,
          //           text: "Settings",
          //         )
          //       ],
          //     ),
          //   ),
          // ),
          // bottomNavigationBar: BottomAppBar(
          //   color: context.colors.background,
          //   elevation: 4,
          //   child: Padding(
          //     padding: EdgeInsets.all(22),
          //     child: Text("lololol"),
          //   ),
          // ),
        );
      },
    );
  }

  Widget _logCounterAppBarSubtitle(int count) {
    if (count == 0) return const SizedBox.shrink();
    return Text(
      context.l10n.entryAmountInformation(count),
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).appBarTheme.foregroundColor?.withOpacity(0.6),
        fontStyle: FontStyle.italic,
      ),
    );
  }

  void _addLoggable(context, List<Loggable> loggables) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          maxChildSize: loggables.length >= 4 ? 0.8 : 0.5,
          initialChildSize: loggables.length < 2 ? 0.25 : 0.5,
          expand: false,
          builder: (_, controller) {
            return Column(
              //mainAxisAlignment: MainAxisAlignment.center,
              //mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  color: context.colors.primary.withAlpha(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.loggables,
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.w500,
                            color: context.colors.onBackground.withOpacity(0.8),
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SelectNewLoggableScreen(),
                              ),
                            );
                            Navigator.of(context).pop();
                            setState(() {
                              _loading = true;
                            });
                            WidgetsBinding.instance?.addPostFrameCallback((_) async {
                              setState(() {
                                _loading = false;
                              });
                            });
                          },
                          label: Text(context.l10n.createNewLoggable),
                        )
                      ],
                    ),
                  ),
                ),
                if (loggables.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(context.l10n.noLoggables),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: loggables.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          onTap: () async {
                            LoggableController loggableController =
                                locator.get<MainFactory>().makeLoggableController(loggables[index]);
                            LoggableUiHelper loggableHelper =
                                locator.get<MainFactory>().getUiHelper(loggables[index].type);

                            final newLog = await loggableHelper.newLog(context, loggableController);

                            if (newLog != null) {
                              await loggableController.addLog(newLog);
                              Navigator.pop(context);
                              await Future.delayed(const Duration(milliseconds: 200));
                              setState(() {
                                _loading = true;
                              });
                              // give it at least a frame for the loading widget to build
                              // this way the widget tree containing the card list will be
                              // completely rebuild with the new loggable log
                              WidgetsBinding.instance?.addPostFrameCallback((_) async {
                                setState(() {
                                  _loading = false;
                                });
                              });
                            }
                          },
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 24),
                          minLeadingWidth: 32,
                          leading: loggables[index].loggableSettings.symbol.isNotEmpty
                              ? Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                      color: context.colors.primary.withOpacity(0.08),
                                      shape: BoxShape.circle
                                      //borderRadius: BorderRadius.circular(8),
                                      ),
                                  padding: const EdgeInsets.all(4),
                                  child: FittedBox(
                                    child: Text(
                                      loggables[index].loggableSettings.symbol,
                                      style: TextStyle(color: Theme.of(context).primaryColor),
                                    ),
                                  ),
                                )
                              : null,
                          title: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: Wrap(
                              //crossAxisAlignment: CrossAxisAlignment.baseline,
                              //textBaseline: TextBaseline.alphabetic,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(loggables[index].title),
                                const SizedBox(
                                  width: 12,
                                ),
                                Text(
                                  loggables[index].type.name.toString(),
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ],
                            ),
                          ),
                          // subtitle: Text(
                          //   loggables[index].type.name.toString(),
                          //   //style: Theme.of(context).textTheme.caption,
                          // ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class Calendar extends StatelessWidget {
  const Calendar({
    Key? key,
    required this.textColor,
    required this.selectedDay,
    required this.isDarkMode,
    required this.logCountManager,
    required this.nOfDays,
    required this.onDaySelected,
  }) : super(key: key);

  final Color textColor;
  final DateTime selectedDay;
  final bool isDarkMode;
  final LogCountManager logCountManager;
  final int nOfDays;
  final void Function(DateTime day) onDaySelected;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return TableCalendar(
      //calendarStyle: CalendarStyle(ce)
      calendarFormat: CalendarFormat.month,
      locale: Localizations.localeOf(context).languageCode,
      firstDay: DateTime.utc(2010, 10, 16),
      lastDay: now.add(const Duration(days: 1)),
      focusedDay: selectedDay,
      calendarStyle: CalendarStyle(
        todayTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        outsideTextStyle: TextStyle(color: textColor.withOpacity(0.4)),
        weekendTextStyle: TextStyle(color: textColor),
        isTodayHighlighted: false,
        selectedTextStyle: TextStyle(color: textColor, fontWeight: FontWeight.w800),
        defaultTextStyle: TextStyle(color: textColor),
        //todayDecoration: BoxDecoration(color: textColor.withAlpha(20), borderRadius: BorderRadius.circular(12),)
        selectedDecoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: textColor.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        todayDecoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: textColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
        ),
        defaultDecoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(12),
        ),
        weekendDecoration: const BoxDecoration(
          shape: BoxShape.rectangle,
        ),
        holidayDecoration: const BoxDecoration(
          shape: BoxShape.rectangle,
        ),
        outsideDecoration: const BoxDecoration(
          shape: BoxShape.rectangle,
        ),
        withinRangeDecoration: const BoxDecoration(shape: BoxShape.rectangle),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle:
            TextStyle(color: textColor.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold),
        weekendStyle:
            TextStyle(color: textColor.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold),
      ),
      headerStyle: HeaderStyle(
          rightChevronIcon: Icon(Icons.chevron_right, color: textColor),
          rightChevronMargin: const EdgeInsets.all(0),
          rightChevronPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leftChevronMargin: const EdgeInsets.all(0),
          leftChevronPadding: const EdgeInsets.fromLTRB(16, 12, 32, 12),
          leftChevronIcon: Icon(Icons.chevron_left, color: textColor),
          formatButtonVisible: false,
          titleTextStyle: TextStyle(color: textColor, fontSize: 18)),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          Widget markerWidget(int logCount) {
            if (logCount == 0) {
              return const SizedBox();
            } else {
              double opacity = ((logCount.clamp(0, 100) / 100) * 0.84) + 0.16;
              return Container(
                height: 2,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? context.colors.secondary.withOpacity(opacity)
                      : textColor.withOpacity(opacity),
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              );
            }
          }

          int? count = logCountManager.getCountSync(day);

          if (count != null) {
            return markerWidget(count);
          } else {
            return FutureBuilder<int>(
              future: logCountManager.getCountAsync(day),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  int count = snapshot.data!;
                  return markerWidget(count);
                } else {
                  return const SizedBox();
                }
              },
            );
          }
        },
      ),
      selectedDayPredicate: (day) => selectedDay.asISO8601 == day.asISO8601,
      onDaySelected: (selected, focused) => onDaySelected(selected),
    );
  }
}

class LogCountManager {
  final List<MonthLogCountInformation> _cache = [];
  final Map<YearMonth, Future<IMap<String, int>>> _currentFetchingFutures = {};
  final MainController _mainController = locator.get<MainController>();

  void clear() {
    _cache.clear();
    _currentFetchingFutures.clear();
  }

  int? getCountSync(DateTime date) {
    if (_cache.isEmpty) return null;

    for (final monthInfo in _cache) {
      // exists in the cache
      if (date.month == monthInfo.yearMonth.month && date.year == monthInfo.yearMonth.year) {
        return monthInfo.dateAndLogCount[date.asISO8601] ?? 0;
      }
    }
    // not found, should use the async method
    return null;
  }

  Future<int> getCountAsync(DateTime date) async {
    final yearMonth = YearMonth.fromDateTime(date);
    var future = _currentFetchingFutures[yearMonth];

    if (future == null) {
      future = _mainController.getLogCount(
          DateTime(date.year, date.month).asISO8601, DateTime(date.year, date.month + 1).asISO8601);
      _currentFetchingFutures.putIfAbsent(yearMonth, () => future!);
      final result = await future;
      _currentFetchingFutures.removeWhere((key, val) => key == yearMonth);

      // keep a limited cache
      if (_cache.length > 3) {
        _cache.removeAt(0);
      }
      _cache.add(MonthLogCountInformation(dateAndLogCount: result, yearMonth: yearMonth));

      return result[date.asISO8601] ?? 0;
    } else {
      final result = await future;
      return result[date.asISO8601] ?? 0;
    }
  }
}

class MonthLogCountInformation {
  final IMap<String, int> dateAndLogCount;
  final YearMonth yearMonth;
  MonthLogCountInformation({
    required this.dateAndLogCount,
    required this.yearMonth,
  });
}

class YearMonth {
  final int year;
  final int month;
  YearMonth({
    required this.year,
    required this.month,
  });

  bool isIn(DateTime dateTime) {
    return dateTime.month == month && dateTime.year == year;
  }

  factory YearMonth.fromDateTime(DateTime dateTime) =>
      YearMonth(year: dateTime.year, month: dateTime.month);

  @override
  String toString() => '$year-$month';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is YearMonth && other.year == year && other.month == month;
  }

  @override
  int get hashCode => year.hashCode ^ month.hashCode;
}
