import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart' show Option;
import 'package:super_logger/core/models/filters.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';

enum _FilterType { removeLargerThan, removeLessThan, equalTo, between }

String _getFilterTranslation(BuildContext context, _FilterType type) {
  switch (type) {
    case _FilterType.removeLargerThan:
      return context.l10n.showSmallerThan;
    case _FilterType.removeLessThan:
      return context.l10n.showGreaterThan;
    case _FilterType.equalTo:
      return context.l10n.showEqualTo;
    case _FilterType.between:
      return context.l10n.showValuesInBetween;
  }
}

class NumLogFilterForm2 extends StatefulWidget {
  const NumLogFilterForm2({Key? key, required this.controller}) : super(key: key);
  final ValueEitherController<Option<ValueFilter>> controller;

  @override
  _NumLogFilterForm2State createState() => _NumLogFilterForm2State();
}

class _NumLogFilterForm2State extends State<NumLogFilterForm2> {
  late _FilterType _filter;

  final formatter = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(
      RegExp(r'^-?\d{0,9}'),
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.controller.isSetUp) {
      final filter = widget.controller.value.fold(
        (l) => null,
        (r) => r.match(
          (some) => some,
          () => null,
        ),
      );

      if (filter != null) {
        if (filter is NumFilterOutLargerThan) {
          _filter = _FilterType.removeLargerThan;
        } else if (filter is NumFilterOutLessThan) {
          _filter = _FilterType.removeLessThan;
        } else if (filter is NumFilterOutNotEqualTo) {
          _filter = _FilterType.equalTo;
        } else if (filter is NumFilterOutNotInBetween) {
          _filter = _FilterType.between;
        } else {
          assert(false, "Invalid filter");
        }
      } else {
        _filter = _FilterType.between;
      }
    } else {
      _filter = _FilterType.between;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget editWidget;
    switch (_filter) {
      case _FilterType.removeLargerThan:
      case _FilterType.removeLessThan:
      case _FilterType.equalTo:
        editWidget = TextFormField(
          decoration: InputDecoration(
            isDense: true,
            label: Text(context.l10n.value),
            //errorText: errorString,
          ),
          inputFormatters: formatter,
          keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: true),
          onChanged: (s) {
            double? val = double.tryParse(s);
            if (val != null) {
              ValueFilter filter;

              // TODO: clean this code...
              if (_filter == _FilterType.equalTo) {
                filter = NumFilterOutNotEqualTo(val);
              } else if (_filter == _FilterType.removeLargerThan) {
                filter = NumFilterOutLargerThan(val);
              } else /*if(_filter == _FilterType.removeLessThan)*/ {
                filter = NumFilterOutLessThan(val);
              }
              widget.controller.setRightValue(Option.of(filter));

              // if (errorString != null) {
              //   setState(() {
              //     errorString = null;
              //   });
              // }
            } else {
              widget.controller.setErrorValue("Invalid filter value: $val");
              // if (errorString == null) {
              //   setState(() {
              //     errorString = "Invalid Value";
              //   });
              // }
            }
          },
        );
        break;
      case _FilterType.between:
        editWidget = NumInBetweenFilterForm(controller: widget.controller);
        break;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DropdownButtonHideUnderline(
          child: DropdownButton<_FilterType>(
            value: _filter,
            //isExpanded: true,
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
            onChanged: (_FilterType? filter) {
              if (filter != null) {
                setState(() {
                  _filter = filter;
                  widget.controller.setRightValue(Option.none());
                });
              }
            },
            items: [
              DropdownMenuItem(
                value: _FilterType.removeLargerThan,
                child: Text(_getFilterTranslation(context, _FilterType.removeLargerThan)),
              ),
              DropdownMenuItem(
                value: _FilterType.removeLessThan,
                child: Text(_getFilterTranslation(context, _FilterType.removeLessThan)),
              ),
              DropdownMenuItem(
                value: _FilterType.equalTo,
                child: Text(_getFilterTranslation(context, _FilterType.equalTo)),
              ),
              DropdownMenuItem(
                value: _FilterType.between,
                child: Text(_getFilterTranslation(context, _FilterType.between)),
              ),
            ],
          ),
        ),
        editWidget
      ],
    );
  }
}

class NumInBetweenFilterForm extends StatefulWidget {
  const NumInBetweenFilterForm({Key? key, required this.controller}) : super(key: key);

  final ValueEitherController<Option<ValueFilter>> controller;

  @override
  _NumInBetweenFilterFormState createState() => _NumInBetweenFilterFormState();
}

class _NumInBetweenFilterFormState extends State<NumInBetweenFilterForm> {
  String? _errorText;

  String? _greaterThanError;
  String? _lessThanError;

  late final TextEditingController _greaterThanController;
  late final TextEditingController _lessThanController;

  bool _isValid(String greaterThan, String lessThan) {
    int? greaterThanVal = int.tryParse(greaterThan);
    int? lessThanVal = int.tryParse(lessThan);

    if (greaterThanVal != null && lessThanVal != null) {
      return greaterThanVal >= lessThanVal;
    }

    return true;
  }

  void _textEditingListener() {
    int? greaterThanVal = int.tryParse(_greaterThanController.text);

    if (greaterThanVal == null) {
      setState(() {
        _greaterThanError = "Invalid value";
      });
      return;
    }

    int? lessThanVal = int.tryParse(_lessThanController.text);

    if (lessThanVal == null) {
      setState(() {
        _lessThanError = "Invalid value";
      });
      return;
    }

    if (greaterThanVal <= lessThanVal) {
      setState(() {
        _lessThanError = null;
        _greaterThanError = null;
        _errorText = "Invalid values";
      });
    }

    widget.controller
        .setRightValue(Option.of(NumFilterOutNotInBetween(lessThanVal, greaterThanVal)));

    if (_errorText != null || _greaterThanError != null || _lessThanError != null) {
      setState(() {
        _errorText = null;
        _greaterThanError = null;
        _lessThanError = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    String greaterThanText = "";
    String lessThanText = "";
    if (widget.controller.isSetUp) {
      final filter = widget.controller.value.fold(
        (l) => null,
        (r) => r.match(
          (some) => some,
          () => null,
        ),
      );
      if (filter != null) {
        greaterThanText = (filter as NumFilterOutNotInBetween).min.toString();
        lessThanText = filter.max.toString();
      }
    }

    _greaterThanController = TextEditingController(text: greaterThanText);
    _lessThanController = TextEditingController(text: lessThanText);

    _greaterThanController.addListener(_textEditingListener);
    _lessThanController.addListener(_textEditingListener);
  }

  @override
  void dispose() {
    _greaterThanController.removeListener(_textEditingListener);
    _lessThanController.removeListener(_textEditingListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextFormField(
          controller: _greaterThanController,
          decoration: const InputDecoration(
            isDense: true,
            label: Text("greater than"),
          ),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(
              RegExp(r'^-?\d{0,9}'),
            ),
          ],
          keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: true),
        ),
        const SizedBox(
          height: 12,
        ),
        TextFormField(
          controller: _lessThanController,
          decoration: const InputDecoration(
            isDense: true,
            label: Text("less than"),
          ),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(
              RegExp(r'^-?\d{0,9}'),
            ),
          ],
          keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: true),
        ),
      ],
    );
  }
}
