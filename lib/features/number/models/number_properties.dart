import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/features/composite/interfaces/computable_loggable.dart';
import 'package:super_logger/features/composite/interfaces/side_by_side_eligible.dart';
import 'package:super_logger/utils/value_controller.dart';

import 'package:flutter/foundation.dart';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'number_properties.freezed.dart';
part 'number_properties.g.dart';

class NumberComputationInformation implements ComputableInformation {
  @override
  String get displayInformation => "";
}

@freezed
class NumberProperties
    with _$NumberProperties
    implements MappableObject, SideBySideEligible, ComputableLoggable {
  const NumberProperties._();
  static const maxSliderDiff = 100;

  const factory NumberProperties({
    int? max,
    int? min,
    required String prefix,
    required String suffix,
    required bool allowDecimal,
    required bool showMinusButton,
    required bool showSlider,
    // ignore: invalid_annotation_target
    @JsonKey(defaultValue: false) required bool showTotalCount,
  }) = _NumberProperties;

  factory NumberProperties.defaults() => const NumberProperties(
      prefix: "",
      suffix: "",
      allowDecimal: true,
      showMinusButton: false,
      showSlider: false,
      showTotalCount: false);

  factory NumberProperties.fromJson(Map<String, dynamic> json) => _$NumberPropertiesFromJson(json);

  bool isStringValueValid(String s) {
    if (s == "" || s == "-") {
      return false;
    }
    double val = double.parse(s);
    if (max != null && val > max! || min != null && val < min!) {
      return false;
    }
    if (!allowDecimal && val.toInt() != val) {
      return false;
    }
    return true;
  }

  @override
  bool get isSideBySideEligible => true;

  @override
  IList<ComputableInformation> get computablesInformation =>
      <ComputableInformation>[NumberComputationInformation()].lock;

  @override
  double getComputableValue(ComputableInformation info, MappableObject properties, Log log) {
    return log.value;
  }
}

class NumberPropertiesHelper {
  NumberPropertiesHelper._();
  static Either<ValueErr<NumberProperties>, NumberProperties> propertiesValidator(
      NumberProperties properties) {
    int? max = properties.max;
    int? min = properties.min;

    String? errorMessage;

    if (max != null && min != null) {
      if (max == min) {
        errorMessage = "Max and min cannot be the same";
      } else if (max < min) {
        errorMessage = "Invalid max and min values";
      } else if (max - min > NumberProperties.maxSliderDiff && properties.showSlider) {
        errorMessage = "Invalid show slider with max and min values";
      }
    }

    if (errorMessage != null) {
      return Left(ValueErr(errorMessage, properties));
    } else {
      return Right(properties);
    }
  }

  static double getValidValue(NumberProperties properties) {
    int? max = properties.max;
    int? min = properties.min;
    if (min != null) {
      return min.toDouble();
    } else if (max != null) {
      return max.toDouble();
    } else {
      return 0;
    }
  }

  static Either<ValueErr<double?>, double> isValueValid(
      double? value, NumberProperties properties) {
    if (value == null) return Left(ValueErr("Invalid value: No value selected", value));
    int? max = properties.max;
    int? min = properties.min;
    if (max != null) {
      if (min != null) {
        if (value >= min.toDouble() && value <= max) {
          return Right(value);
        } else {
          return Left(ValueErr("Value must be between $min and $max", value));
        }
      } else {
        if (value <= max) {
          return Right(value);
        } else {
          return Left(ValueErr("Value must be less than ${max + 1}", value));
        }
      }
    } else if (min != null) {
      if (value >= min) {
        return Right(value);
      } else {
        return Left(ValueErr("Value must be greater than ${min - 1}", value));
      }
    } else {
      return Right(value);
    }
  }

  // if current settings allow the use of slider
  static bool isValidForSlider(NumberProperties properties) {
    return (properties.max != null &&
        properties.min != null /*&& !allowDecimal*/ &&
        (properties.max! - properties.min!).abs() <= NumberProperties.maxSliderDiff);
  }

  static bool shouldUseSlider(NumberProperties properties) {
    return properties.showSlider && isValidForSlider(properties);
  }
}
