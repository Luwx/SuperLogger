import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_logger/features/counter/models/counter_properties.dart';
import 'package:super_logger/utils/value_controller.dart';

class CounterValueEditWidget extends StatefulWidget {
  final ValueEitherController<int> controller;
  final CounterProperties counterProperties;
  final int? logValue;
  const CounterValueEditWidget(
      {Key? key, required this.controller, required this.counterProperties, required this.logValue})
      : super(key: key);

  @override
  _CounterValueEditWidgetState createState() => _CounterValueEditWidgetState();
}

class _CounterValueEditWidgetState extends State<CounterValueEditWidget> {
  bool _validAmount = true;
  //late int _value;

  @override
  @override
  Widget build(BuildContext context) {
    return amountWidget();
  }

  @override
  void initState() {
    super.initState();
    //_value = widget.log?.value ?? 1;
    widget.controller.setRightValue(widget.logValue ?? 1);
  }

  Widget amountWidget() {
    RegExp signed = RegExp(r'^\d{0,4}');
    RegExp unsigned = RegExp(r'^-?\d{0,4}');
    if (!widget.counterProperties.unitary) {
      return TextFormField(
        initialValue: widget.logValue?.toString() ?? "1",
        style: const TextStyle(fontSize: 20),
        autofocus: false,
        decoration: InputDecoration(
          labelText: 'Amount',
          filled: true,
          errorText: !_validAmount ? 'Invalid amount' : null,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: true),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(
              widget.counterProperties.positiveOnly ? signed : unsigned),
        ],
        onChanged: (String s) {
          if (s != "" && s != "-") {

            if (int.parse(s) == 0 && _validAmount) {
              setState(() {
                _validAmount = false;
                widget.controller.setErrorValue("Invalid value");
              });
            } else if (int.parse(s) != 0) {
              if (!_validAmount) {
                setState(() {
                  _validAmount = true;
                });
              }
              widget.controller.setRightValue(int.parse(s));
            }
          } else {
            widget.controller.setErrorValue("Invalid value");
            if (_validAmount) {
              setState(() {
                _validAmount = false;
              });
            }
          }
        },
      );
    } else {
      if (widget.counterProperties.positiveOnly) {
        return TextField(
          style: const TextStyle(fontSize: 20),
          enabled: false,
          controller: TextEditingController(text: "1"),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Amount',
            filled: true,
          ),
        );
      } else {
        return Column(
          children: <Widget>[
            Align(
              alignment: Alignment.topLeft,
              child: Text("Amount", style: TextStyle(color: Colors.grey[700])),
            ),
            const SizedBox(
              height: 11,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      RadioListTile<int>(
                        title: const Text('+1'),
                        value: 1,
                        // groupValue: widget.controller.value,
                        groupValue: widget.controller.value.fold((l) => null, (value) => value),
                        onChanged: (int? newValue) {
                          setState(() {
                            widget.controller.setRightValue(newValue!);
                          });
                        },
                      ),
                      RadioListTile<int>(
                        title: const Text('-1'),
                        value: -1,
                        //groupValue: widget.controller.value,
                        groupValue: widget.controller.value.fold((l) => null, (value) => value),
                        onChanged: (int? newValue) {
                          setState(() {
                            widget.controller.setRightValue(newValue!);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        );
      }
    }
  }
}
