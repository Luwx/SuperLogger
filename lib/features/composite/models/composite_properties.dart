import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/features/composite/interfaces/computable_loggable.dart';
import 'package:super_logger/features/composite/interfaces/side_by_side_eligible.dart';
import 'package:super_logger/features/composite/models/base_loggable_for_composite.dart';
import 'package:super_logger/features/composite/models/composite_log.dart';
import 'package:super_logger/features/composite/models/computations.dart';

part 'composite_properties.freezed.dart';

class CompositeCalcComputableInformation implements ComputableInformation {
  final String calcName;

  CompositeCalcComputableInformation(this.calcName);

  @override
  String get displayInformation => calcName + " (C)";
}

@freezed
class CompositeProperties with _$CompositeProperties implements MappableObject, ComputableLoggable {
  /// 0 = first level
  const CompositeProperties._();
  const factory CompositeProperties({
    required IList<LoggableForComposite> loggables,
    required IList<NumericCalculation> calculations,
    required bool displaySideBySide,
    required bool isOrGroup,
    required String sideBySideDelimiter,
    required int level,
  }) = _CompositeProperties;

  factory CompositeProperties.defaults() => CompositeProperties(
        loggables: <LoggableForComposite>[].lock,
        calculations: <NumericCalculation>[].lock,
        displaySideBySide: false,
        isOrGroup: false,
        sideBySideDelimiter: "",
        level: 0,
      );

  @override
  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> loggablesList = [];
    for (final loggable in loggables) {
      loggablesList.add(loggable.toJson());
    }

    List<Map<String, dynamic>> calculationList = [];
    for (final calculation in calculations) {
      calculationList.add(calculation.toJson());
    }

    return {
      'loggables': loggablesList,
      'calculations': calculationList,
      'displaySideBySide': displaySideBySide,
      'isOrGroup': isOrGroup,
      'sideBySideDelimiter': sideBySideDelimiter,
      'level': level,
    };
  }

  static CompositeProperties fromMap(Map<String, dynamic> map) {
    List<LoggableForComposite> loggablesList = [];
    final List loggableMapList = map['loggables'];
    for (final loggableMap in loggableMapList) {
      loggablesList.add(LoggableForComposite.fromJson(loggableMap));
    }

    List<NumericCalculation> computationsList = [];
    final List? computationMapList = map['calculations'];
    if (computationMapList != null) {
      for (final computationMap in computationMapList) {
        computationsList.add(NumericCalculation.fromJson(computationMap));
      }
    }

    return CompositeProperties(
      loggables: loggablesList.lock,
      calculations: computationsList.lock,
      displaySideBySide: map['displaySideBySide'],
      isOrGroup: map['isOrGroup'],
      sideBySideDelimiter: map['sideBySideDelimiter'],
      level: map['level'],
    );
  }

  static const List<LoggableType> supportedTypes = [
    LoggableType.number,
    LoggableType.choice,
    LoggableType.color,
    LoggableType.duration,
    LoggableType.text,
    LoggableType.composite,
    LoggableType.image,
    LoggableType.internetImage
  ];

  // composite(0) -> composite(1) -> composite(2)
  static const int maximumLevel = 2;

  bool get canShowSubCatsSideBySide {
    //if (!displaySideBySide) return false;
    if (loggables.length != 2) return false;
    if (isOrGroup) return false;

    for (final catForComposite in loggables) {
      if (catForComposite.isArrayable || catForComposite.isDismissible) return false;
      final loggableProperties = catForComposite.properties;
      if (loggableProperties is! SideBySideEligible) return false;
      if ((loggableProperties as SideBySideEligible).isSideBySideEligible == false) {
        return false;
      }
    }

    return true;
  }

  @override
  IList<ComputableInformation> get computablesInformation {
    return calculations.map((calc) => CompositeCalcComputableInformation(calc.name)).toIList();
  }

  @override
  double? getComputableValue(ComputableInformation info, MappableObject properties, Log log) {
    final calcName = (info as CompositeCalcComputableInformation).calcName;

    final calc = (properties as CompositeProperties)
        .calculations
        .firstWhereOrNull((calculation) => calculation.name == calcName);

    return calc?.performComputation(log as CompositeLog, properties);
  }
}
