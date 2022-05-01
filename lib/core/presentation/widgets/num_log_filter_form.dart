import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_logger/core/models/filters.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/number_reg_exp_helper.dart';
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

class NumLogFilterForm extends StatefulWidget {
  const NumLogFilterForm({
    Key? key,
    required this.controller,
    this.allowDecimals = true,
    this.allowNegative = true,
  }) : super(key: key);
  final ValueEitherController<ValueFilter> controller;
  final bool allowDecimals;
  final bool allowNegative;

  @override
  _NumLogFilterFormState createState() => _NumLogFilterFormState();
}

class _NumLogFilterFormState extends State<NumLogFilterForm> {
  late _FilterType _filter;

  final TextEditingController _textController = TextEditingController();

  late final List<TextInputFormatter> _formatter;

  @override
  void initState() {
    super.initState();
    _formatter = <TextInputFormatter>[
      FilteringTextInputFormatter.allow(
        NumberRegExpHelper.inputRegex(
          widget.allowNegative,
          widget.allowDecimals,
        ),
      ),
    ];
    if (widget.controller.isSetUp) {
      final filter = widget.controller.value.fold(
        (l) => null,
        (r) => r,
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
    ValueFilter Function(double val)? getFilter;
    switch (_filter) {
      case _FilterType.removeLargerThan:
        getFilter = (val) => NumFilterOutLargerThan(val);
        continue singleValue;
      case _FilterType.removeLessThan:
        getFilter ??= (val) => NumFilterOutLessThan(val);
        continue singleValue;
      singleValue:
      case _FilterType.equalTo:
        getFilter ??= (val) => NumFilterOutNotEqualTo(val);
        editWidget = TextFormField(
          controller: _textController,
          decoration: InputDecoration(
            isDense: true,
            hintText: context.l10n.value,
            //errorText: errorString,
          ),
          inputFormatters: _formatter,
          keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: true),
          onChanged: (s) {
            double? val = double.tryParse(s);
            if (val != null) {
              widget.controller.setRightValue(getFilter!(val));
            } else {
              widget.controller.setErrorValue("Invalid filter value: $s");
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
                  _textController.text = "";
                  widget.controller.setErrorValue("No value selected");
                });
              }
            },
            items: _FilterType.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(_getFilterTranslation(context, type)),
                  ),
                )
                .toList(),
          ),
        ),
        editWidget
      ],
    );
  }
}

class NumInBetweenFilterForm extends StatefulWidget {
  const NumInBetweenFilterForm({Key? key, required this.controller}) : super(key: key);

  final ValueEitherController<ValueFilter> controller;

  @override
  _NumInBetweenFilterFormState createState() => _NumInBetweenFilterFormState();
}

class _NumInBetweenFilterFormState extends State<NumInBetweenFilterForm> {
  String? _errorText;

  String? _greaterThanError;
  String? _lessThanError;

  late final TextEditingController _greaterThanController;
  late final TextEditingController _lessThanController;

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

    if (_errorText != null) {
      widget.controller.setErrorValue(_errorText!);
    } else {
      widget.controller.setRightValue(NumFilterOutNotInBetween(lessThanVal, greaterThanVal));
    }

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
        (r) => r,
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
