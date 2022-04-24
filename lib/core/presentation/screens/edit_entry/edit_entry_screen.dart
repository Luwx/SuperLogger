import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/value_controller.dart';

import 'package:super_logger/utils/extensions.dart';

class EditEntryScreen extends StatefulWidget {
  const EditEntryScreen({Key? key, required this.log, required this.loggableController})
      : super(key: key);
  final LoggableController loggableController;
  final Log log;

  @override
  _EditEntryScreenState createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends State<EditEntryScreen> {
  //late String _note;
  late DateTime _dateTime;
  late TextEditingController _noteController;
  late final ValueEitherController _valueController;
  late LoggableUiHelper loggableHelper;

  bool _busy = false;

  String formatDate(DateTime dateTime) {
    final DateFormat outputFormat = DateFormat("E, MMM d, yyyy");
    return outputFormat.format(dateTime);
  }

  ButtonStyle dateTimeStyle(BuildContext context) => TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(30),
        shape: const StadiumBorder(),
      );

  @override
  void initState() {
    super.initState();
    _dateTime = widget.log.timestamp;
    _noteController = TextEditingController(text: widget.log.note);

    loggableHelper =
        locator.get<MainFactory>().getUiHelper(widget.loggableController.loggable.type);

    _valueController =
        locator.get<MainFactory>().makeValueController(widget.loggableController.loggable.type);

    _valueController.addListener(() {
      //print("change!!!!!");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.editEntry),
        actions: <Widget>[
          TextButton(
              style: TextButton.styleFrom(
                primary: Colors.white,
              ),
              child: Text(context.l10n.save),
              onPressed: () async {
                assert(_valueController.isSetUp, "value Controller is not set up");
                _valueController.value.fold(
                  (error) => null,
                  (value) async {
                    if (_dateTime.millisecondsSinceEpoch !=
                            widget.log.timestamp.millisecondsSinceEpoch ||
                        value != widget.log.value ||
                        _noteController.text != widget.log.note) {
                      Log modifiedLog = locator.get<MainFactory>().makeNewLog(loggableHelper.type,
                          id: widget.log.id,
                          timestamp: _dateTime,
                          value: value,
                          note: _noteController.text);
                      setState(() {
                        _busy = true;
                      });
                      await widget.loggableController.updateLog(widget.log, modifiedLog);
                      setState(() {
                        _busy = false;
                      });
                      await Future.delayed(const Duration(milliseconds: 100));
                      Navigator.pop(context);
                    } else {
                      // No change done
                      print("no change done?");
                    }
                  },
                );
              })
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(
                    height: 22,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      context.l10n.dateAndTime,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground.withAlpha(180),
                        fontSize: 16,
                        //fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 11,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TextButton(
                          style: dateTimeStyle(context),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _dateTime,
                                firstDate: DateTime(2000, 1),
                                lastDate: DateTime.now());

                            if (picked != null && picked != _dateTime) {
                              setState(() {
                                _dateTime = DateTime(picked.year, picked.month, picked.day,
                                    _dateTime.hour, _dateTime.minute, _dateTime.second);
                              });
                            }
                          },
                          child: Text(formatDate(_dateTime))),
                      Expanded(child: Container()),
                      TextButton(
                        style: dateTimeStyle(context),
                        onPressed: () async {
                          String? newTime = await showDialog(
                              context: context,
                              builder: (context) {
                                return TimePickerDialog(_dateTime.formattedTimeHMS);
                              });
                          if (newTime == null) return;
                          if (newTime != _dateTime.formattedTimeHMS) {
                            List<String> newTimeSplit = newTime.split(":");
                            setState(() {
                              _dateTime = DateTime(
                                  _dateTime.year,
                                  _dateTime.month,
                                  _dateTime.day,
                                  int.parse(newTimeSplit[0]),
                                  int.parse(newTimeSplit[1]),
                                  int.parse(newTimeSplit[2]));
                            });
                          }
                        },
                        child: Text(_dateTime.formattedTimeHMS),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 22,
                  ),
                  loggableHelper.getEditEntryValueWidget(
                      widget.loggableController.loggable.loggableProperties,
                      _valueController,
                      widget.log.value),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: TextField(
                      controller: _noteController,
                      autofocus: false,
                      maxLength: 150,
                      minLines: 3,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                          filled: true,
                          labelText: context.l10n.note,
                          hintText: context.l10n.writeANote
                          //border: OutlineInputBorder()
                          ),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ),
          if (_busy)
            const Center(
              child: CircularProgressIndicator(),
            )
        ],
      ),
    );
  }
}

class TimePickerDialog extends StatefulWidget {
  final String initTime;

  const TimePickerDialog(this.initTime, {Key? key}) : super(key: key);

  @override
  _TimePickerDialogState createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<TimePickerDialog> {
  @override
  void initState() {
    super.initState();
    List<String> splitTime = widget.initTime.split(':');

    hourController = TextEditingController(text: splitTime[0]);
    minuteController = TextEditingController(text: splitTime[1]);
    secondController = TextEditingController(text: splitTime[2]);
  }

  late TextEditingController hourController;
  late TextEditingController minuteController;
  late TextEditingController secondController;

  bool validTime = true;

  TextStyle timeStyle = const TextStyle(fontSize: 20);
  TextStyle timeLabelStyle = const TextStyle(fontSize: 12, color: Colors.grey);
  TextStyle invalidTimeLabelStyle =
      const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold);

  bool isValidTime(String hour, String minute, String second) {
    int h = hour == "" ? 0 : int.parse(hour);
    int m = minute == "" ? 0 : int.parse(minute);
    int s = second == "" ? 0 : int.parse(second);
    if (h >= 0 && h <= 23 && m >= 0 && m <= 59 && s >= 0 && s <= 59) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.time),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      actions: <Widget>[
        TextButton(
            child: Text(context.l10n.cancel),
            onPressed: () {
              Navigator.pop(context);
            }),
        TextButton(
            child: Text(context.l10n.ok),
            onPressed: () {
              if (isValidTime(hourController.text, minuteController.text, secondController.text)) {
                final String t = hourController.text.padLeft(2, '0') +
                    ":" +
                    minuteController.text.padLeft(2, '0') +
                    ":" +
                    secondController.text.padLeft(2, '0');

                Navigator.pop(context, t);
              } else {
                setState(() {
                  validTime = false;
                });
              }
            })
      ],
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          //crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        style: timeStyle,
                        controller: hourController,
                        decoration: const InputDecoration(counterText: ''),
                        maxLength: 2,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: false, signed: true),
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}')),
                        ],
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text("hour", style: timeLabelStyle),
                      ),
                    ],
                  ),
                ),
                Text(
                  " : ",
                  style: timeStyle,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        style: timeStyle,
                        controller: minuteController,
                        decoration: const InputDecoration(counterText: ''),
                        maxLength: 2,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: false, signed: true),
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}')),
                        ],
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text("minute", style: timeLabelStyle),
                      ),
                    ],
                  ),
                ),
                Text(
                  " : ",
                  style: timeStyle,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        style: timeStyle,
                        controller: secondController,
                        decoration: const InputDecoration(counterText: ''),
                        maxLength: 2,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: false, signed: true),
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}')),
                        ],
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text("second", style: timeLabelStyle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
