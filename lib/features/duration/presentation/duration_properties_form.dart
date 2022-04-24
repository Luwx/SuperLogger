import 'package:flutter/material.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/core/presentation/theme/dimensions.dart';
import 'package:super_logger/features/duration/models/duration_properties.dart';
import 'package:super_logger/features/duration/presentation/duration_input_widgets.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';

class DurationPropertiesForm extends StatefulWidget {
  const DurationPropertiesForm({Key? key, this.properties, required this.propertiesController})
      : super(key: key);
  final DurationProperties? properties;
  final ValueEitherValidOrErrController<MappableObject> propertiesController;

  @override
  _DurationPropertiesFormState createState() => _DurationPropertiesFormState();
}

class _DurationPropertiesFormState extends State<DurationPropertiesForm> {
  // int? _minDuration;
  // int? _maxDuration;

  // bool _canBePaused = false;
  // bool _showTotalDurationOfDay = true;
  // bool _usePlayStopButton = true;

  DurationProperties get _currentProperties {
    return widget.propertiesController.valueNoValidation as DurationProperties;
  }

  void _setProperties(DurationProperties properties) {
    widget.propertiesController.setRightValue(properties);
  }

  void _propertiesListener() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // // _minDuration = widget.properties?.minDuration;
    // // _maxDuration = widget.properties?.maxDuration;

    // if (widget.properties != null) {
    //   _canBePaused = widget.properties!.canBePaused;
    //   _showTotalDurationOfDay = widget.properties!.showTotalDurationOfDay;
    //   _usePlayStopButton = widget.properties!.usePlayStopButton;
    // }

    widget.propertiesController.setRightValue(widget.properties ?? DurationProperties.defaults());
    widget.propertiesController.addListener(_propertiesListener);
  }

  @override
  void dispose() {
    widget.propertiesController.removeListener(_propertiesListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: AppDimens.defaultSpacing),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.defaultSpacing),
          child: Row(
            children: <Widget>[
              Expanded(
                child: StaticDurationInput(
                  onChange: () {},
                  initialDuration: _currentProperties.minDuration,
                ),
              ),
              const SizedBox(width: AppDimens.defaultSpacing / 2),
              Expanded(
                child: StaticDurationInput(
                  onChange: () {},
                  initialDuration: _currentProperties.minDuration,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.defaultSpacing),
        CheckboxListTile(
          title: Text(context.l10n.showTotalDurationOfDay),
          controlAffinity: ListTileControlAffinity.leading,
          value: _currentProperties.showTotalDurationOfDay,
          onChanged: (value) {
            if (value != null) {
              _setProperties(_currentProperties.copyWith(showTotalDurationOfDay: value));
            }
          },
        ),
        CheckboxListTile(
          title: Text(context.l10n.canBePaused),
          controlAffinity: ListTileControlAffinity.leading,
          value: _currentProperties.canBePaused,
          onChanged: (value) {
            if (value != null) {
              _setProperties(_currentProperties.copyWith(canBePaused: value));
            }
          },
        ),
        CheckboxListTile(
          title: Text(context.l10n.usePlayStopButton),
          controlAffinity: ListTileControlAffinity.leading,
          value: _currentProperties.usePlayStopButton,
          onChanged: (value) {
            if (value != null) {
              _setProperties(_currentProperties.copyWith(usePlayStopButton: value));
            }
          },
        ),
      ],
    );
  }
}
