import 'package:flutter/material.dart';
import 'package:super_logger/features/composite/models/composite_log.dart';
import 'package:super_logger/features/composite/models/composite_properties.dart';
import 'package:super_logger/features/composite/presentation/composite_log_input.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';

class CompositeDialog extends StatefulWidget {
  final CompositeProperties compositeProperties;
  final String title;
  const CompositeDialog({Key? key, required this.compositeProperties, required this.title})
      : super(key: key);

  @override
  _CompositeDialogState createState() => _CompositeDialogState();
}

class _CompositeDialogState extends State<CompositeDialog> {
  bool _isValid = false;

  final controller = ValueEitherController<CompositeLog>();

  void _loggableControllerListener() {
    controller.value.fold((l) {
      if (_isValid) setState(() => _isValid = false);
    }, (r) {
      if (!_isValid) setState(() => _isValid = true);
    });
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(_loggableControllerListener);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      //shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      actions: <Widget>[
        TextButton(
          child: Text(context.l10n.cancel),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text(context.l10n.ok),
          onPressed: !_isValid
              ? null
              : () {
                  controller.value.fold(
                      (l) => setState(() => _isValid = false), (r) => Navigator.pop(context, r));
                },
        ),
      ],
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: CompositeLogInput(
            compositeProperties: widget.compositeProperties,
            controller: controller,
          ),
        ),
      ),
    );
  }
}
