import 'package:animations/animations.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart' show Either, Left, Option, Right;

import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/models/filters.dart';
import 'package:super_logger/core/presentation/widgets/development_warning.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';

enum _DateButtonDialogAction { reset, pickNewDate }

enum _Tabs { none, logContent, dateContent }

class FilterLogListForm extends StatefulWidget {
  const FilterLogListForm(
      {Key? key,
      required this.onApplyFilters,
      required this.uiHelper,
      required this.loggable,
      required this.dateLimitsApplied,
      required this.dateLogFiltersApplied,
      required this.logFiltersApplied})
      : super(key: key);

  final NullableDateLimits dateLimitsApplied;
  final ValueFilter? logFiltersApplied;
  final DateLogFilter? dateLogFiltersApplied;

  final Function(Either<ValueFilter, DateLogFilter>? filters, NullableDateLimits datelimits)
      onApplyFilters;

  final LoggableUiHelper uiHelper;
  final Loggable loggable;

  @override
  _FilterLogListFormState createState() => _FilterLogListFormState();
}

class _FilterLogListFormState extends State<FilterLogListForm> {
  _Tabs _currentTab = _Tabs.none;
  _Tabs _previousTab = _Tabs.none;

  late NullableDateLimits _dateLimits;
  bool _isAppliable = false;

  // check if value can be applied, if it is not already
  void _updateAppliability() {
    _Tabs tab = _Tabs.values[_currentTab.index];
    bool isAppliable = true;
    switch (tab) {
      case _Tabs.logContent:
        bool appliableLogFilters = _logFilterController.value.fold(
          (l) => false,
          (r) => r != widget.logFiltersApplied,
        );
        isAppliable = appliableLogFilters || _dateLimits != widget.dateLimitsApplied;
        break;
      case _Tabs.dateContent:
        bool appliableDateLogFilters = _dateLogFilterController.value.fold(
          (l) => false,
          (r) => r != widget.dateLogFiltersApplied,
        );
        isAppliable = appliableDateLogFilters || _dateLimits != widget.dateLimitsApplied;
        break;
      case _Tabs.none:
        isAppliable = _dateLimits != widget.dateLimitsApplied ||
            widget.logFiltersApplied != null ||
            widget.dateLogFiltersApplied != null;
        break;
    }
    if (_isAppliable != isAppliable) {
      setState(() {
        _isAppliable = isAppliable;
      });
    }
  }

  late ValueEitherController<ValueFilter> _logFilterController;
  late ValueEitherController<DateLogFilter> _dateLogFilterController;

  @override
  void didUpdateWidget(covariant FilterLogListForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAppliability();
  }

  @override
  void initState() {
    super.initState();
    _logFilterController = ValueEitherController();
    if (widget.logFiltersApplied != null) {
      _logFilterController.setRightValue(widget.logFiltersApplied!);
    } else {
      _logFilterController.setErrorValue("No filter selected");
    }

    _dateLogFilterController = ValueEitherController();
    if (widget.dateLogFiltersApplied != null) {
      _dateLogFilterController.setRightValue(widget.dateLogFiltersApplied!);
    } else {
      _dateLogFilterController.setErrorValue("No filter selected");
    }

    _dateLimits = widget.dateLimitsApplied;

    _logFilterController.addListener(_updateAppliability);
    _dateLogFilterController.addListener(_updateAppliability);
  }

  @override
  void dispose() {
    _logFilterController.removeListener(_updateAppliability);
    _dateLogFilterController.removeListener(_updateAppliability);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //
    //----
    //
    final Map<int, Widget> tabContents = {
      _Tabs.none.index: const SizedBox.shrink(),
      _Tabs.logContent.index: widget.uiHelper
          .getLogFilterForm(_logFilterController, widget.loggable.loggableProperties),
      // _Tabs.dateContent.index: FilterByDateLogContentForm(
      //   controller: _dateLogFilterController,
      //   loggable: widget.loggable,
      //   uiHelper: widget.uiHelper,
      // ),
      _Tabs.dateContent.index: const DevelopmentWarning(),
    };

    //
    //----
    //
    final Map<_Tabs, Widget> tabs = <_Tabs, Widget>{
      _Tabs.none: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(
          context.l10n.none,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      _Tabs.logContent: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(
          "Log content",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      _Tabs.dateContent: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(
          "Date content",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      )
    };

    //
    //----
    //
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Date filter",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              //mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Start date",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        if (_dateLimits.minDate != null) {
                          final action = await _showDateButtonDialog();
                          if (action == null) return;
                          if (action == _DateButtonDialogAction.reset) {
                            setState(() {
                              _dateLimits = _dateLimits.copyWith(minDate: null);
                              _updateAppliability();
                            });
                            return;
                          }
                        }
                        final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _dateLimits.minDate ?? DateTime.now(),
                            firstDate: DateTime(2000, 1),
                            lastDate: DateTime.now());

                        if (pickedDate != null) {
                          if (_dateLimits.maxDate != null &&
                              pickedDate.isAfter(_dateLimits.maxDate!)) return;
                          setState(
                            () {
                              _dateLimits = _dateLimits.copyWith(minDate: pickedDate);
                              _updateAppliability();
                            },
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                        child: Text(
                          _dateLimits.minDate == null
                              ? "Select a date"
                              : _dateLimits.minDate!.asISO8601,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  //mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "End date",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            if (_dateLimits.maxDate != null) {
                              final action = await _showDateButtonDialog();
                              if (action == null) return;
                              if (action == _DateButtonDialogAction.reset) {
                                setState(() {
                                  _dateLimits = _dateLimits.copyWith(maxDate: null);
                                  _updateAppliability();
                                });
                                return;
                              }
                            }
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _dateLimits.maxDate ?? DateTime.now(),
                              firstDate: DateTime(2000, 1),
                              lastDate: DateTime.now(),
                            );

                            if (pickedDate != null) {
                              if (_dateLimits.minDate != null &&
                                  pickedDate.isBefore(_dateLimits.minDate!)) return;
                              setState(
                                () {
                                  _dateLimits = _dateLimits.copyWith(maxDate: pickedDate);
                                  _updateAppliability();
                                },
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                            child: Text(
                              _dateLimits.maxDate == null
                                  ? "Select a date"
                                  : _dateLimits.maxDate!.asISO8601,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Text(
            "Content filter",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
              fontWeight: FontWeight.w500,
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
                CupertinoSegmentedControl<_Tabs>(
                  borderColor: Colors.transparent,
                  unselectedColor: Color.lerp(
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.background,
                    0.84,
                  ),
                  //selectedColor: Colors.white,
                  children: tabs,
                  onValueChanged: (_Tabs val) {
                    setState(() {
                      _previousTab = _currentTab;
                      _currentTab = val;
                      _updateAppliability();
                    });
                  },
                  groupValue: _currentTab,
                ),
                if (_currentTab != _Tabs.none)
                  const SizedBox(
                    height: 12,
                  ),
                PageTransitionSwitcher(
                  duration: kThemeAnimationDuration,
                  reverse: _currentTab.index < _previousTab.index,
                  child: tabContents[_currentTab.index],
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
            height: 16,
          ),
          ElevatedButton(
            onPressed: !_isAppliable
                ? null
                : () {
                    switch (_currentTab) {
                      case _Tabs.none:
                        widget.onApplyFilters(null, _dateLimits);
                        break;
                      case _Tabs.logContent:
                        widget.onApplyFilters(
                          Left(_logFilterController.value.fold((l) => null, (r) => r)!),
                          _dateLimits,
                        );
                        break;
                      case _Tabs.dateContent:
                        widget.onApplyFilters(
                          Right(
                            (_dateLogFilterController.value.fold((l) => null, (r) => r)!),
                          ),
                          _dateLimits,
                        );
                        break;
                    }
                  },
            child: const SizedBox(
              width: double.maxFinite,
              child: Center(child: Text("Apply filters")),
            ),
          ),
        ],
      ),
    );
  }

  Future<_DateButtonDialogAction?> _showDateButtonDialog() async {
    return showDialog<_DateButtonDialogAction>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(context.l10n.chooseAction),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          children: [
            SimpleDialogOption(
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Text("Reset"),
              ),
              onPressed: () async {
                Navigator.pop(context, _DateButtonDialogAction.reset);
              },
            ),
            SimpleDialogOption(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(context.l10n.pickNewDate),
              ),
              onPressed: () async {
                Navigator.pop(context, _DateButtonDialogAction.pickNewDate);
              },
            ),
          ],
        );
      },
    );
  }
}

// class _ShowLessThanLogAmountFilter implements DateLogFilter {
//   final int val;
//   _ShowLessThanLogAmountFilter(this.val);

//   @override
//   bool shouldRemove(DateLog datelog) {
//     return datelog.logs.length >= val;
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is _ShowLessThanLogAmountFilter && other.val == val;
//   }

//   @override
//   int get hashCode => val.hashCode;
// }

// class _ShowGreaterThanLogAmountFilter implements DateLogFilter {
//   final int val;
//   _ShowGreaterThanLogAmountFilter(this.val);

//   @override
//   bool shouldRemove(DateLog datelog) {
//     return datelog.logs.length <= val;
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is _ShowGreaterThanLogAmountFilter && other.val == val;
//   }

//   @override
//   int get hashCode => val.hashCode;
// }

// class FilterByDateLogContentForm extends StatefulWidget {
//   const FilterByDateLogContentForm({
//     Key? key,
//     required this.controller,
//     required this.loggable,
//     required this.uiHelper,
//   }) : super(key: key);

//   final ValueEitherController<DateLogFilter> controller;
//   final LoggableUiHelper uiHelper;
//   final Loggable loggable;

//   @override
//   _FilterByDateLogContentFormState createState() => _FilterByDateLogContentFormState();
// }

// class _FilterByDateLogContentFormState extends State<FilterByDateLogContentForm> {
//   late final TextEditingController _greaterThanController;
//   late final TextEditingController _lessThanController;

//   // will be used to track the changes done by the loggable's filter form
//   late final ValueEitherController<IList<DateLogFilter>> _controller;

//   String? _errorText;

//   bool _isValid(String greaterThan, String lessThan) {
//     int? greaterThanVal = int.tryParse(greaterThan);
//     int? lessThanVal = int.tryParse(lessThan);

//     if (greaterThanVal != null && lessThanVal != null) {
//       return greaterThanVal >= lessThanVal;
//     }

//     return true;
//   }

//   void _controllerListener() {
//     if (_isValid(_greaterThanController.text, _lessThanController.text)) {
//       final loggableFormFilters = _controller.value.fold((l) => null, (r) => r);

//       int? greaterThanVal = int.tryParse(_greaterThanController.text);
//       int? lessThanVal = int.tryParse(_lessThanController.text);

//       if (loggableFormFilters != null) {
//         widget.controller.setRightValue([
//           if (greaterThanVal != null) _ShowGreaterThanLogAmountFilter(greaterThanVal),
//           if (lessThanVal != null) _ShowLessThanLogAmountFilter(lessThanVal),
//           ...loggableFormFilters
//         ].lock);
//         if (_errorText != null) {
//           setState(() {
//             _errorText = null;
//           });
//         }
//       } else {
//         widget.controller.setErrorValue(_controller.value.fold((l) => l, (r) => null)!);
//       }
//     } else {
//       widget.controller.setErrorValue(context.l10n.invalidValues);
//       if (_errorText == null) {
//         setState(() {
//           _errorText = context.l10n.invalidValues;
//         });
//       }
//     }
//   }

//   @override
//   void initState() {
//     super.initState();

//     // controller should be set up at this point
//     IList<DateLogFilter> filters =
//         widget.controller.value.fold((l) => <DateLogFilter>[].lock, (r) => r);

//     String greaterThanText = "";
//     String lessThanText = "";
//     for (final filter in filters) {
//       if (filter is _ShowGreaterThanLogAmountFilter) {
//         greaterThanText = filter.val.toString();
//       } else if (filter is _ShowLessThanLogAmountFilter) {
//         lessThanText = filter.val.toString();
//       }
//     }
//     _greaterThanController = TextEditingController(text: greaterThanText);
//     _lessThanController = TextEditingController(text: lessThanText);

//     final loggableFilterForm = filters.removeWhere((element) =>
//         element is _ShowGreaterThanLogAmountFilter || element is _ShowLessThanLogAmountFilter);
//     _controller = ValueEitherController();
//     _controller.setRightValue(loggableFilterForm);
//     _controller.addListener(_controllerListener);

//     _greaterThanController.addListener(_controllerListener);
//     _lessThanController.addListener(_controllerListener);
//   }

//   @override
//   void dispose() {
//     _controller.removeListener(_controllerListener);
//     _greaterThanController.removeListener(_controllerListener);
//     _lessThanController.removeListener(_controllerListener);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filterDateLogForm =
//         widget.uiHelper.getDateLogFilterForm(_controller, widget.loggable.loggableProperties);
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: <Widget>[
//         Text(context.l10n.amountOfEntries),
//         TextFormField(
//           controller: _greaterThanController,
//           decoration: InputDecoration(
//             isDense: true,
//             label: Text(context.l10n.greaterThan),
//             errorText: _errorText,
//           ),
//           keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: true),
//           inputFormatters: <TextInputFormatter>[
//             FilteringTextInputFormatter.allow(
//               RegExp(r'^\d{0,4}'),
//             ),
//           ],
//         ),
//         const SizedBox(
//           height: 12,
//         ),
//         TextFormField(
//           controller: _lessThanController,
//           decoration: InputDecoration(
//               isDense: true, label: Text(context.l10n.lessThan), errorText: _errorText),
//           keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: true),
//           inputFormatters: <TextInputFormatter>[
//             FilteringTextInputFormatter.allow(
//               RegExp(r'^\d{0,4}'),
//             ),
//           ],
//         ),
//         if (filterDateLogForm != null) ...[
//           const SizedBox(
//             height: 8,
//           ),
//           filterDateLogForm
//         ]
//       ],
//     );
//   }
// }
