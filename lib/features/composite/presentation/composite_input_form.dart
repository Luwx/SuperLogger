import 'package:flutter/material.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/presentation/theme/dimensions.dart';
import 'package:super_logger/features/composite/models/composite_log.dart';
import 'package:super_logger/features/composite/models/composite_properties.dart';
import 'package:super_logger/features/composite/presentation/composite_log_input.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';

class CompositeInputForm extends StatefulWidget {
  const CompositeInputForm({Key? key, required this.compositeProperties, required this.title})
      : super(key: key);
  final CompositeProperties compositeProperties;
  final String title;

  @override
  _CompositeInputFormState createState() => _CompositeInputFormState();
}

class _CompositeInputFormState extends State<CompositeInputForm> {

  final ValueNotifier<bool> _isValid = ValueNotifier(false);
  final controller = ValueEitherController<CompositeLog>();

  void _loggableControllerListener() {
    controller.value.fold((l) {
      if (_isValid.value) _isValid.value = false;
    }, (r) {
      if (!_isValid.value) _isValid.value = true;
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(context.l10n.newEntryOf(widget.title)),
        //backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 16,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: SizedBox(
                width: double.maxFinite,
                child: CompositeLogInput(
                  compositeProperties: widget.compositeProperties,
                  controller: controller,
                  forInputForm: true,
                ),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isValid,
              builder: (context, isValid, child) {
                return Padding(
                  padding: const EdgeInsets.all(AppDimens.defaultSpacing),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextButton(
                        //style: TextButton.styleFrom(visualDensity: VisualDensity.),
                        onPressed: !isValid
                            ? null
                            : () {
                                controller.value.fold(
                                  (l) => _isValid.value = false,
                                  (r) async {
                                    final uiHelper =
                                        locator.get<MainFactory>().getUiHelper(LoggableType.composite);
                                    await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          actions: [
                                            TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: Text(context.l10n.ok))
                                          ],
                                          content: uiHelper.getDisplayLogValueWidget(r,
                                              properties: widget.compositeProperties),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                        child: const Center(child: Text("Preview")),
                      ),
                      const SizedBox(
                        height: 11,
                      ),
                      ElevatedButton(
                        //style: TextButton.styleFrom(visualDensity: VisualDensity.),
                        onPressed: !isValid
                            ? null
                            : () {
                                controller.value.fold(
                                  (l) => _isValid.value = false,
                                  (r) => Navigator.pop(context, r),
                                );
                              },
                        child: const SizedBox(
                          width: double.infinity,
                          child: Center(
                              child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text("Save"),
                          )),
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }
}
