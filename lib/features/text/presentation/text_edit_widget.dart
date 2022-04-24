import 'package:flutter/material.dart';
import 'package:super_logger/features/text/models/text_properties.dart';
import 'package:super_logger/utils/value_controller.dart';

class TextEditWidget extends StatefulWidget {
  const TextEditWidget({Key? key, required this.valueController, required this.properties}) : super(key: key);
  final ValueEitherController<String> valueController;
  final TextProperties properties;
  @override
  _TextEditWidgetState createState() => _TextEditWidgetState();
}

class _TextEditWidgetState extends State<TextEditWidget> {
  String? _errorText;
  bool _wasTouched = false;

  late final TextEditingController _textController;

  void _textControllerListener() {
    if (!_wasTouched && _textController.text.isEmpty) {
      widget.valueController.setErrorValue("No text");
      return;
    }

    if (!_wasTouched) {
      setState(() {
        _wasTouched = true;
      });
    }

    if (_textController.text.isEmpty) {
      if (_errorText == null) {
        setState(() {
          _errorText = "Cannot be empty";
          widget.valueController.setErrorValue("No text");
        });
      }
    } else {
      widget.valueController.setRightValue(_textController.text);
      if (_errorText != null) {
        setState(() {
          _errorText = null;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.valueController.isSetUp) {
      _textController =
          TextEditingController(text: widget.valueController.value.fold((l) => "", (r) => r));
    } else {
      _textController = TextEditingController();
      widget.valueController.setErrorValue("No text");
    }

    _textController.addListener(_textControllerListener);
  }

  @override
  void dispose() {
    _textController.removeListener(_textControllerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _textController,
      decoration: InputDecoration(
        errorText: _errorText,
      ),
      minLines: 2,
      maxLines: null,
      maxLength: widget.properties.maximumLength,
    );
  }
}
