import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/presentation/screens/loggable_details/loggable_details_screen.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';

//enum _DateButtonDialogAction { reset, pickNewDate }

enum SortingOrder { ascending, descending }

enum _Tabs { byDate, byLogContent, byDateContent }

class SortLogListForm extends StatefulWidget {
  const SortLogListForm({
    Key? key,
    required this.uiHelper,
    required this.loggable,
    required this.onApplyDateSort,
    required this.onApplyLogContentSort,
    required this.onApplyDateLogContentSort,
    required this.appliedDateSortOrder,
    required this.appliedCompareLogs,
    required this.appliedCompareDateLogs,
    //required
  }) : super(key: key);

  final Function(SortingOrder order) onApplyDateSort;
  final Function(CompareLogs compareLogs) onApplyLogContentSort;
  final Function(CompareDateLogs compareDateLogs) onApplyDateLogContentSort;
  final LoggableUiHelper uiHelper;
  final Loggable loggable;

  final SortingOrder appliedDateSortOrder;
  final CompareLogs? appliedCompareLogs;
  final CompareDateLogs? appliedCompareDateLogs;

  @override
  _SortLogListFormState createState() => _SortLogListFormState();
}

class _SortLogListFormState extends State<SortLogListForm> {
  int _currentTab = 0;
  int _previousTab = 0;

  late SortingOrder _dateOrder;

  late ValueEitherValidOrErrController<CompareLogs> _compareLogsController;
  late ValueEitherValidOrErrController<CompareDateLogs> _compareDateLogsController;

  bool _isAppliable = false;

  // check if value can be applied, if it is not already
  void _updateAppliability() {
    _Tabs tab = _Tabs.values[_currentTab];
    bool isAppliable = true;
    switch (tab) {
      case _Tabs.byDate:
        // print(
        //     '_dateOrder: $_dateOrder, {widget.appliedDateSortOrder}: ${widget.appliedDateSortOrder}');
        isAppliable = _dateOrder != widget.appliedDateSortOrder;
        break;
      case _Tabs.byLogContent:
        if (_compareLogsController.isSetUp) {
          isAppliable = _compareLogsController.value.fold(
            (l) => false,
            (r) => r != widget.appliedCompareLogs,
          );
        } else {
          isAppliable = false;
        }
        break;
      case _Tabs.byDateContent:
        if (_compareDateLogsController.isSetUp) {
          isAppliable = _compareDateLogsController.value.fold(
            (l) => false,
            (r) => r != widget.appliedCompareDateLogs,
          );
        } else {
          isAppliable = false;
        }
        break;
    }
    if (_isAppliable != isAppliable) {
      setState(() {
        _isAppliable = isAppliable;
      });
    }
  }

  @override
  void didUpdateWidget(covariant SortLogListForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAppliability();
  }

  @override
  void initState() {
    super.initState();

    _dateOrder = widget.appliedDateSortOrder;

    _compareLogsController = ValueEitherValidOrErrController();
    if (widget.appliedCompareLogs != null) {
      _compareLogsController.setRightValue(widget.appliedCompareLogs!);
    }

    _compareDateLogsController = ValueEitherValidOrErrController();
    if (widget.appliedCompareDateLogs != null) {
      _compareDateLogsController.setRightValue(widget.appliedCompareDateLogs!);
    }

    _compareLogsController.addListener(_updateAppliability);
    _compareDateLogsController.addListener(_updateAppliability);
  }

  @override
  Widget build(BuildContext context) {
    //
    //----
    //
    final Map<int, Widget> tabContents = {
      _Tabs.byDate.index: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withAlpha(16),
          borderRadius: const BorderRadius.all(
            Radius.circular(12),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<SortingOrder>(
            value: _dateOrder,
            isExpanded: true,
            icon: const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.keyboard_arrow_down_rounded),
            ),
            elevation: 16,
            borderRadius: BorderRadius.circular(12),
            hint: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("??"),
            ),
            onChanged: (SortingOrder? order) {
              if (order != null) {
                setState(() {
                  _dateOrder = order;
                  _updateAppliability();
                });
              }
            },
            items: const [
              DropdownMenuItem(
                value: SortingOrder.ascending,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "Oldest first",
                  ),
                ),
              ),
              DropdownMenuItem(
                value: SortingOrder.descending,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "Newest first",
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      _Tabs.byDateContent.index: SortByDateLogContentForm(
        controller: _compareDateLogsController,
        loggable: widget.loggable,
        uiHelper: widget.uiHelper,
      )
    };

    //
    //----
    //
    final Map<int, Widget> tabs = <int, Widget>{
      _Tabs.byDate.index: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text("Date",
            style: TextStyle(
              fontWeight: FontWeight.w500,
            )),
      ),
      _Tabs.byDateContent.index: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(
          "Date content",
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    };

    final logSortingForm =
        widget.uiHelper.getLogSortForm(_compareLogsController, widget.loggable.loggableProperties);
    if (logSortingForm != null) {
      tabContents.putIfAbsent(_Tabs.byLogContent.index, () => logSortingForm);
      tabs.putIfAbsent(
        _Tabs.byLogContent.index,
        () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            "Log content",
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    //
    //---- build
    //
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sort by",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
              fontWeight: FontWeight.w500,
              //fontSize: 16,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Container(
            decoration: BoxDecoration(
              //color: Colors.white.withOpacity(0.05),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CupertinoSegmentedControl(
                  borderColor: Colors.transparent,
                  unselectedColor: Color.lerp(Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.background, 0.84),
                  children: tabs,
                  onValueChanged: (int val) {
                    setState(() {
                      _previousTab = _currentTab;
                      _currentTab = val;
                      _updateAppliability();
                    });
                  },
                  groupValue: _currentTab,
                ),
                const SizedBox(
                  height: 12,
                ),
                PageTransitionSwitcher(
                  duration: const Duration(milliseconds: 400),
                  reverse: _currentTab < _previousTab,
                  child: tabContents[_currentTab],
                  layoutBuilder: (entries) {
                    return AnimatedSize(
                      curve: Curves.easeOutCubic,
                      duration: kThemeAnimationDuration,
                      child: Stack(
                        children: entries,
                        alignment: Alignment.center,
                      ),
                    );
                  },
                  transitionBuilder: (child, animation, secondaryAnimation) {
                    return SharedAxisTransition(
                      fillColor: Colors.transparent,
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      child: child,
                      transitionType: SharedAxisTransitionType.horizontal,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          ElevatedButton(
            // style: TextButton.styleFrom(
            //     onSurface: Theme.of(context).colorScheme.primary,
            //     backgroundColor: _isAppliable ? Colors.white : Colors.white24),
            onPressed: !_isAppliable
                ? null
                : () {
                    final tab = _Tabs.values[_currentTab];
                    switch (tab) {
                      case _Tabs.byDate:
                        widget.onApplyDateSort(_dateOrder);
                        break;
                      case _Tabs.byLogContent:
                        widget.onApplyLogContentSort(
                            _compareLogsController.value.fold((l) => null, (r) => r)!);
                        break;
                      case _Tabs.byDateContent:
                        widget.onApplyDateLogContentSort(
                            _compareDateLogsController.value.fold((l) => null, (r) => r)!);
                        break;
                    }
                  },
            child: const SizedBox(
              width: double.maxFinite,
              child: Center(child: Text("Apply sort")),
            ),
          ),
        ],
      ),
    );
  }

  // Future<_DateButtonDialogAction?> _showDateButtonDialog() async {
  //   return showDialog<_DateButtonDialogAction>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return SimpleDialog(
  //         title: Text("Choose action"),
  //         shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
  //         children: [
  //           SimpleDialogOption(
  //             child: const Padding(
  //               padding: EdgeInsets.all(8),
  //               child: Text("Reset"),
  //             ),
  //             onPressed: () async {
  //               Navigator.pop(context, _DateButtonDialogAction.reset);
  //             },
  //           ),
  //           SimpleDialogOption(
  //             child: const Padding(
  //               padding: EdgeInsets.all(8),
  //               child: Text("Pick new date"),
  //             ),
  //             onPressed: () async {
  //               Navigator.pop(context, _DateButtonDialogAction.pickNewDate);
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
}

enum _DateLogSortType { amountEntries, custom }

class CompareDateLogsByAmountOfEntries implements CompareDateLogs {
  @override
  final SortingOrder order;
  const CompareDateLogsByAmountOfEntries(this.order);

  @override
  int compare(DateLog a, DateLog b) {
    if (a.logs.length == b.logs.length) return 0;

    if (order == SortingOrder.ascending) {
      return a.logs.length > b.logs.length ? 1 : -1;
    } else {
      return a.logs.length < b.logs.length ? 1 : -1;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CompareDateLogsByAmountOfEntries && other.order == order;
  }

  @override
  int get hashCode => order.hashCode;
}

class SortByDateLogContentForm extends StatefulWidget {
  const SortByDateLogContentForm({
    Key? key,
    required this.controller,
    required this.loggable,
    required this.uiHelper,
  }) : super(key: key);
  final ValueEitherValidOrErrController<CompareDateLogs> controller;
  final LoggableUiHelper uiHelper;
  final Loggable loggable;

  @override
  _SortByDateLogContentFormState createState() => _SortByDateLogContentFormState();
}

class _SortByDateLogContentFormState extends State<SortByDateLogContentForm> {
  _DateLogSortType _dateLogSortType = _DateLogSortType.amountEntries;

  @override
  Widget build(BuildContext context) {
    final customDateLogSortingForm =
        widget.uiHelper.getDateLogSortForm(widget.controller, widget.loggable.loggableProperties);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DropdownButtonHideUnderline(
          child: DropdownButton<_DateLogSortType>(
            value: _dateLogSortType,
            isExpanded: true,
            //decoration: InputDecoration(filled: true,labelText: 'Choice'),
            //icon: const Icon(Icons.arrow_downward),
            //iconSize: 24,
            icon: const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.keyboard_arrow_down_rounded),
            ),
            elevation: 16,
            borderRadius: BorderRadius.circular(12),
            hint: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("??"),
            ),
            //style: const TextStyle(color: Colors.deepPurple),
            onChanged: (_DateLogSortType? order) {
              if (order != null && order != _dateLogSortType) {
                setState(() {
                  _dateLogSortType = order;
                });
              }
            },
            items: [
              const DropdownMenuItem(
                value: _DateLogSortType.amountEntries,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "Amount of entries per day",
                  ),
                ),
              ),
              if (customDateLogSortingForm != null)
                const DropdownMenuItem(
                  value: _DateLogSortType.custom,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "Custom sorting",
                    ),
                  ),
                )
            ],
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: _dateLogSortType == _DateLogSortType.amountEntries
              ? buildLogAmountSortingOrderMenu()
              : customDateLogSortingForm,
        )
      ],
    );
  }

  Widget buildLogAmountSortingOrderMenu() {
    CompareDateLogs defaultValue;
    if (widget.controller.isSetUp) {
      defaultValue = widget.controller.value
          .getOrElse((l) => const CompareDateLogsByAmountOfEntries(SortingOrder.ascending));
    } else {
      defaultValue = const CompareDateLogsByAmountOfEntries(SortingOrder.ascending);

      // we do not notify during build, so we reschedule
      WidgetsBinding.instance!.addPostFrameCallback((_) async {
        widget.controller.setRightValue(defaultValue);
      });
    }

    // value from custom sorting, change that to amount of entries sort
    if (defaultValue is! CompareDateLogsByAmountOfEntries) {
      defaultValue = const CompareDateLogsByAmountOfEntries(SortingOrder.ascending);
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha(16),
        borderRadius: const BorderRadius.all(
          Radius.circular(12),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CompareDateLogs>(
          value: defaultValue,
          isExpanded: true,
          icon: const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.keyboard_arrow_down_rounded),
          ),
          elevation: 16,
          borderRadius: BorderRadius.circular(12),
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("??"),
          ),
          onChanged: (CompareDateLogs? compare) {
            if (compare != null) {
              setState(() {
                widget.controller.setRightValue(compare);
              });
            }
          },
          items: [
            DropdownMenuItem(
              value: const CompareDateLogsByAmountOfEntries(SortingOrder.ascending),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  context.l10n.ascending,
                ),
              ),
            ),
            DropdownMenuItem(
              value: const CompareDateLogsByAmountOfEntries(SortingOrder.descending),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(context.l10n.descending),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
