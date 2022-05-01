import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/main_controller.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/models/filters.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/presentation/screens/loggable_details/filter_log_list_form.dart';
import 'package:super_logger/core/presentation/screens/loggable_details/sort_log_list_form.dart';

import 'package:super_logger/core/presentation/screens/create_loggable/create_loggable_screen.dart';
import 'package:super_logger/core/presentation/screens/edit_entry/edit_entry_screen.dart';
import 'package:super_logger/core/presentation/widgets/development_warning.dart';
import 'package:super_logger/core/presentation/widgets/value_shimmer.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';

enum ActionDone { add, update, delete }

enum AggregationPeriod { day, week, month, year, noAggregation }

class LoggableDetailsScreen extends StatefulWidget {
  const LoggableDetailsScreen({Key? key, required this.loggableId, this.date}) : super(key: key);
  final String loggableId;
  final String? date;

  @override
  _LoggableDetailsScreenState createState() => _LoggableDetailsScreenState();
}

class _LoggableDetailsScreenState extends State<LoggableDetailsScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late LoggableController loggableController;
  late LoggableUiHelper loggableUiHelper;

  late final ScrollController _scrollController;

  final ValueNotifier<double> _toolbarShadowPercent = ValueNotifier(0);

  //String _searchString = "";

  final ValueNotifier<int?> _totalEntries = ValueNotifier(null);
  final ValueNotifier<Map<String, int>?> _dateCount = ValueNotifier(null);

  AggregationPeriod _aggregationPeriod = AggregationPeriod.day;

  // filtering feature
  bool _showFilterWidget = false;
  ValueFilter? _logFilter;
  DateLogFilter? _dateLogFilter;
  late NullableDateLimits _dateLimits;

  // sorting feature
  static const _defaultDateSortingOrder = SortingOrder.descending;
  bool _showSortingWidget = false;
  SortingOrder _dateSortingOrder = _defaultDateSortingOrder;
  CompareLogs? _logSortingConfig;
  CompareDateLogs? _dateLogSortingConfig;

  final ValueNotifier<int> _amountSelected = ValueNotifier(0);
  bool _selectMode = false;
  final Set<Log> _selectedLogs = {};
  late List<Log> _deletedEntries = [];

  // TODO: implement hidden dates
  //final Set<String> _hiddenDates = {};

  // Prevent the user from deleting more events when the
  // snackBar undo action is still showing
  bool _waitingForDeletion = false;

  late TabController _tabController;

  Future<void> _calculateLogAmount(List<Log> logs) async {
    int waitTimeMillis = (160 + logs.length ~/ 2).clamp(100, 800);

    await Future.delayed(Duration(milliseconds: waitTimeMillis));

    // calculate amount of entries per date
    Map<String, int> dateCount = {};
    for (final log in logs) {
      String date = AggregationHelper.aggregationDateIdentifier(log.timestamp, _aggregationPeriod);
      dateCount.putIfAbsent(date, () => 0);
      dateCount[date] = dateCount[date]! + 1;
    }
    _dateCount.value = dateCount;
    _totalEntries.value = logs.length;
  }

  void onDeleteButtonPress() {
    if (_waitingForDeletion) return;
    _deletedEntries = _selectedLogs.toList();
    loggableController.deleteLogs(_selectedLogs.toList());

    if (_selectedLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No event selected"),
        ),
      );

      setState(() {
        _selectMode = false;
      });

      return;
    }

    int amountDeleted = _selectedLogs.length;
    _selectedLogs.clear();

    // prevent further deletions
    _waitingForDeletion = true;

    setState(() {
      _selectMode = false;
    });

    String snackText = amountDeleted == 0
        ? context.l10n.noEventSelected
        : context.l10n.deletedLogsMessage(amountDeleted);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(
          content: Text(snackText),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: context.l10n.undo,
            onPressed: () async {
              // restore logs
              await loggableController.addLogs(_deletedEntries);
              _deletedEntries.clear();
              _waitingForDeletion = false;
            },
          ),
        ))
        .closed
        .then((reason) {
      if (reason != SnackBarClosedReason.action) _deletedEntries.clear();
      _waitingForDeletion = false;
    });
  }

  bool _isFilterActive() {
    if (_logFilter != null || _dateLogFilter != null || _dateLimits != const NullableDateLimits()) {
      return true;
    } else {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabController = TabController(length: 2, vsync: this);
    Loggable loggable = locator.get<MainController>().loggableById(widget.loggableId)!;
    loggableController = locator.get<MainFactory>().makeLoggableController(loggable);
    loggableUiHelper = locator.get<MainFactory>().getUiHelper(loggable.type);

    if (widget.date != null) {
      DateTime date = DateTime.parse(widget.date!);
      _dateLimits = NullableDateLimits(maxDate: date, minDate: date);
    } else {
      _dateLimits = const NullableDateLimits();
    }

    _scrollController.addListener(() {
      if (_selectMode && _scrollController.hasClients) {
        _toolbarShadowPercent.value = (_scrollController.offset / 2).clamp(1, 100) / 100;
      }
    });
  }

  @override
  void dispose() {
    loggableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);

    if (_selectMode) {
      themeData = themeData.copyWith(
          appBarTheme: themeData.appBarTheme.copyWith(backgroundColor: Colors.red[700]));
    }

    Color? toolbarBackground;
    //Color.lerp(themeData.scaffoldBackgroundColor, themeData.primaryColor, 0.1);
    Color? toolbarForeground = themeData.colorScheme.onBackground;

    //print('toolbarBackground: $toolbarBackground, toolbarForeground:');

    return Theme(
      data: themeData,
      child: WillPopScope(
        onWillPop: () async {
          if (_selectMode) {
            setState(() {
              _selectMode = false;
              _selectedLogs.clear();
            });
            return Future<bool>.value(false);
          }
          if (_waitingForDeletion) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
          Navigator.pop(context);
          return Future<bool>.value(true);
        },
        child: DefaultTabController(
          length: 2,
          child: Scaffold(
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              key: _scaffoldKey,
              appBar: AppBar(
                title: AnimatedBuilder(
                    animation: loggableController,
                    builder: (context, child) {
                      return loggableController.isBusy
                          ? const CircularProgressIndicator()
                          : Text(loggableController.loggable.title);
                    }),
                actions: <Widget>[
                  IconButton(
                    onPressed: () async {
                      final ActionDone? action = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateLoggableScreen(
                            loggableType: loggableController.loggable.type,
                            loggable: loggableController.loggable,
                          ),
                        ),
                      );

                      if (action != null) {
                        if (action == ActionDone.update) {
                          //print("refreshing...");
                          loggableController.refreshLoggable();
                        } else if (action == ActionDone.delete) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    icon: const Icon(Icons.settings),
                  )
                ],
                bottom: TabBar(
                  indicatorSize: TabBarIndicatorSize.label,
                  controller: _tabController,
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.history),
                      text: context.l10n.history,
                    ),
                    Tab(
                      icon: const Icon(Icons.show_chart_rounded),
                      text: context.l10n.statistics,
                    ),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 16,
                        color: themeData.appBarTheme.backgroundColor,
                      ),
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            if (_selectMode)
                              SliverPinnedHeader(
                                  child: buildListHeaderToolBar(
                                      themeData, toolbarForeground, context, toolbarBackground))
                            else
                              SliverToBoxAdapter(
                                child: buildListHeaderToolBar(
                                  themeData,
                                  toolbarForeground,
                                  context,
                                  toolbarBackground,
                                ),
                              ),
                            StreamBuilder<List<Log>>(
                              stream: loggableController.getAllLogsStream(
                                dateLimits: _dateLimits,
                                order: _dateSortingOrder,
                              ),
                              //initialData: loggableController.allLogsList,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting &&
                                    !snapshot.hasData) {
                                  return const SliverToBoxAdapter(
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty ||
                                    snapshot.hasError) {
                                  _calculateLogAmount([]);
                                  return SliverToBoxAdapter(
                                    child: Container(
                                      color: themeData.scaffoldBackgroundColor,
                                      padding: const EdgeInsets.only(top: 24),
                                      child: Center(
                                        child: Text(
                                          snapshot.hasError
                                              ? context.l10n.error
                                              : context.l10n.noEvents,
                                          style: TextStyle(
                                            fontSize: 24,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onBackground
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                var logs = List<Log>.from(snapshot.data!);

                                // FILTER
                                if (_logFilter != null) {
                                  logs.removeWhere((log) => _logFilter!.shouldRemove(log.value));
                                } else if (_dateLogFilter != null) {
                                  // dateLog filters are HEAVY!
                                  // unflatten back to dateLogs
                                  Map<String, List<Log>> dateLogMap = {};
                                  for (final log in logs) {
                                    String date = log.dateAsISO8601;
                                    dateLogMap.putIfAbsent(date, () => []).add(log);
                                  }
                                  List<DateLog> dateLogs = [];
                                  for (final entry in dateLogMap.entries) {
                                    dateLogs.add(DateLog(date: entry.key, logs: entry.value));
                                  }

                                  // filter
                                  dateLogs.removeWhere(
                                      (dateLog) => _dateLogFilter!.shouldRemove(dateLog));

                                  // sorting if needed
                                  if (_dateLogSortingConfig != null) {
                                    dateLogs.sort(_dateLogSortingConfig!.compare);
                                  }

                                  // flatten back
                                  List<Log> filteredLogs = [];
                                  for (final dateLog in dateLogs) {
                                    filteredLogs.addAll(dateLog.logs);
                                  }

                                  logs = filteredLogs;
                                } else if (_dateLogSortingConfig != null) {
                                  // unflatten back to dateLogs
                                  Map<String, List<Log>> dateLogMap = {};
                                  for (final log in logs) {
                                    String date = log.dateAsISO8601;
                                    dateLogMap.putIfAbsent(date, () => []).add(log);
                                  }
                                  List<DateLog> dateLogs = [];
                                  for (final entry in dateLogMap.entries) {
                                    dateLogs.add(DateLog(date: entry.key, logs: entry.value));
                                  }

                                  // sort
                                  dateLogs.sort(_dateLogSortingConfig!.compare);

                                  // flatten back
                                  List<Log> sortedLogs = [];
                                  for (final dateLog in dateLogs) {
                                    sortedLogs.addAll(dateLog.logs);
                                  }

                                  //return sortedLogs;
                                  logs = sortedLogs;
                                }

                                // // search
                                // if (_searchString.isNotEmpty) {
                                //   logs.removeWhere(
                                //       (log) => !loggableController.hasString(_searchString, log));
                                // }

                                if (_logSortingConfig != null) {
                                  logs.sort(_logSortingConfig!.compare);
                                }

                                // calculate amount of entries per date
                                Map<String, int> dateCount = {};
                                for (final log in logs) {
                                  String date = log.dateAsISO8601;
                                  dateCount.putIfAbsent(date, () => 0);
                                  dateCount[date] = dateCount[date]! + 1;
                                }

                                // WidgetsBinding.instance?.addPostFrameCallback(
                                //     (_) => _totalEntries.value = logs.length);
                                // calculate total entries and amount per day
                                _calculateLogAmount(logs);

                                return SliverStack(
                                  children: <Widget>[
                                    SliverPositioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).scaffoldBackgroundColor,
                                          // borderRadius:
                                          //     const BorderRadius.vertical(top: Radius.circular(16)),
                                        ),
                                      ),
                                    ),
                                    SliverPadding(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                      sliver: SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) => buildItem(logs, index),
                                          childCount: logs.length,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Container(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                child: Icon(
                                  Icons.sentiment_very_satisfied,
                                  size: 75,
                                  color: Colors.blue[900]!.withOpacity(0.1),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  const DevelopmentWarning(),
                  //LoggableStatistics(controller: loggableController),
                ],
              )),
        ),
      ),
    );
  }

  Widget buildListHeaderToolBar(ThemeData themeData, Color toolbarForeground, BuildContext context,
      Color? toolbarBackground) {
    return ValueListenableBuilder<double>(
      valueListenable: _toolbarShadowPercent,
      builder: (context, shadowPercent, child) {
        final shouldHaveShadow =
            _selectMode && _scrollController.hasClients && _scrollController.offset > 0;
        return Material(
          color: themeData.scaffoldBackgroundColor,
          child: Container(
            decoration: BoxDecoration(
              color: shouldHaveShadow ? themeData.scaffoldBackgroundColor : null,
              boxShadow: shouldHaveShadow
                  ? [
                      BoxShadow(
                        color: Colors.black12,
                        spreadRadius: -3 * shadowPercent,
                        blurRadius: 16 * shadowPercent,
                        offset: Offset(0, 3 * shadowPercent),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            //textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: _totalEntries,
                  builder: (context, value, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text(
                        //   context.l10n.history,
                        //   style: TextStyle(
                        //       color: toolbarForeground,
                        //       fontSize: 16,
                        //       fontWeight: FontWeight.w500),
                        // ),

                        ValueListenableBuilder<Map<String, int>?>(
                          valueListenable: _dateCount,
                          builder: (context, map, child) {
                            int? periodAmount = map?.entries.length;
                            int? totalEntries = _totalEntries.value;
                            bool isLoading = periodAmount == null || totalEntries == null;

                            return AnimatedCrossFade(
                              secondChild: _selectMode
                                  ? ValueListenableBuilder<int>(
                                      valueListenable: _amountSelected,
                                      builder: (context, amount, child) {
                                        return Text(
                                          "$amount of $totalEntries selected",
                                          key: ValueKey(
                                              periodAmount.toString() + totalEntries.toString()),
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onBackground
                                                .withOpacity(0.6),
                                            //fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        );
                                      })
                                  : Text(
                                      totalEntries == 0
                                          ? context.l10n.noEntries
                                          : context.l10n.entryAmountInformation(totalEntries ?? 0) +
                                              " " +
                                              AggregationHelper.entryPeriodInformation(
                                                  context, periodAmount ?? 0, _aggregationPeriod),
                                      key: ValueKey(
                                          periodAmount.toString() + totalEntries.toString()),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground
                                            .withOpacity(0.6),
                                        //fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                              firstChild: const SizedBox(
                                width: 100,
                                child: ValueShimmer(height: 24),
                              ),
                              crossFadeState:
                                  isLoading ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                              duration: kThemeAnimationDuration * 2,
                              sizeCurve: Curves.easeOutCubic,
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (_selectMode) ...[
                TextButton.icon(
                  style: TextButton.styleFrom(
                    primary: Colors.red,
                  ),
                  label: Text(context.l10n.delete),
                  icon: const Icon(Icons.delete),
                  onPressed: () => onDeleteButtonPress(),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _selectedLogs.clear();
                    _selectMode = false;
                  }),
                  child: Text(context.l10n.cancel),
                ),
              ] else ...[
                TextButton(
                  style: _isFilterActive()
                      ? TextButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1))
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.filter_alt),
                      AnimatedCrossFade(
                        firstChild: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            _isFilterActive() ? context.l10n.active : context.l10n.filter,
                          ),
                        ),
                        secondChild: const SizedBox(),
                        crossFadeState: _showFilterWidget || _isFilterActive()
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: kThemeAnimationDuration,
                        sizeCurve: Curves.easeOutCubic,
                      )
                    ],
                  ),
                  onPressed: () {
                    setState(() {
                      _showFilterWidget = !_showFilterWidget;
                      _showSortingWidget = false;
                      if (_showFilterWidget) {
                        _scrollController.animateTo(0,
                            duration: kThemeAnimationDuration, curve: Curves.easeOutCubic);
                      }
                    });
                  },
                ),
                // TextButton(
                //   onPressed: () {
                //     final rnd = Random();
                //     //int year2012 = 1457154942;
                //     //int maxTime = (60 * 60 * 24 * 365 * 2);

                //     int days600 = 600 * 24 * 60 * 60 * 1000;
                //     int maxValue = 100;

                //     final now = DateTime.now();

                //     List<Log<int>> logs = [];
                //     for (int i = 0; i < 12000; i++) {
                //       double rndVal = rnd.nextDouble();
                //       DateTime timestamp =
                //           now.subtract(Duration(milliseconds: (days600 * rndVal).toInt()));
                //       logs.add(
                //         Log(
                //           id: generateId(),
                //           timestamp: timestamp,
                //           value: (maxValue * rndVal).toInt() +
                //               timestamp.hour +
                //               timestamp.minute +
                //               timestamp.day,
                //           note: "index $i",
                //         ),
                //       );
                //     }
                //     loggableController.addLogs(logs);
                //   },
                //   child: const Text(
                //     "blow up",
                //     style: TextStyle(),
                //   ),
                // ),
                TextButton(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.sort),
                      AnimatedCrossFade(
                        firstChild: const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text(
                            "Sort",
                          ),
                        ),
                        secondChild: const SizedBox(),
                        crossFadeState: _showSortingWidget
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: kThemeAnimationDuration,
                        sizeCurve: Curves.easeOutCubic,
                      )
                    ],
                  ),
                  onPressed: () {
                    setState(() {
                      _showSortingWidget = !_showSortingWidget;
                      _showFilterWidget = false;
                      if (_showSortingWidget) {
                        _scrollController.animateTo(0,
                            duration: kThemeAnimationDuration, curve: Curves.easeOutCubic);
                      }
                    });
                  },
                ),
                PopupMenuButton<AggregationPeriod>(
                  icon: const Icon(Icons.menu),
                  onSelected: (period) {
                    setState(() {
                      _aggregationPeriod = period;
                    });
                  },
                  itemBuilder: (BuildContext context) {
                    return AggregationPeriod.values.map((period) {
                      return PopupMenuItem<AggregationPeriod>(
                        // onTap: () {
                        //   context.pop();
                        //   setState(() {
                        //     _filterType = type;
                        //   });
                        // },
                        value: period,
                        child: Text(
                          period.name,
                          style:
                              TextStyle(color: period == _aggregationPeriod ? Colors.amber : null),
                        ),
                      );
                    }).toList();
                  },
                ),
              ]
            ],
          ),
          AnimatedCrossFade(
            firstChild: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FilterLogListForm(
                    logFiltersApplied: _logFilter,
                    dateLimitsApplied: _dateLimits,
                    dateLogFiltersApplied: _dateLogFilter,
                    uiHelper: loggableUiHelper,
                    loggable: loggableController.loggable,
                    onApplyFilters: ((filters, dateLimits) {
                      setState(
                        () {
                          if (filters == null) {
                            _dateLogFilter = null;
                            _logFilter = null;
                          } else {
                            filters.fold(
                              (logFilter) {
                                _dateLogFilter = null;
                                _logFilter = logFilter;
                              },
                              (dateLogFilter) {
                                _logFilter = null;
                                _dateLogFilter = dateLogFilter;
                              },
                            );
                          }
                          _dateLimits = dateLimits;
                          _showFilterWidget = false;
                        },
                      );
                    }),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox(
              width: double.maxFinite,
            ),
            crossFadeState:
                _showFilterWidget ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: kThemeAnimationDuration,
            sizeCurve: Curves.easeInOutCubic,
            secondCurve: Curves.easeInOutCubic,
          ),
          AnimatedCrossFade(
            firstChild: Container(
              color: toolbarBackground,
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                SortLogListForm(
                  uiHelper: loggableUiHelper,
                  loggable: loggableController.loggable,
                  appliedCompareDateLogs: _dateLogSortingConfig,
                  appliedCompareLogs: _logSortingConfig,
                  appliedDateSortOrder: _dateSortingOrder,
                  onApplyDateSort: (SortingOrder order) {
                    setState(() {
                      _dateSortingOrder = order;
                    });
                  },
                  onApplyDateLogContentSort: (CompareDateLogs compareDateLogs) {
                    setState(() {
                      _dateLogSortingConfig = compareDateLogs;
                      _logSortingConfig = null;
                      _dateSortingOrder = _defaultDateSortingOrder;
                    });
                  },
                  onApplyLogContentSort: (CompareLogs compareLogs) {
                    setState(() {
                      _logSortingConfig = compareLogs;
                      _dateLogSortingConfig = null;
                      _dateSortingOrder = _defaultDateSortingOrder;
                    });
                  },
                ),
              ]),
            ),
            secondChild: const SizedBox(
              width: double.maxFinite,
            ),
            crossFadeState:
                _showSortingWidget ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: kThemeAnimationDuration,
            sizeCurve: Curves.easeInOutCubic,
            secondCurve: Curves.easeInOutCubic,
          ),
        ],
      ),
    );
  }

  Widget buildItem(List<Log> logs, int index) {
    //bool shouldShowCurrentAmount = !(widget.counter.positiveOnly && widget.counter.unitary);
    final log = logs[index];

    String dateSideLabel(DateTime time) {
      final now = DateTime.now();
      int diff = now.difference(time).inDays;
      if (diff == 0 && now.day == time.day) {
        return context.l10n.today;
      } else if (diff == 0 && now.day != time.day) {
        return context.l10n.yesterday;
      } else {
        return context.l10n.xDaysAgo(diff);
      }
    }

    bool isSelected = false;
    if (_selectMode) {
      isSelected = _selectedLogs.any((element) => element.id == log.id);
    }

    Color? tileColor = isSelected
        ? Colors.red.withAlpha(50)
        : Color.lerp(context.colors.primary, Theme.of(context).scaffoldBackgroundColor, 0.96);

    final showDateHeader = AggregationHelper.isFirstOfPeriod(logs, index, _aggregationPeriod);
    final isLast = AggregationHelper.isLastOfPeriod(logs, index, _aggregationPeriod);

    Widget? dateHeaderWidget;

    switch (_aggregationPeriod) {
      case AggregationPeriod.day:
        break;
      case AggregationPeriod.week:

        // TODO: Handle this case.
        break;
      case AggregationPeriod.month:
        // TODO: Handle this case.
        break;
      case AggregationPeriod.year:
        // TODO: Handle this case.
        break;
      case AggregationPeriod.noAggregation:
        // TODO: Handle this case.
        break;
    }

    ShapeBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: showDateHeader ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
    );

    Widget? leadingWidget() {
      if (isSelected) {
        return const Icon(
          Icons.check_box,
          color: Colors.red,
        );
      } else if (_selectMode) {
        return const Icon(Icons.check_box_outline_blank);
      } else {
        return null;
      }
    }

    void onLongPressFunction() {
      setState(() {
        if (!_selectMode) {
          _selectMode = true;
          _selectedLogs.add(log);
          _amountSelected.value = _selectedLogs.length;
        } else {
          //toggleSelected(entryLocation);
        }
      });
    }

    void onTapFunction(VoidCallback openContainer) async {
      if (_selectMode) {
        setState(() {
          if (isSelected) {
            _selectedLogs.remove(log);
            _amountSelected.value = _selectedLogs.length;
          } else {
            _selectedLogs.add(log);
            _amountSelected.value = _selectedLogs.length;
          }
        });
        return;
      } else {
        openContainer();
      }
    }

    final logTileWidget = loggableUiHelper.getTileTitleWidget(logs[index], loggableController);

    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDateHeader) ...[
            Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : 24, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //mainAxisSize: MainAxisSize.min,
                textBaseline: TextBaseline.ideographic,
                children: [
                  Text(
                    AggregationHelper.dateLabel(log.timestamp, _aggregationPeriod) + "  ",
                    style: TextStyle(
                      color: context.colors.primary.withOpacity(0.8),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    dateSideLabel(log.timestamp),
                    style: TextStyle(
                      color: context.colors.primary.withOpacity(0.6),
                      fontSize: 14,
                      //fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Expanded(
                    child: Container(),
                  ),
                  ValueListenableBuilder<Map<String, int>?>(
                    valueListenable: _dateCount,
                    builder: (context, map, child) {
                      int? entryNumber = map?[log.dateAsISO8601];
                      return AnimatedCrossFade(
                        firstChild: Text(
                          context.l10n.entryAmountInformation(entryNumber ?? 0),
                          key: ValueKey(entryNumber),
                          style: TextStyle(
                            color: context.colors.primary.withOpacity(0.6),
                            fontSize: 14,
                            //fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        secondChild: const SizedBox(
                          width: 60,
                          child: ValueShimmer(height: 20),
                        ),
                        crossFadeState: entryNumber != null
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: kThemeAnimationDuration * 2,
                        sizeCurve: Curves.easeOutCubic,
                      );
                    },
                  ),
                  // TextButton(
                  //   onPressed: () {
                  //     setState(() {
                  //       if (_hiddenDates.contains(log.timestamp.asISO8601)) {
                  //         _hiddenDates.remove(log.timestamp.asISO8601);
                  //       } else {
                  //         _hiddenDates.add(log.timestamp.asISO8601);
                  //       }
                  //     });
                  //   },
                  //   child: const Icon(Icons.arrow_drop_up_rounded),
                  // )
                ],
              ),
            ),
            if (loggableController.loggable.loggableConfig.aggregationConfig.hasAggregations)
              FutureBuilder(
                future: loggableController.getAllLogs(
                    dateLimits: AggregationHelper.dateLimits(log.timestamp, _aggregationPeriod)),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Container(
                      child: Text("test"),
                    );
                  } else {
                    return Container(
                      child: Text("nore"),
                    );
                  }
                },
              )
          ],
          OpenContainer(
            transitionDuration: kThemeAnimationDuration * 2,
            transitionType: ContainerTransitionType.fadeThrough,
            openBuilder: (context, closedContainer) {
              return EditEntryScreen(
                log: log,
                loggableController: loggableController,
              );
            },
            openShape:
                const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            openColor: Theme.of(context).scaffoldBackgroundColor,
            onClosed: (res) {},
            closedShape: shape,
            closedElevation: 0,
            closedColor: tileColor!,
            closedBuilder: (context, openContainer) {
              return ListTile(
                leading: leadingWidget(),
                subtitle: log.note == ""
                    ? null
                    : Text(
                        logs[index].note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                title: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: logTileWidget,
                ),
                trailing: SizedBox(
                  child: Text(
                    logs[index].timestamp.formattedTimeHMS,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.onBackground.withOpacity(0.7),
                    ),
                  ),
                ),
                onLongPress: () => onLongPressFunction(),
                onTap: () => onTapFunction(openContainer),
              );
            },
          ),
          if (!isLast)
            Divider(
              height: 1,
              thickness: 2,
              //color: context.colors.primary.withOpacity(0.15),
              color: Theme.of(context).scaffoldBackgroundColor,
            )
          else
            const SizedBox(
              height: 8,
            ),
        ],
      ),
    );
  }
}

class ShowDateLogWithMoreThanXEntries implements DateLogFilter<int> {
  final int _val;
  ShowDateLogWithMoreThanXEntries(this._val);

  @override
  bool shouldRemove(DateLog<int> dateLog) {
    return dateLog.logs.length <= _val;
  }
}

abstract class CompareLogs {
  final SortingOrder order;
  const CompareLogs(this.order);
  int compare(Log a, Log b);
}

abstract class CompareDateLogs {
  //const CompareDateLogs(this.order);
  SortingOrder get order;
  int compare(DateLog a, DateLog b);
}

class AggregationHelper {
  AggregationHelper._();

  static String entryPeriodInformation(BuildContext context, int amount, AggregationPeriod period) {
    switch (period) {
      case AggregationPeriod.day:
        return context.l10n.entryDaysInformation(amount);
      case AggregationPeriod.week:
        return context.l10n.entryWeekInformation(amount);
      case AggregationPeriod.month:
        return context.l10n.entryMonthInformation(amount);
      case AggregationPeriod.year:
        return context.l10n.entryYearInformation(amount);
      case AggregationPeriod.noAggregation:
        return "";
    }
  }

  static NullableDateLimits dateLimits(DateTime date, AggregationPeriod period) {
    switch (period) {
      case AggregationPeriod.day:
        return NullableDateLimits(maxDate: date, minDate: date);
      case AggregationPeriod.week:
        final startOfWeekDate = date.subtract(Duration(days: date.weekday - 1));
        return NullableDateLimits(
          maxDate: startOfWeekDate.add(const Duration(days: 7)),
          minDate: startOfWeekDate,
        );
      case AggregationPeriod.month:
        return NullableDateLimits(
          maxDate: DateTime(date.year, date.month + 1).subtract(const Duration(days: 1)),
          minDate: DateTime(date.year, date.month),
        );
      case AggregationPeriod.year:
        return NullableDateLimits(
          maxDate: DateTime(date.year + 1).subtract(const Duration(days: 1)),
          minDate: DateTime(date.year),
        );
      case AggregationPeriod.noAggregation:
        return const NullableDateLimits();
    }
  }

  static String aggregationDateIdentifier(DateTime dateTime, AggregationPeriod period) {
    switch (period) {
      case AggregationPeriod.day:
        return dateTime.asISO8601;
      case AggregationPeriod.week:
        return dateTime.year.toString() + "-" + dateTime.weekNumber.toString();
      case AggregationPeriod.month:
        return dateTime.year.toString() + "-" + dateTime.month.toString();
      case AggregationPeriod.year:
        return dateTime.year.toString();
      case AggregationPeriod.noAggregation:
        return "all";
    }
  }

  static String dateLabel(DateTime dateTime, AggregationPeriod period) {
    switch (period) {
      case AggregationPeriod.day:
        return dateTime.asISO8601;
      case AggregationPeriod.week:
        return "W" + dateTime.weekNumber.toString();
      case AggregationPeriod.month:
        return dateTime.year.toString() + dateTime.month.toString();
      case AggregationPeriod.year:
        return dateTime.year.toString();
      case AggregationPeriod.noAggregation:
        return "From () to ()";
    }
  }

  static bool isFirstOfPeriod(List<Log> logs, int index, AggregationPeriod period) {
    final log = logs[index];

    if (index == 0) return true;

    final previousLog = logs[index - 1];
    switch (period) {
      case AggregationPeriod.day:
        if (previousLog.dateAsISO8601 != log.dateAsISO8601) {
          return true;
        } else {
          return false;
        }
      case AggregationPeriod.week:
        if (previousLog.timestamp.weekday < log.timestamp.weekday) {
          return true;
        } else if ((previousLog.timestamp.difference(log.timestamp)).abs() >
            const Duration(days: 7)) {
          return true;
        } else {
          return false;
        }
      case AggregationPeriod.month:
        if (previousLog.timestamp.month != log.timestamp.month &&
            previousLog.timestamp.year != log.timestamp.year) {
          return true;
        } else {
          return false;
        }
      case AggregationPeriod.year:
        if (previousLog.timestamp.year != log.timestamp.year) {
          return true;
        } else {
          return false;
        }
      case AggregationPeriod.noAggregation:
        return false;
    }
  }

  static bool isLastOfPeriod(List<Log> logs, int index, AggregationPeriod period) {
    final log = logs[index];

    if (index == logs.length - 1) {
      return true;
    }

    final nextLog = logs[index + 1];
    switch (period) {
      case AggregationPeriod.day:
        if (nextLog.dateAsISO8601 != log.dateAsISO8601) {
          return true;
        } else {
          return false;
        }
      case AggregationPeriod.week:
        if (nextLog.timestamp.weekday > log.timestamp.weekday) {
          return true;
        } else if ((nextLog.timestamp.difference(log.timestamp)).abs() > const Duration(days: 7)) {
          return true;
        } else {
          return false;
        }
      case AggregationPeriod.month:
        if (nextLog.timestamp.month != log.timestamp.month &&
            nextLog.timestamp.year != log.timestamp.year) {
          return true;
        } else {
          return false;
        }
      case AggregationPeriod.year:
        if (nextLog.timestamp.year != log.timestamp.year) {
          return true;
        } else {
          return false;
        }
      case AggregationPeriod.noAggregation:
        return false;
    }
  }
}
