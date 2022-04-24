import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/core/presentation/theme/dimensions.dart';
import 'package:super_logger/features/counter/counter_factory.dart';
import 'package:super_logger/features/counter/models/counter_properties.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';
import 'package:fpdart/fpdart.dart' show Right;

import 'custom_add_widget.dart';

class EditCounterPropertiesForm extends StatefulWidget {
  final CounterProperties? counterProperties;
  final ValueEitherValidOrErrController<MappableObject> propertiesController;

  const EditCounterPropertiesForm(
      {Key? key, this.counterProperties, required this.propertiesController})
      : super(key: key);

  @override
  _EditCounterPropertiesFormState createState() => _EditCounterPropertiesFormState();
}

class _EditCounterPropertiesFormState extends State<EditCounterPropertiesForm> {
  CounterProperties get _currentProperties {
    return widget.propertiesController.valueNoValidation as CounterProperties;
  }

  void _setProperties(CounterProperties properties) {
    widget.propertiesController.setValue(Right(properties));
  }

  void _propertiesListener() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.propertiesController
        .setValue(Right(widget.counterProperties ?? CounterFactory().createDefaultProperties()));

    widget.propertiesController.addListener(_propertiesListener);
  }

  @override
  void dispose() {
    widget.propertiesController.removeListener(_propertiesListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      //padding: EdgeInsets.all(22),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        initialValue: _currentProperties.prefix,
                        decoration: InputDecoration(filled: true, labelText: context.l10n.prefix),
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'^.{0,12}')),
                        ],
                        onChanged: (s) {
                          setState(() {
                            _setProperties(_currentProperties.copyWith(prefix: s));
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppDimens.defaultSpacing),
                    Expanded(
                      child: TextFormField(
                          initialValue: _currentProperties.suffix,
                          decoration: InputDecoration(filled: true, labelText: context.l10n.suffix),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(RegExp(r'^.{0,12}')),
                          ],
                          onChanged: (s) {
                            setState(() {
                              _setProperties(_currentProperties.copyWith(suffix: s));
                            });
                          }),
                    ),
                  ],
                )
              ],
            ),
          ),
          SwitchListTile(
            title: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(context.l10n.positiveValuesOnly),
            ),
            value: _currentProperties.positiveOnly,
            onChanged: (bool value) {
              CounterProperties properties = _currentProperties;
              properties = properties.copyWith(positiveOnly: value);
              if (properties.positiveOnly &&
                  properties.minusButtonBehavior == MinusButtonBehavior.minusOne) {
                properties =
                    properties.copyWith(minusButtonBehavior: MinusButtonBehavior.deleteLastEntry);
              }
              _setProperties(properties);
            },
          ),
          SwitchListTile(
            title: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(context.l10n.unitary),
            ),
            value: _currentProperties.unitary,
            onChanged: (bool value) {
              _setProperties(_currentProperties.copyWith(unitary: value));
            },
          ),
          // ListTile(
          //   enabled: !_currentProperties.unitary,
          //   subtitle: Padding(
          //     padding: const EdgeInsets.only(left: 14),
          //     child: Text(context.l10n.addButtonBehaviorDescription),
          //   ),
          //   title: Padding(
          //     padding: const EdgeInsets.only(left: 14),
          //     child: Text(context.l10n.addButtonBehavior),
          //   ),
          //   trailing: Row(
          //     mainAxisSize: MainAxisSize.min,
          //     children: [
          //       _currentProperties.addButtonBehavior == AddButtonBehavior.defaultAction
          //           ? Text(context.l10n.counterAddButtonBehaviorAddOne)
          //           : Text(context.l10n.counterAddButtonBehaviorShowCustomValues),
          //       const SizedBox(
          //         width: 4,
          //       ),
          //       const Icon(
          //         Icons.keyboard_arrow_right,
          //       ),
          //     ],
          //   ),
          //   onTap: () {
          //     _showAddButtonBehaviorDialog();
          //   },
          // ),
          SwitchListTile(
            title: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(context.l10n.showMinusButton),
            ),
            value: _currentProperties.showMinusButton,
            onChanged: (bool value) {
              _setProperties(_currentProperties.copyWith(showMinusButton: value));
            },
          ),
          ListTile(
            enabled: _currentProperties.showMinusButton,
            title: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(context.l10n.minusButtonBehavior),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_currentProperties.minusButtonBehavior == MinusButtonBehavior.deleteLastEntry
                    ? context.l10n.counterMinusButtonBehaviorDeleteLastEntry
                    : context.l10n.counterMinusButtonBehaviorAddMinusOne),
                const SizedBox(
                  width: 4,
                ),
                const Icon(
                  Icons.keyboard_arrow_right,
                ),
              ],
            ),
            onTap: () {
              _showMinusButtonBehaviorDialog();
            },
          ),
        ],
      ),
    );
  }

  Future<int?> _showEditValueDialog(int? initVal) async {
    return await showDialog<int>(
      context: context,
      builder: (context) {
        TextEditingController _amountController = TextEditingController(text: initVal?.toString());
        RegExp signed = RegExp(r'^\d{0,4}');
        RegExp unsigned = RegExp(r'^-?\d{0,4}');
        bool _validAmount = true;

        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(initVal == null ? context.l10n.newValue : context.l10n.editValue),
            content: TextField(
              controller: _amountController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount',
                filled: true,
                errorText: !_validAmount ? context.l10n.invalidValues : null,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(
                    _currentProperties.positiveOnly ? signed : unsigned),
              ],
              onChanged: (String s) {
                if (s != "" && s != "-") {
                  if (int.parse(s) == 0 && _validAmount) {
                    setState(() {
                      _validAmount = false;
                    });
                  } else if (int.parse(s) != 0 && !_validAmount) {
                    setState(() {
                      _validAmount = true;
                    });
                  }
                }
              },
              onSubmitted: (String s) {
                if (_validAmount) {
                  Navigator.pop(context, int.parse(s));
                }
              },
            ),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(context.l10n.cancel)),
              TextButton(
                  onPressed: () {
                    if (_validAmount) {
                      Navigator.pop(context, int.parse(_amountController.text));
                    }
                  },
                  child: Text(context.l10n.ok)),
            ],
          );
        });
      },
    );
  }

  void _showAddButtonBehaviorDialog() async {
    AddButtonBehavior opt = _currentProperties.addButtonBehavior;
    bool showValuesWidget = opt == AddButtonBehavior.addDialog;

    double sheetHeight() {
      if (opt == AddButtonBehavior.addDialog) {
        return _currentProperties.addButtonDialogValues.length > 3 ? 400 : 350;
      } else {
        return 240;
      }
    }

    List<Widget> valueTiles() {
      List<Widget> list = [];
      for (int i = 0; i < _currentProperties.addButtonDialogValues.length; i++) {
        list.add(
          TextButton(
            style: TextButton.styleFrom(
              primary: _currentProperties.addButtonDialogValues[i] > 0 ? Colors.green : Colors.red,
              backgroundColor: _currentProperties.addButtonDialogValues[i] > 0
                  ? Colors.green[50]
                  : Colors.red[50],
              minimumSize: const Size(72, 34),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0),
                //side: BorderSide(color: Colors.green),
              ),
            ),
            child: Text(_currentProperties.addButtonDialogValues[i].toString()),
            onPressed: () async {
              int? val = await _showEditValueDialog(_currentProperties.addButtonDialogValues[i]);
              if (val != null) {
                setState(() {
                  _setProperties(_currentProperties.copyWith(
                      addButtonDialogValues: _currentProperties.addButtonDialogValues.put(i, val)));
                });
              }
            },
          ),
        );
      }

      return list;
    }

    AddButtonBehavior? newOpt = await showModalBottomSheet<AddButtonBehavior>(
      enableDrag: false,
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.fastOutSlowIn,
            height: sheetHeight(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.fromLTRB(26, 26, 26, 20),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "Add button behavior",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                RadioListTile<int>(
                  title: Text(context.l10n.counterAddButtonBehaviorDefaultActionLabel),
                  value: AddButtonBehavior.defaultAction.index,
                  groupValue: opt.index,
                  onChanged: (int? value) {
                    setState(() {
                      opt = AddButtonBehavior.values[value!];
                      showValuesWidget = opt == AddButtonBehavior.addDialog;
                    });
                  },
                ),
                RadioListTile<int>(
                  title: Text(context.l10n.counterCustomValues),
                  value: AddButtonBehavior.addDialog.index,
                  groupValue: opt.index,
                  onChanged: (int? value) {
                    setState(() {
                      opt = AddButtonBehavior.values[value!];
                      Timer(const Duration(milliseconds: 300), () {
                        setState(() {
                          showValuesWidget = opt == AddButtonBehavior.addDialog;
                        });
                      });
                    });
                  },
                ),
                //if(opt == AddButtonBehavior.addDialog) Divider(),
                Expanded(
                  child: AnimatedOpacity(
                    opacity: showValuesWidget ? 1.0 : 0.0,
                    curve: Curves.easeOut,
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        const Divider(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(left: 26.0),
                              child: Text(context.l10n.values),
                            ),
                            IconButton(
                                onPressed: _currentProperties.addButtonDialogValues.length == 4
                                    ? null
                                    : () async {
                                        int? val = await _showEditValueDialog(null);
                                        if (val != null) {
                                          setState(() {
                                            _currentProperties.addButtonDialogValues.add(val);
                                          });
                                        }
                                      },
                                icon: const Icon(Icons.add)),
                            IconButton(
                                onPressed: _currentProperties.addButtonDialogValues.isEmpty
                                    ? null
                                    : () {
                                        setState(() {
                                          _currentProperties.addButtonDialogValues.removeLast();
                                        });
                                      },
                                icon: const Icon(Icons.remove)),
                            Expanded(child: Container()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 26.0),
                              child: Text(
                                  _currentProperties.addButtonDialogValues.length.toString() +
                                      "/" +
                                      4.toString()),
                            )
                          ],
                        ),
                        _currentProperties.addButtonDialogValues.isEmpty
                            ? const Expanded(
                                child: Center(
                                child: Text(
                                  "No values",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ))
                            : Expanded(
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: CustomAddWidgetGrid(
                                      children: valueTiles(),
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
                //Expanded(child: Container()),
                Row(
                  //mainAxisAlignment: MainAxisAlignment.spaceAround,
                  //mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Expanded(
                      child: TextButton(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(context.l10n.cancel),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(context.l10n.ok),
                        ),
                        onPressed: !(opt == AddButtonBehavior.defaultAction ||
                                opt == AddButtonBehavior.addDialog &&
                                    _currentProperties.addButtonDialogValues.isNotEmpty)
                            ? null
                            : () {
                                Navigator.pop(context, opt);
                              },
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        });
      },
    );

    if (newOpt != null) {
      _setProperties(_currentProperties.copyWith(addButtonBehavior: newOpt));
      //_currentProperties.addButtonBehavior = newOpt;

    }
  }

  void _showMinusButtonBehaviorDialog() async {
    MinusButtonBehavior opt = _currentProperties.minusButtonBehavior;

    MinusButtonBehavior? newOpt = await showModalBottomSheet<MinusButtonBehavior>(
      enableDrag: false,
      //isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 26, 26, 20),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    context.l10n.minusButtonBehavior,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              RadioListTile<int>(
                title: Text(context.l10n.counterMinusButtonBehaviorDeleteLastEntry),
                value: MinusButtonBehavior.deleteLastEntry.index,
                groupValue: opt.index,
                onChanged: (int? value) {
                  setState(() {
                    opt = MinusButtonBehavior.values[value!];
                  });
                },
              ),
              if (!_currentProperties.positiveOnly)
                RadioListTile<int>(
                  title: Text(context.l10n.counterMinusButtonBehaviorAddMinusOne),
                  value: MinusButtonBehavior.minusOne.index,
                  groupValue: opt.index,
                  onChanged: (int? value) {
                    setState(() {
                      opt = MinusButtonBehavior.values[value!];
                    });
                  },
                ),
              //Expanded(child: Container()),
              Row(
                //mainAxisAlignment: MainAxisAlignment.spaceAround,
                //mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Expanded(
                    child: TextButton(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(context.l10n.cancel),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(context.l10n.ok),
                      ),
                      onPressed: () {
                        Navigator.pop(context, opt);
                      },
                    ),
                  )
                ],
              )
            ],
          );
        });
      },
    );

    if (newOpt != null) {
      _setProperties(_currentProperties.copyWith(minusButtonBehavior: newOpt));
      //_minusButtonBehavior = newOpt;
    }
  }
}
