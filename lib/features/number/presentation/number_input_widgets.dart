import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_logger/features/number/models/number_properties.dart';
import 'package:super_logger/utils/value_controller.dart';

import 'super_slider.dart';

class NumberTextField extends StatefulWidget {
  final FocusNode? valueFocus;
  final NumberProperties valueProperties;
  final bool shouldHaveInitialFocus;
  final String title;
  final bool centerText;
  final bool showHint;
  final ValueEitherController<double> valueController;

  const NumberTextField({
    Key? key,
    required this.valueProperties,
    this.valueFocus,
    required this.valueController,
    required this.title,
    this.shouldHaveInitialFocus = true,
    this.centerText = false,
    this.showHint = true,
  }) : super(key: key);

  @override
  _NumberTextFieldState createState() => _NumberTextFieldState();
}

class _NumberTextFieldState extends State<NumberTextField> {
  bool _isCurrentAmountValid = true;
  String _errorMessage = "";
  double? _originalValue;

  bool _wasTouched = false;

  final TextEditingController _newController = TextEditingController();

  late String _hintText;

  final RegExp _signedInt = RegExp(r'^\d{0,9}');
  final RegExp _unsignedInt = RegExp(r'^-?\d{0,9}');
  final RegExp _signedFractional = RegExp(r'^\d{0,6}\.?\d{0,3}');
  final RegExp _unsignedFractional = RegExp(r'^-?\d{0,6}\.?\d{0,3}');

  RegExp _inputRegex(bool positiveOnly, bool allowDecimal) {
    if (positiveOnly) {
      if (allowDecimal) {
        return _signedFractional;
      } else {
        return _signedInt;
      }
    } else {
      if (allowDecimal) {
        return _unsignedFractional;
      } else {
        return _unsignedInt;
      }
    }
  }

  String _generateHintText() {
    String hintText = "";
    int hintVal;
    int? max = widget.valueProperties.max;
    int? min = widget.valueProperties.min;

    Random rnd = Random();

    if (max != null) {
      if (min != null) {
        hintVal = min + rnd.nextInt((max - min) + 1);
      } else {
        hintVal = max - rnd.nextInt(100);
      }
    } else if (min != null) {
      hintVal = min + rnd.nextInt(100);
    } else {
      hintVal = rnd.nextInt(1000);
    }

    hintText = hintVal.toString();

    if (widget.valueProperties.allowDecimal) {
      double decimalVal = rnd.nextDouble();
      String decimalString = decimalVal.toStringAsFixed(2).replaceFirst('0', '');

      if (max != null) {
        if (hintVal + decimalVal < max) {
          hintText += decimalString;
        }
      } else {
        hintText += decimalString;
      }
    }
    return hintText;
  }

  @override
  void didUpdateWidget(covariant NumberTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    String? controllerVal = widget.valueController.value.fold((l) => null, (r) => r.toString());

    double? val = double.tryParse(controllerVal ?? "");

    double? current = double.tryParse(_newController.text);

    if (val != null) {
      if (current == null || current != val) {
        _newController.text = val.toString();
      }
    }

    // do not display errors when the widget was not even changed
    if (current == null && !_wasTouched) {
      return;
    }

    NumberPropertiesHelper.isValueValid(current, widget.valueProperties).match(
      (l) {
        _isCurrentAmountValid = false;
        _errorMessage = l.cause;
      },
      (r) {
        _errorMessage = "";
        _isCurrentAmountValid = true;
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _hintText = _generateHintText();

    if (!widget.valueController.isSetUp) {
      widget.valueController.setErrorValue("No value selected", notify: true);
    }

    // //_originalValue = 0;// (TODO: use inital value ) //widget.valueController.value;
    // if (_originalValue != null && widget.textController.text.isEmpty) {
    //   widget.textController.text = _originalValue.toString();
    // }

    String? controllerVal = widget.valueController.value.match((l) => null, (r) => r.toString());
    _newController.text = controllerVal?.toString() ?? "";
  }

  @override
  void dispose() {
    //widget.textController.removeListener(_textControllerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // the contents of textController can change outside of this widget,
    // so we need to recheck if it still valid
    // _validAmount = widget.valueProperties.isValueValid(widget.textController.text) ||
    //     _isInvalidAndOriginalValue();
    return TextFormField(
      controller: _newController,
      autofocus: widget.shouldHaveInitialFocus,
      focusNode: widget.valueFocus,
      textAlign: widget.centerText ? TextAlign.center : TextAlign.start,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(10),
        prefix: widget.valueProperties.prefix.isNotEmpty
            ? Text(widget.valueProperties.prefix + " ")
            : null,
        suffix: widget.valueProperties.suffix.isNotEmpty
            ? Text(" " + widget.valueProperties.suffix)
            : null,
        isDense: false,
        labelText: widget.title.isNotEmpty ? widget.title : null,
        //floatingLabelAlignment: FloatingLabelAlignment.center,
        hintText: widget.showHint ? 'Ex: $_hintText' : null,
        filled: true,
        errorText: !_isCurrentAmountValid ? _errorMessage : null,
        errorMaxLines: 3,
        //helperText: _isInvalidAndOriginalValue() ? "Original value" : null,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(
          _inputRegex(
              (widget.valueProperties.min != null && widget.valueProperties.min! >= 0)
                  ? true
                  : false,
              widget.valueProperties.allowDecimal),
        ),
      ],
      onChanged: (String s) {
        _wasTouched = true;
        if (s != "" && s != "-") {
          if (!_isCurrentAmountValid && double.parse(s) == _originalValue) {
            setState(() {
              _isCurrentAmountValid = true;
            });
            return;
          }

          double val = double.parse(s);
          NumberPropertiesHelper.isValueValid(val, widget.valueProperties).match(
            (error) => setState(() {
              widget.valueController.setErrorValue(error.cause);
              _isCurrentAmountValid = false;
              _errorMessage = error.cause;
            }),
            (validValue) {
              _errorMessage = "";
              widget.valueController.setRightValue(validValue);
              if (!_isCurrentAmountValid) {
                setState(() {
                  _isCurrentAmountValid = true;
                });
              }
            },
          );
        } else {
          widget.valueController.setErrorValue("Invalid value");
          setState(() {
            _isCurrentAmountValid = false;
            _errorMessage = s == "" ? "Enter a value" : "Enter a valid value";
          });
        }
      },
    );
  }
}

class ValueSlider extends StatefulWidget {
  final NumberProperties valueProperties;
  final ValueEitherController<double> controller;
  final String title;
  final bool forDialog;
  final bool dismissible;
  final Widget? menuButton;
  const ValueSlider(
      {Key? key,
      required this.valueProperties,
      required this.controller,
      this.forDialog = true,
      this.dismissible = false,
      required this.title,
      this.menuButton})
      : super(key: key);

  @override
  _ValueSliderState createState() => _ValueSliderState();
}

enum _FocusedInputWidget { slider, textField }

class _ValueSliderState extends State<ValueSlider> {
  final FocusNode _focus = FocusNode();

  _FocusedInputWidget _focusedInputWidget = _FocusedInputWidget.slider;

  // Will be used to send events from the textfield onChange
  // event to the slider drawing widget, so that it doesn't get flooded with rebuilds
  // only the value generated immediately by the onChange will be used
  // as this controller can get out of sync fast
  late ValueEitherController<double> _textFieldValueController;

  @override
  void dispose() {
    _textFieldValueController.dispose();
    super.dispose();
  }

  // due to a issue in super slider caused by wrong calculations in the scroll extent,
  // the initial scroll position may be wrong if it is far from either the start or the end of the slider
  // double _defaultInitialSliderValue() =>
  //     ((widget.valueProperties.max!.toDouble() + widget.valueProperties.min!.toDouble()) ~/ 2)
  //         .toDouble();
  double _defaultInitialSliderValue() => widget.valueProperties.min!.toDouble();

  @override
  void initState() {
    super.initState();
    if (widget.dismissible) assert(widget.menuButton != null);

    assert(widget.valueProperties.max != null && widget.valueProperties.min != null);

    // setup main value controller
    if (!widget.controller.isSetUp) {
      //// skip notify so that it doesn't trigger rebuilds when the widget is building
      widget.controller.setRightValue(_defaultInitialSliderValue(), notify: true);
    }
    widget.controller.value.fold(
      // skip notify so that it doesn't trigger rebuilds when the widget is building
      (error) => widget.controller.setRightValue(_defaultInitialSliderValue(), notify: false),
      (value) {
        assert(value >= widget.valueProperties.min! && value <= widget.valueProperties.max!);
      },
    );

    // setup text field controller
    _textFieldValueController = ValueEitherController<double>();
    _textFieldValueController.setValue(widget.controller.value);

    // sync controllers
    _textFieldValueController.addListener(() {
      widget.controller.setValue(_textFieldValueController.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
            animation: widget.controller,
            builder: (context, child) {
              _textFieldValueController.setValue(widget.controller.value, notify: false);
              return Listener(
                onPointerDown: (_) => _focusedInputWidget = _FocusedInputWidget.textField,
                child: _SliderLabel(
                  forDialog: widget.forDialog,
                  dismissible: widget.dismissible,
                  allowDecimal: widget.valueProperties.allowDecimal,
                  valueController: _textFieldValueController,
                  valueProperties: widget.valueProperties,
                  title: widget.title,
                  focusNode: _focus,
                ),
              );
            }),
        Listener(
          onPointerDown: (_) {
            _focusedInputWidget = _FocusedInputWidget.slider;
            //_focus.canRequestFocus
            //FocusScope.of(context).requestFocus(FocusNode());
          },
          child: AnimatedBuilder(
              animation: _textFieldValueController,
              builder: (context, child) {
                return SuperSlider(
                  current: widget.controller.value.getOrElse(
                    (_) => widget.controller.lastValidValue.getOrElse(
                      () => _defaultInitialSliderValue(),
                    ),
                  ),
                  minValue: widget.valueProperties.min!.toDouble(),
                  maxValue: widget.valueProperties.max!.toDouble(),
                  step: 1,
                  allowDecimal: widget.valueProperties.allowDecimal,
                  onSelectedChanged: (value) {
                    if (_focusedInputWidget != _FocusedInputWidget.textField) {
                      // // silently update the controller value, otherwise this widget
                      // // will be rebuilt too ofter
                      widget.controller.setRightValue(value, notify: true);
                    }
                    //widget.controller.setValue(value);
                  },
                );
              }),
        ),
      ],
    );
  }
}

class _SliderLabel extends StatelessWidget {
  const _SliderLabel({
    Key? key,
    required this.forDialog,
    required this.dismissible,
    //required this.value,
    required this.allowDecimal,
    required this.valueController,
    required this.title,
    this.menuButton,
    required this.valueProperties,
    required this.focusNode,
  }) : super(key: key);

  final bool forDialog;
  final bool dismissible;
  //final double value;
  final String title;
  final bool allowDecimal;
  final Widget? menuButton;
  final ValueEitherController<double> valueController;
  final NumberProperties valueProperties;
  final FocusNode focusNode;

//   @override
//   State<_SliderLabel> createState() => _SliderLabelState();
// }

// class _SliderLabelState extends State<_SliderLabel> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (forDialog)
          const SizedBox(
            height: 4,
          ),
        if (forDialog)
          // Center(
          //   child: Container(
          //     padding: const EdgeInsets.all(12),
          //     decoration: BoxDecoration(
          //         color: Theme.of(context).colorScheme.primary.withAlpha(20),
          //         border: Border.all(width: 2, color: Theme.of(context).colorScheme.primary),
          //         borderRadius: const BorderRadius.all(Radius.circular(8))),
          //     child: Text(
          //       value.toStringAsFixed(allowDecimal ? 1 : 0),
          //       style: TextStyle(fontSize: 22, color: Theme.of(context).colorScheme.primary),
          //     ),
          //   ),
          // ),
          Center(
            child: NumberTextField(
              valueController: valueController,
              //textController: textController,
              valueProperties: valueProperties,
              shouldHaveInitialFocus: false,
              valueFocus: focusNode,
              centerText: true,
              showHint: false,
              title: title,
            ),
          ),
        if (forDialog)
          SizedBox(
            height: 14,
            child: Container(
              width: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        if (!forDialog)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                //widget.valueProperties.title,
                "title",
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(
                width: 10,
              ),
              const Text(
                "blah", //value.toStringAsFixed(allowDecimal ? 1 : 0),
                style: TextStyle(fontSize: 22, color: Colors.green),
              ),
              const SizedBox(
                width: 4,
              ),
              const Text(
                "mmHg",
                style: TextStyle(color: Colors.green),
              ),
              Expanded(child: Container()),
              dismissible
                  ? menuButton ?? Container()
                  : IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.transparent,
                      )),
            ],
          ),
        // const SizedBox(
        //   height: 10,
        // ),
      ],
    );
  }
}
