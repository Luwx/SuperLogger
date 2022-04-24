import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:super_logger/core/loggable_factory.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/features/composite/interfaces/computable_loggable.dart';
import 'package:super_logger/features/composite/interfaces/side_by_side_eligible.dart';
import 'package:super_logger/locator.dart';

part 'choice_properties.freezed.dart';
part 'choice_properties.g.dart';

class MetadataComputableInformation implements ComputableInformation {
  final String metadataName;
  MetadataComputableInformation(this.metadataName);
  @override
  String get displayInformation => metadataName + " (M)";
}

@freezed
class ChoiceProperties
    with _$ChoiceProperties
    implements MappableObject, SideBySideEligible, ComputableLoggable {
  const ChoiceProperties._();
  const factory ChoiceProperties({
    required bool isRanked,
    required LoggableType optionType,
    required bool useSlider,
    required IList<ChoiceOption> options,
    required IList<ChoiceOptionMetadataPropertyTemplate> metadataTemplate,
  }) = _ChoiceProperties;

  @override
  Map<String, dynamic> toJson() {
    var mapper = locator.get<MainFactory>().entryValueToMap(optionType);
    return {
      'optionType': optionType.name,
      'isRanked': isRanked,
      'useSlider': useSlider,
      'options': options.map((option) => option.toJson(mapper)).toList(),
      'template': metadataTemplate.map((template) => template.toJson()).toList(),
    };
  }

  factory ChoiceProperties.fromJson(Map<String, dynamic> map) {
    List<Map<String, dynamic>> optionsMap = List<Map<String, dynamic>>.from(map['options']);
    List<ChoiceOption> options = [];

    final optionType =
        LoggableType.values.firstWhere((element) => element.name == map['optionType']);
    final mapper = locator.get<MainFactory>().entryValueFromMap(optionType);
    for (final choiceMap in optionsMap) {
      options.add(ChoiceOption.fromJson(choiceMap, mapper));
    }

    return ChoiceProperties(
      optionType: optionType,
      isRanked: map['isRanked'],
      useSlider: map['useSlider'],
      options: options.lock,
      metadataTemplate: (map['template'] as List)
          .map((templateMap) => ChoiceOptionMetadataPropertyTemplate.fromJson(templateMap))
          .toIList(),
    );
  }

  static const List<LoggableType> supportedTypes = [
    //LoggableType.number,
    LoggableType.color,
    LoggableType.duration,
    LoggableType.text,
    //LoggableType.composite,
    LoggableType.internetImage
  ];

  bool get canUseSlider {
    if (!isRanked) return false;
    if (options.length > 12) return false;
    return true;
  }

  bool get shouldUseSlider => useSlider && canUseSlider;

  @override
  bool get isSideBySideEligible =>
      (optionType == LoggableType.color ||
          optionType == LoggableType.text ||
          optionType == LoggableType.duration) &&
      !useSlider;

  @override
  IList<ComputableInformation> get computablesInformation {
    List<MetadataComputableInformation> metadataNameList = [];
    for (final metadata in metadataTemplate) {
      metadataNameList.add(MetadataComputableInformation(metadata.propertyName));
    }
    return metadataNameList.lock;
  }

  @override
  double? getComputableValue(ComputableInformation info, MappableObject properties, Log log) {
    return (properties as ChoiceProperties)
        .options
        .firstWhereOrNull((option) => option.id == log.value)
        ?.metadata
        .firstWhereOrNull((metadata) =>
            metadata.propertyName == (info as MetadataComputableInformation).metadataName)
        ?.value;
  }
}

@freezed
class ChoiceOptionMetadataPropertyTemplate with _$ChoiceOptionMetadataPropertyTemplate {
  const factory ChoiceOptionMetadataPropertyTemplate({
    required String propertyName,
    required bool isRequired,
    required String prefix,
    required String suffix,
  }) = _ChoiceOptionMetadataPropertyTemplate;

  factory ChoiceOptionMetadataPropertyTemplate.fromJson(Map<String, dynamic> json) =>
      _$ChoiceOptionMetadataPropertyTemplateFromJson(json);
}

@freezed
class ChoiceOptionMetadataProperty with _$ChoiceOptionMetadataProperty {
  const factory ChoiceOptionMetadataProperty(
      {required String propertyName, required double value}) = _ChoiceOptionMetadataProperty;

  factory ChoiceOptionMetadataProperty.fromJson(Map<String, dynamic> json) =>
      _$ChoiceOptionMetadataPropertyFromJson(json);
}

@freezed
class ChoiceOption with _$ChoiceOption {
  const ChoiceOption._();
  const factory ChoiceOption({
    required IList<ChoiceOptionMetadataProperty> metadata,
    required String id,
    required dynamic value,
  }) = _ChoiceOption;

  Map<String, dynamic> toJson(ValueToMap? valueToMap) {
    return {
      'id': id,
      'value': valueToMap?.call(value) ?? value,
      'metadata': metadata.map((element) => element.toJson()).toList(),
    };
  }

  factory ChoiceOption.fromJson(Map<String, dynamic> json, ValueFromMap? valueFromMap) {
    List<Map<String, dynamic>> mapList = List<Map<String, dynamic>>.from(json['metadata']);
    List<ChoiceOptionMetadataProperty> generatedList = [];

    for (final propertyMap in mapList) {
      generatedList.add(ChoiceOptionMetadataProperty.fromJson(propertyMap));
    }

    return ChoiceOption(
      metadata: generatedList.lock,
      id: json['id'],
      value: valueFromMap?.call(json['value']) ?? json['value'],
    );
  }
}
