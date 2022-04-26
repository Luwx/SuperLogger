import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/models/loggable_settings.dart';
import 'package:super_logger/core/models/loggable_tag.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/utils/extensions.dart';

part 'loggable.freezed.dart';

typedef MappableMapper = MappableObject Function(Map<String, dynamic>);

@freezed
class Loggable with _$Loggable {
  const Loggable._();

  const factory Loggable({
    required LoggableSettings loggableSettings,
    required LoggableProperties loggableConfig,
    required LoggableType type,
    required String title,
    required DateTime creationDate,
    required IList<LoggableTag> tags,
    required String id,
  }) = _Loggable;

  Map<String, dynamic> toJson() {
    return {
      'loggableSettings': loggableSettings.toJson(),
      'loggableConfig': loggableConfig.toJson(),
      'type': type.toString(),
      'title': title,
      'creationDate': creationDate.millisecondsSinceEpoch,
      'tags': tags.map((tag) => tag.toJson()).toList(),
      'id': id,
    };
  }

  factory Loggable.fromJson(
    Map<String, dynamic> json, {
    required MappableMapper generalMapper,
    required MappableMapper mainCardMapper,
    required MappableMapper aggregationMapper,
  }) {
    return Loggable(
      loggableSettings: LoggableSettings.fromJson(json['loggableSettings']),
      loggableConfig: LoggableProperties.fromJson(json['loggableConfig'],
          generalMapper: generalMapper,
          mainCardMapper: mainCardMapper,
          aggregationMapper: aggregationMapper),
      type: LoggableTypeHelper.fromString(json['type']),
      title: json['title'],
      creationDate: json['creationDate'] == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(json['creationDate']),
      tags: List<dynamic>.from(json['tags'] ?? [].lock)
          .map((tagMap) => LoggableTag.fromJson(tagMap))
          .toList()
          .lock,
      id: json['id'],
    );
  }

  MappableObject get loggableProperties => loggableConfig.generalConfig;
}

class LoggableProperties {
  // generally, holds information about input and displays settings
  final MappableObject generalConfig;

  //
  final MappableObject mainCardConfig;

  //
  final MappableObject aggregationConfig;

  LoggableProperties({
    required this.generalConfig,
    required this.mainCardConfig,
    required this.aggregationConfig,
  });

  Map<String, dynamic> toJson() {
    return {
      'generalConfig': generalConfig.toJson(),
      'mainCardConfig': mainCardConfig.toJson(),
      'aggregationConfig': aggregationConfig.toJson(),
    };
  }

  factory LoggableProperties.fromJson(Map<String, dynamic> json,
      {required MappableMapper generalMapper,
      required MappableMapper mainCardMapper,
      required MappableMapper aggregationMapper}) {
    return LoggableProperties(
      generalConfig: generalMapper(json['generalConfig']),
      mainCardConfig: mainCardMapper(json['mainCardConfig']),
      aggregationConfig: aggregationMapper(json['aggregationConfig']),
    );
  }

  LoggableProperties copyWith({
    MappableObject? generalConfig,
    MappableObject? mainCardConfig,
    MappableObject? aggregationConfig,
  }) {
    return LoggableProperties(
      generalConfig: generalConfig ?? this.generalConfig,
      mainCardConfig: mainCardConfig ?? this.mainCardConfig,
      aggregationConfig: aggregationConfig ?? this.aggregationConfig,
    );
  }

  @override
  String toString() =>
      'LoggableProperties(generalConfig: $generalConfig, mainCardConfig: $mainCardConfig, aggregationConfig: $aggregationConfig)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LoggableProperties &&
        other.generalConfig == generalConfig &&
        other.mainCardConfig == mainCardConfig &&
        other.aggregationConfig == aggregationConfig;
  }

  @override
  int get hashCode => generalConfig.hashCode ^ mainCardConfig.hashCode ^ aggregationConfig.hashCode;
}

extension IsNew on Loggable {
  bool get isNew => DateTime.now().difference(creationDate) < const Duration(minutes: 2);
}
