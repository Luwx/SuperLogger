import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/main_controller.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';

enum CardState { normal, toggled, selected }

class LoggableAndDateRelevancy {
  Loggable loggable;
  final bool isRelevant;
  LoggableAndDateRelevancy(
    this.loggable,
    this.isRelevant,
  );
}

class LoggableAndDateRelevancyTime {
  Loggable loggable;
  final int latestTimestamp;
  LoggableAndDateRelevancyTime(
    this.loggable,
    this.latestTimestamp,
  );
}

class CardDateList extends StatefulWidget {
  const CardDateList({
    Key? key,
    required this.loadedCategories,
    required this.date,
    required this.index,
    required this.onLogDeleted,
    required this.onNoLogs,
    required this.pageController,
    this.onFlickDown,
    this.onFlickUp,
    this.onRefresh,
  }) : super(key: key);
  final List<Loggable> loadedCategories;
  final OnLogDelete onLogDeleted;
  final VoidCallback onNoLogs;
  final DateTime date;
  final int index;
  final PageController pageController;

  static int numberOfCachedInstances = 2;

  final Future<void> Function()? onRefresh;

  final VoidCallback? onFlickUp;
  final VoidCallback? onFlickDown;

  @override
  _CardDateListState createState() => _CardDateListState();
}

class _CardDateListState extends State<CardDateList> with AutomaticKeepAliveClientMixin {
  bool _loading = true;
  List<Loggable> _relevantCategories = [];
  List<CardState> _cardState = [];

  late final ScrollController _scrollController;

  Future<List<Loggable>> _generateRelevantCategories(List<Loggable> categories) async {
    List<Loggable> relevantCategories = [];
    final DateTime date = widget.date;

    List<LoggableAndDateRelevancyTime> possiblyRelevantCategories = [];

    final idAndLastLogTimeList =
        await locator.get<MainController>().categoriesAndLastLogTime(date.asISO8601);

    for (final loggable in categories) {
      var lastLogTime = idAndLastLogTimeList
          .firstWhereOrNull((idAndLastLogTime) => idAndLastLogTime.id == loggable.id)
          ?.lastLogTime;
      if (lastLogTime == null && date.isToday) {
        if (loggable.loggableSettings.pinned || loggable.isNew) {
          lastLogTime = DateTime.now().millisecondsSinceEpoch;
        }
      }

      if (lastLogTime != null) {
        possiblyRelevantCategories.add(LoggableAndDateRelevancyTime(loggable, lastLogTime));
      }
    }

    possiblyRelevantCategories.sort((a, b) => b.latestTimestamp.compareTo(a.latestTimestamp));
    for (final possiblyRelevantLoggable in possiblyRelevantCategories) {
      relevantCategories.add(possiblyRelevantLoggable.loggable);
    }
    return relevantCategories;
  }

  Future<void> initCardList() async {
    if (!_loading) {
      setState(() {
        _loading = true;
      });
    }

    _relevantCategories = await _generateRelevantCategories(widget.loadedCategories);
    _cardState = List.generate(_relevantCategories.length, (index) => CardState.normal);

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  bool get wantKeepAlive {
    if (widget.pageController.position.hasContentDimensions) {
      return (widget.pageController.page! - widget.index).abs() <
          CardDateList.numberOfCachedInstances;
    } else {
      return false;
    }
  }

  int _currentPage = 0;
  // call updateKeepAlive each time the current page changes
  void _pageObserver() {
    if (widget.pageController.position.hasContentDimensions) {
      int currentPage = widget.pageController.page!.toInt();
      if (currentPage != _currentPage) {
        updateKeepAlive();
        _currentPage = currentPage;
      }
    }
  }

  double _previusOffset = -1;
  void _scrollListener() {
    double speed = _scrollController.offset - _previusOffset;
    if (speed < -2) {
      widget.onFlickUp?.call();
    } else if (speed > 2) {
      widget.onFlickDown?.call();
    }
    _previusOffset = _scrollController.offset;
  }

  @override
  void initState() {
    //print("card list innit state");
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    initCardList();
    widget.pageController.addListener(_pageObserver);
  }

  @override
  void didUpdateWidget(covariant CardDateList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // TODO: Consider also initing the card list again every time the widget change, not only when the date changes
    if (widget.date.asISO8601 != oldWidget.date.asISO8601) {
      initCardList();
      return;
    }

    // update relevant categories
    for (int i = 0; i < _relevantCategories.length; i++) {
      final relevantLoggable = _relevantCategories[i];
      final updatedLoggable =
          widget.loadedCategories.firstWhereOrNull((cat) => cat.id == relevantLoggable.id);
      if (updatedLoggable != null) {
        _relevantCategories[i] = updatedLoggable;
      } else {
        // loggable is gone, se we remove it from the relevant array
        _relevantCategories.removeWhere((loggable) => loggable.id == relevantLoggable.id);
      }
    }
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_pageObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimatedSwitcher(
      duration: kThemeAnimationDuration,
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _relevantCategories.isEmpty
              ? LayoutBuilder(builder: (context, constraints) {
                  return RefreshIndicator(
                    displacement: 100,
                    onRefresh: widget.onRefresh ?? () async {},
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Text(
                            context.l10n.noEvents,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor.withAlpha(96),
                              fontSize: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                })
              : RefreshIndicator(
                  displacement: 100,
                  onRefresh: widget.onRefresh ?? () async {},
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 48),
                    itemCount: _relevantCategories.length,
                    controller: _scrollController,
                    itemBuilder: (context, index) {
                      Loggable loggable = _relevantCategories[index];
                      return locator.get<MainFactory>().getUiHelper(loggable.type).getMainCard(
                            key: ValueKey(loggable.id),
                            date: widget.date,
                            state: _cardState[index],
                            onTap: () => setState(() {
                              _setSelected(index);
                            }),
                            onLongPress: () => setState(() {
                              _setToggled(index);
                            }),
                            onNoLogs: (loggable) {
                              setState(() {
                                _relevantCategories.removeWhere((cat) => cat.id == loggable.id);
                                widget.onNoLogs();
                              });
                            },
                            loggable: loggable,
                            onLogDeleted: widget.onLogDeleted,
                          );
                      //return
                    },
                  ),
                ),
    );
  }

  void _setSelected(int index) {
    CardState oldState = _cardState[index];
    _setAllCardsTo(CardState.normal);
    if (oldState == CardState.normal) _cardState[index] = CardState.selected;
  }

  void _setToggled(int index) {
    CardState oldState = _cardState[index];
    _setAllCardsTo(CardState.normal);
    if (oldState != CardState.toggled) _cardState[index] = CardState.toggled;
  }

  void _setAllCardsTo(CardState state) {
    for (int i = 0; i < _cardState.length; i++) {
      _cardState[i] = state;
    }
  }
}
