import 'package:flutter/material.dart';
import 'package:super_logger/features/number/models/number_properties.dart';
import 'package:super_logger/features/number/presentation/number_input_widgets.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';

class NumberAddButtonDialog extends StatefulWidget {
  final NumberProperties valueProperties;

  const NumberAddButtonDialog({required this.valueProperties, Key? key}) : super(key: key);

  @override
  _NumberAddButtonDialogState createState() => _NumberAddButtonDialogState();
}

class _NumberAddButtonDialogState extends State<NumberAddButtonDialog> {
  bool _showSlider = false;
  bool _isInSliderPage = false;

  final _valueFocus = FocusNode();

  late ValueEitherController<double> _valueController;
  late TextEditingController _amountController;

  bool _isValid = false;

  void _valueListener() {
    bool valid;

    if (!_valueController.isSetUp) {
      valid = false;
    } else {
      valid = _valueController.value.fold((l) => false, (r) => true);
    }

    if (valid != _isValid) {
      setState(() {
        _isValid = valid;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _showSlider = NumberPropertiesHelper.shouldUseSlider(widget.valueProperties);
    _isInSliderPage = _showSlider;

    _valueController = ValueEitherController<double>();
    _valueController.addListener(_valueListener);
    if (_showSlider) {
      _valueController.setRightValue(widget.valueProperties.min!.toDouble());
    } else {
      _valueController.setErrorValue("no initial value");
    }

    if (_showSlider) {
      _amountController = TextEditingController(
          text: _valueController.value.fold((l) => null, (r) => r.toString()));
    } else {
      _amountController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //if (_isInSliderPage) FocusScope.of(context).unfocus();
    return AlertDialog(
      title: Text(context.l10n.newValue),
      content: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        sizeCurve: Curves.easeOutCubic,
        crossFadeState: _isInSliderPage ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: NumberTextField(
            valueProperties: widget.valueProperties,
            valueFocus: _valueFocus,
            shouldHaveInitialFocus: !_showSlider,
            valueController: _valueController,
            title: context.l10n.amount,
          ),
        ),
        secondChild: !_showSlider
            ? Container()
            : ValueSlider(
                valueProperties: widget.valueProperties,
                controller: _valueController,
                title: context.l10n.amount,
              ),
      ),
      actions: <Widget>[
        Row(
          children: <Widget>[
            const SizedBox(width: 10.0),
            if (_showSlider)
              IconButton(
                color: Theme.of(context).colorScheme.primary,
                icon: _isInSliderPage ? const Icon(Icons.keyboard) : const Icon(Icons.straighten),
                onPressed: () {
                  setState(() {
                    _isInSliderPage = !_isInSliderPage;
                    if (_isInSliderPage) {
                      // hide the keyboard
                      FocusScope.of(context).unfocus();
                      // if (widget.valueProperties.isStringValueValid(_amountController.text)) {
                      //   _valueController.setRightValue(double.parse(_amountController.text));
                      // }
                    } else {
                      _amountController.text = _valueController.value.fold(
                        (l) => "",
                        (r) => r.toStringAsFixed(2),
                      );
                      FocusScope.of(context).requestFocus(_valueFocus);
                    }
                  });
                },
              ),
            Expanded(
              child: Container(
                alignment: AlignmentDirectional.centerEnd,
                constraints: const BoxConstraints(minHeight: 52.0),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: OverflowBar(
                  spacing: 8,
                  overflowAlignment: OverflowBarAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(context.l10n.cancel),
                    ),
                    TextButton(
                      onPressed: !_isValid
                          ? null
                          : () {
                              _valueController.value.fold(
                                (error) {},
                                (value) {
                                  Navigator.pop(context, value.roundDouble(2));
                                },
                              );
                            },
                      child: Text(context.l10n.ok),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
