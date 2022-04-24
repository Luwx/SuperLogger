import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/features/choice/models/choice_properties.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';
import 'package:collection/collection.dart';

class ChoiceDropdownButton extends StatefulWidget {
  const ChoiceDropdownButton(
      {Key? key,
      required this.controller,
      required this.properties,
      required this.title,
      this.inlineTitle = false})
      : super(key: key);
  final ValueEitherController<String> controller;
  final ChoiceProperties properties;
  final String title;
  final bool inlineTitle;

  @override
  _ChoiceDropdownButtonState createState() => _ChoiceDropdownButtonState();
}

class _ChoiceDropdownButtonState extends State<ChoiceDropdownButton> {
  late List<String> _options;
  String _invalidOption = "";

  String? _original;

  late LoggableUiHelper _uiHelper;

  @override
  void initState() {
    super.initState();
    _options = [...widget.properties.options.map((element) => element.id)];

    if (widget.controller.isSetUp) {
      _original = widget.controller.value.fold((l) => null, (r) => r);
      if (_original != null && !_options.contains(_original)) {
        _invalidOption = _original!;
        _options.add(_invalidOption);
      }
    } else {
      widget.controller.setErrorValue("No choice selected", notify: false);
    }

    _uiHelper = locator.get<MainFactory>().getUiHelper(widget.properties.optionType);
  }

  @override
  Widget build(BuildContext context) {
    return widget.inlineTitle
        ? Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (widget.title.isNotEmpty)
                Text(widget.title + ": ",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground.withAlpha(180),
                      fontSize: 16,
                      //fontWeight: FontWeight.w400,
                    )),
              if (widget.title.isNotEmpty)
                const SizedBox(
                  width: 12,
                ),
              Expanded(child: buildDropdownButton(context))
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (widget.title.isNotEmpty)
                Text(widget.title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground.withAlpha(180),
                      fontSize: 16,
                      //fontWeight: FontWeight.w400,
                    )),
              if (widget.title.isNotEmpty)
                const SizedBox(
                  height: 12,
                ),
              buildDropdownButton(context)
            ],
          );
  }

  Widget buildDropdownButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha(16),
        borderRadius: const BorderRadius.all(
          Radius.circular(12),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.controller.value.fold((l) => null, (r) => r),
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
          onChanged: (String? newValue) {
            setState(() {
              if (newValue == null) {
                widget.controller.setErrorValue("empty value");
              } else {
                widget.controller.setRightValue(newValue);
              }
            });
          },
          items: _options.map<DropdownMenuItem<String>>((String id) {
            final logValue =
                widget.properties.options.firstWhereOrNull((option) => option.id == id)?.value;
            return DropdownMenuItem<String>(
              value: id,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: logValue == null
                    ? Text(
                        "Option data not found",
                        style: TextStyle(
                          color: Colors.red[400],
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : _uiHelper.getDisplayLogValueWidget(logValue),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

Future<String?> showChoiceSliderDialog(BuildContext context, ChoiceProperties properties) {
  ValueEitherController<String> controller = ValueEitherController<String>();

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.newEntry),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 4,
          ),
          ChoiceSlider(
            controller: controller,
            properties: properties,
            title: "",
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(context.l10n.cancel),
        ),
        TextButton(
          onPressed: () {
            controller.value.fold(
              (error) {},
              (value) {
                Navigator.pop(context, value);
              },
            );
          },
          child: Text(context.l10n.ok),
        ),
      ],
    ),
  );
}

class ChoiceSlider extends StatefulWidget {
  ChoiceSlider({Key? key, required this.controller, required this.properties, required this.title})
      : assert(properties.useSlider && properties.canUseSlider),
        super(key: key);
  final ValueEitherController<String> controller;
  final ChoiceProperties properties;
  final String title;

  @override
  _ChoiceSliderState createState() => _ChoiceSliderState();
}

class _ChoiceSliderState extends State<ChoiceSlider> {
  //late String _currentOptionId;
  late int _currentOptionIndex;
  late int _previousOptionIndex;

  late LoggableUiHelper _uiHelper;

  @override
  void initState() {
    super.initState();
    _uiHelper = locator.get<MainFactory>().getUiHelper(widget.properties.optionType);

    if (widget.controller.isSetUp) {
      _currentOptionIndex = widget.controller.value.fold(
        (l) => 0,
        (r) {
          for (int i = 0; i < widget.properties.options.length; i++) {
            if (widget.properties.options[i].id == r) {
              return i;
            }
          }
          // TODO: deleted or unrecognized option?
          return -1;
        },
      );
      _previousOptionIndex = _currentOptionIndex;
    } else {
      _currentOptionIndex = 0;
      _previousOptionIndex = 0;
      widget.controller.setRightValue(widget.properties.options[0].id, notify: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(
          height: 4,
        ),
        if (_currentOptionIndex == -1)
          Text(
            "Invalid option",
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          )
        else
          PageTransitionSwitcher(
            duration: kThemeAnimationDuration,
            reverse: _previousOptionIndex > _currentOptionIndex,
            child: SizedBox(
              key: ValueKey(_currentOptionIndex),
              child: _uiHelper.getDisplayLogValueWidget(
                  widget.properties.options[_currentOptionIndex].value,
                  size: LogDisplayWidgetSize.large),
            ),
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
        const SizedBox(
          height: 16,
        ),
        Slider(
          divisions: widget.properties.options.length - 1,
          min: 0,
          max: widget.properties.options.length - 1,
          value: _currentOptionIndex.toDouble(),
          onChanged: (val) {
            if (val != _currentOptionIndex) {
              setState(() {
                _previousOptionIndex = _currentOptionIndex;
                _currentOptionIndex = val.toInt();
                widget.controller.setRightValue(widget.properties.options[_currentOptionIndex].id);
              });
            }
          },
        ),
      ],
    );
  }
}
