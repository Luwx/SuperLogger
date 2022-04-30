import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/core/presentation/theme/dimensions.dart';

import 'package:super_logger/features/number/models/number_properties.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';

class EditValuePropertiesForm extends HookWidget {
  final NumberProperties? valueProperties;
  final ValueEitherValidOrErrController<MappableObject> propertiesController;

  const EditValuePropertiesForm(
      {Key? key, this.valueProperties, required this.propertiesController})
      : super(key: key);

  NumberProperties get _currentProperties {
    return propertiesController.valueNoValidation as NumberProperties;
  }

  void _setProperties(NumberProperties properties) {
    propertiesController.setValue(NumberPropertiesHelper.propertiesValidator(properties));
  }

  @override
  Widget build(BuildContext context) {
    useEffect(
      () {
        if (propertiesController.isSetUp == false) {
          propertiesController.setValue(
            NumberPropertiesHelper.propertiesValidator(
              valueProperties ?? NumberProperties.defaults(),
            ),
          );
        }
        return null;
      },
      [propertiesController],
    );

    useListenable(propertiesController);

    final formState = NumberFormMinMaxState.fromProperties(_currentProperties, context);

    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          const SizedBox(height: AppDimens.defaultSpacing),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.defaultSpacing),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    initialValue: _currentProperties.prefix,
                    decoration: InputDecoration(labelText: context.l10n.prefix),
                    onChanged: (value) {
                      _setProperties(_currentProperties.copyWith(prefix: value));
                    },
                  ),
                ),
                const SizedBox(width: AppDimens.defaultSpacing / 2),
                Expanded(
                  child: TextFormField(
                    initialValue: _currentProperties.suffix,
                    decoration: InputDecoration(labelText: context.l10n.suffix),
                    onChanged: (value) {
                      _setProperties(_currentProperties.copyWith(suffix: value));
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.defaultSpacing),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    initialValue: _currentProperties.min?.toString(),
                    decoration: InputDecoration(
                      //errorStyle: TextStyle(height: 0),
                      labelText: context.l10n.minValue,
                      errorText: formState.minError,
                      errorMaxLines: 2,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: false, signed: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'^-?\d{0,9}')),
                    ],
                    onChanged: (String s) {
                      if (s != "-" && s != "") {
                        _setProperties(_currentProperties.copyWith(min: int.parse(s)));
                      }
                      if (s == "" || s == "-") {
                        _setProperties(_currentProperties.copyWith(min: null));
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppDimens.defaultSpacing / 2),
                Expanded(
                  child: TextFormField(
                    initialValue: _currentProperties.max?.toString(),
                    decoration: InputDecoration(
                        //errorStyle: TextStyle(height: 0),
                        labelText: context.l10n.maxValue,
                        errorText: formState.maxError,
                        errorMaxLines: 2),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: false, signed: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'^-?\d{0,9}')),
                    ],
                    onChanged: (String s) {
                      if (s != "-" && s != "") {
                        _setProperties(_currentProperties.copyWith(max: int.parse(s)));
                      }
                      if (s == "" || s == "-") {
                        _setProperties(_currentProperties.copyWith(max: null));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.defaultSpacing / 2),
          CheckboxListTile(
            title: Text(context.l10n.useSliderControlLabel),
            //secondary: Icon(Icons.beach_access),
            subtitle: Text(context.l10n.useSliderControlDescription),
            controlAffinity: ListTileControlAffinity.leading,
            value: _currentProperties.showSlider,
            onChanged: !formState.enableShowSliderTile
                ? null
                : (bool? value) {
                    if (value == null) return;
                    _setProperties(_currentProperties.copyWith(showSlider: value));
                  },
          ),
          CheckboxListTile(
            title: Text(context.l10n.allowFractionalValues),
            //secondary: Icon(Icons.beach_access),
            controlAffinity: ListTileControlAffinity.leading,
            value: _currentProperties.allowDecimal,
            onChanged: (bool? value) {
              if (value == null) return;
              _setProperties(_currentProperties.copyWith(allowDecimal: value));
            },
          ),
          CheckboxListTile(
            title: Text(context.l10n.showTotalCount),
            subtitle: Text(context.l10n.showTotalCountDescription),
            controlAffinity: ListTileControlAffinity.leading,
            value: _currentProperties.showTotalCount,
            onChanged: (bool? value) {
              if (value == null) return;
              _setProperties(_currentProperties.copyWith(showTotalCount: value));
            },
          ),
        ],
      ),
    );
  }
}

class NumberFormMinMaxState {
  final bool enableShowSliderTile;
  final String? minError;
  final String? maxError;

  NumberFormMinMaxState(
      {required this.enableShowSliderTile, required this.minError, required this.maxError});

  factory NumberFormMinMaxState.fromProperties(NumberProperties properties, BuildContext context) {
    return NumberFormMinMaxState(
        enableShowSliderTile: NumberPropertiesHelper.isValidForSlider(properties),
        maxError: _limitErrorText(properties, isMin: false, context: context),
        minError: _limitErrorText(properties, isMin: true, context: context));
  }

  static String? _limitErrorText(NumberProperties properties,
      {required bool isMin, required BuildContext context}) {
    int? max = properties.max;
    int? min = properties.min;

    if (max != null && min != null) {
      if (max == min) {
        return context.l10n.valuesCannotBeEqual;
      } else if (max < min) {
        return isMin ? context.l10n.minGreaterThanMax : context.l10n.maxSmallerThanMin;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NumberFormMinMaxState &&
        other.enableShowSliderTile == enableShowSliderTile &&
        other.maxError == maxError &&
        other.minError == minError;
  }

  @override
  int get hashCode => enableShowSliderTile.hashCode ^ maxError.hashCode ^ minError.hashCode;
}
