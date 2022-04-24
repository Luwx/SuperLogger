import 'package:flutter/material.dart';
import 'package:super_logger/features/text/models/text_properties.dart';
import 'package:super_logger/features/text/presentation/text_edit_widget.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';

class AddTextLogDialog extends StatefulWidget {
  const AddTextLogDialog({Key? key, required this.properties}) : super(key: key);
  final TextProperties properties;

  @override
  _AddTextLogDialogState createState() => _AddTextLogDialogState();
}

class _AddTextLogDialogState extends State<AddTextLogDialog> {
  bool _isValid = false;

  late final ValueEitherController<String> _valueController;

  void _valueControllerListener() {
    _valueController.value.fold((l) {
      if (_isValid) {
        setState(() {
          _isValid = false;
        });
      }
    }, (r) {
      if (_isValid == false) {
        setState(() {
          _isValid = true;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _valueController = ValueEitherController();
    _valueController.addListener(_valueControllerListener);
  }

  @override
  void dispose() {
    _valueController.removeListener(_valueControllerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.addText),
      actions: <Widget>[
        Row(
          children: <Widget>[
            const SizedBox(width: 12.0),
            IconButton(
              color: Theme.of(context).colorScheme.primary,
              icon: const Icon(Icons.open_in_full_rounded),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                alignment: AlignmentDirectional.centerEnd,
                //constraints: const BoxConstraints(minHeight: 52.0),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: OverflowBar(
                  spacing: 8,
                  overflowAlignment: OverflowBarAlignment.end,
                  children: <Widget>[
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(context.l10n.cancel)),
                    TextButton(
                      onPressed: !_isValid
                          ? null
                          : () {
                              Navigator.pop(
                                  context, _valueController.value.fold((l) => null, (r) => r));
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
      content: TextEditWidget(
        properties: widget.properties,
        valueController: _valueController,
      ),
    );
  }
}
