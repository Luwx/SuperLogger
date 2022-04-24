import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:super_logger/features/color/models/color_log.dart';
import 'package:super_logger/features/color/models/color_properties.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';

class EditColorLog extends StatelessWidget {
  const EditColorLog({Key? key, required this.valueController, required this.properties})
      : super(key: key);
  final ColorProperties properties;
  final ValueEitherController<ColorLog> valueController;

  @override
  Widget build(BuildContext context) {
    HSVColor pickerColor = const HSVColor.fromAHSV(1.0, 0.5, 0.5, 0.5);
    String label = "";

    if (valueController.isSetUp) {
      valueController.value.fold((l) => null, (r) {
        pickerColor = HSVColor.fromColor(r.color);
        label = r.label;
      });
    } else {
      WidgetsBinding.instance!.addPostFrameCallback((_) async {
        valueController.setRightValue(ColorLog(label: "", color: pickerColor.toColor()));
      });
    }

    return SingleChildScrollView(
      //physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColorRingPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) {
              pickerColor = color;
              valueController.setRightValue(
                ColorLog(
                  label: label,
                  color: color.toColor(),
                ),
              );
            },
            enableAlpha: properties.enableAlpha,
            pickerAreaBorderRadius: BorderRadius.circular(12),
          ),
          TextFormField(
            initialValue: label,
            decoration: const InputDecoration(label: Text('label'), isDense: true),
            maxLength: 16,
            onChanged: (s) {
              label = s;
              valueController.setRightValue(
                ColorLog(
                  label: label,
                  color: pickerColor.toColor(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

Future<ColorLog?> editColorLogDialog(
    context, ColorProperties properties, ColorLog? colorLog) async {
  ValueEitherController<ColorLog> controller = ValueEitherController();
  if (colorLog != null) {
    controller.setRightValue(colorLog);
  }
  return await showDialog<ColorLog>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(colorLog == null ? "Pick a color" : "Edit color"),
        content: EditColorLog(
          properties: properties,
          valueController: controller,
        ),
        actions: <Widget>[
          TextButton(
            child: Text(context.l10n.cancel),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text(context.l10n.ok),
            onPressed: () {
              final newLog = controller.value.fold((l) => null, (r) => r);
              if (newLog == null) {
                Navigator.pop(context);
              } else {
                Navigator.pop(context, newLog);
              }
            },
          ),
        ],
      );
    },
  );
}

class ColorRingPicker extends StatefulWidget {
  const ColorRingPicker({
    Key? key,
    required this.pickerColor,
    required this.onColorChanged,
    this.portraitOnly = false,
    this.colorPickerHeight = 250.0,
    this.hueRingStrokeWidth = 20.0,
    this.enableAlpha = false,
    this.displayThumbColor = true,
    this.pickerAreaBorderRadius = const BorderRadius.all(Radius.zero),
  }) : super(key: key);

  final HSVColor pickerColor;
  final ValueChanged<HSVColor> onColorChanged;
  final bool portraitOnly;
  final double colorPickerHeight;
  final double hueRingStrokeWidth;
  final bool enableAlpha;
  final bool displayThumbColor;
  final BorderRadius pickerAreaBorderRadius;

  @override
  _ColorRingPickerState createState() => _ColorRingPickerState();
}

class _ColorRingPickerState extends State<ColorRingPicker> {
  HSVColor currentHsvColor = const HSVColor.fromAHSV(0.0, 0.0, 0.0, 0.0);

  @override
  void initState() {
    currentHsvColor = widget.pickerColor;
    super.initState();
  }

  @override
  void didUpdateWidget(ColorRingPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    currentHsvColor = widget.pickerColor;
  }

  void onColorChanging(HSVColor color) {
    setState(() => currentHsvColor = color);
    widget.onColorChanged(currentHsvColor);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait || widget.portraitOnly) {
      return Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(15),
            child: Stack(alignment: AlignmentDirectional.center, children: <Widget>[
              SizedBox(
                width: widget.colorPickerHeight,
                height: widget.colorPickerHeight,
                child: ColorPickerHueRing(
                  currentHsvColor,
                  onColorChanging,
                  displayThumbColor: widget.displayThumbColor,
                  strokeWidth: widget.hueRingStrokeWidth,
                ),
              ),
              ClipRRect(
                borderRadius: widget.pickerAreaBorderRadius,
                child: SizedBox(
                  width: widget.colorPickerHeight / 1.6,
                  height: widget.colorPickerHeight / 1.6,
                  child: ColorPickerArea(currentHsvColor, onColorChanging, PaletteType.hsv),
                ),
              )
            ]),
          ),
          if (widget.enableAlpha)
            SizedBox(
              height: 40.0,
              width: widget.colorPickerHeight,
              child: ColorPickerSlider(
                TrackType.alpha,
                currentHsvColor,
                onColorChanging,
                displayThumbColor: widget.displayThumbColor,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 5.0, 10.0, 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                //const SizedBox(width: 10),
                ColorIndicator(currentHsvColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: MyColorPickerInput(
                      currentHsvColor.toColor(),
                      (Color color) {
                        setState(() => currentHsvColor = HSVColor.fromColor(color));
                        widget.onColorChanged(currentHsvColor);
                      },
                      enableAlpha: widget.enableAlpha,
                      embeddedText: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: <Widget>[
          Expanded(
            child: SizedBox(
              width: 300.0,
              height: widget.colorPickerHeight,
              child: ClipRRect(
                borderRadius: widget.pickerAreaBorderRadius,
                child: ColorPickerArea(currentHsvColor, onColorChanging, PaletteType.hsv),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: widget.pickerAreaBorderRadius,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Stack(alignment: AlignmentDirectional.topCenter, children: <Widget>[
                SizedBox(
                  width: widget.colorPickerHeight - widget.hueRingStrokeWidth * 2,
                  height: widget.colorPickerHeight - widget.hueRingStrokeWidth * 2,
                  child: ColorPickerHueRing(currentHsvColor, onColorChanging,
                      strokeWidth: widget.hueRingStrokeWidth),
                ),
                Column(
                  children: [
                    SizedBox(height: widget.colorPickerHeight / 8.5),
                    ColorIndicator(currentHsvColor),
                    const SizedBox(height: 10),
                    ColorPickerInput(
                      currentHsvColor.toColor(),
                      (Color color) {
                        setState(() => currentHsvColor = HSVColor.fromColor(color));
                        widget.onColorChanged(currentHsvColor);
                      },
                      enableAlpha: widget.enableAlpha,
                      embeddedText: true,
                      disable: true,
                    ),
                    if (widget.enableAlpha) const SizedBox(height: 5),
                    if (widget.enableAlpha)
                      SizedBox(
                        height: 40.0,
                        width: (widget.colorPickerHeight - widget.hueRingStrokeWidth * 2) / 2,
                        child: ColorPickerSlider(
                          TrackType.alpha,
                          currentHsvColor,
                          onColorChanging,
                          displayThumbColor: true,
                        ),
                      ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      );
    }
  }
}

/// Provide hex input wiget for 3/6/8 digits.
class MyColorPickerInput extends StatefulWidget {
  const MyColorPickerInput(
    this.color,
    this.onColorChanged, {
    Key? key,
    this.enableAlpha = true,
    this.embeddedText = false,
    this.disable = false,
  }) : super(key: key);

  final Color color;
  final ValueChanged<Color> onColorChanged;
  final bool enableAlpha;
  final bool embeddedText;
  final bool disable;

  @override
  _MyColorPickerInputState createState() => _MyColorPickerInputState();
}

class _MyColorPickerInputState extends State<MyColorPickerInput> {
  TextEditingController textEditingController = TextEditingController();
  int inputColor = 0;

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (inputColor != widget.color.value) {
      textEditingController.text = '#' +
          widget.color.red.toRadixString(16).toUpperCase().padLeft(2, '0') +
          widget.color.green.toRadixString(16).toUpperCase().padLeft(2, '0') +
          widget.color.blue.toRadixString(16).toUpperCase().padLeft(2, '0') +
          (widget.enableAlpha
              ? widget.color.alpha.toRadixString(16).toUpperCase().padLeft(2, '0')
              : '');
    }
    return Padding(
      padding: const EdgeInsets.only(top: 0.0, left: 10, right: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (!widget.embeddedText) Text('Hex', style: Theme.of(context).textTheme.bodyText1),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(20),
                //color: Colors.amberAccent,
                borderRadius: BorderRadius.circular(12)),
            //width: (Theme.of(context).textTheme.bodyText2?.fontSize ?? 14) * 10,
            child: TextField(
              enabled: !widget.disable,
              controller: textEditingController,
              inputFormatters: [
                UpperCaseTextFormatter(),
                FilteringTextInputFormatter.allow(RegExp(kValidHexPattern)),
              ],
              decoration: InputDecoration(
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                isDense: true,
                fillColor: Colors.transparent,
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                label: widget.embeddedText ? const Text('Hex') : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
              ),
              onChanged: (String value) {
                String input = value;
                if (value.length == 9) {
                  input =
                      value.split('').getRange(7, 9).join() + value.split('').getRange(1, 7).join();
                }
                final Color? color = colorFromHex(input);
                if (color != null) {
                  widget.onColorChanged(color);
                  inputColor = color.value;
                }
              },
            ),
          ),
        ),
      ]),
    );
  }
}
