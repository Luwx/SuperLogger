import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggable_factory.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/loggable_type_description.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/features/audio/audio_loggable_controller.dart';
import 'package:super_logger/features/audio/audio_ui_helper.dart';
import 'package:super_logger/features/audio/models/audio_log.dart';
import 'package:super_logger/features/audio/models/image_properties.dart';

class AudioFactory extends BaseLoggableFactory<AudioLog> {
  static AudioUiHelper? _audioUiHelper;

  @override
  Loggable loggableFromMap(Map<String, dynamic> map) {
    return Loggable.fromJson(
      map,
      generalMapper: AudioProperties.fromJson,
      mainCardMapper: EmptyProperty.fromMap,
      aggregationMapper: EmptyAggregationConfig.fromMap,
    );
  }

  @override
  LoggableController<Object> createLoggableController(
      MainRepository repository, Loggable loggable) {
    return AudioLoggableController(loggable: loggable, repository: repository);
  }

  @override
  MappableObject createDefaultProperties() {
    return AudioProperties(o1: "o1");
  }

  @override
  MappableObject generalConfigFromMap(Map<String, dynamic> map) => AudioProperties.fromJson(map);

  @override
  ValueFromMap<AudioLog>? entryValueFromMap() {
    return AudioLog.fromJson;
  }

  @override
  ValueToMap? entryValueToMap() {
    return (entry) => (entry as AudioLog).toJson();
  }

  @override
  LoggableTypeDescription getLoggableTypeDescription() {
    return const LoggableTypeDescription(
        title: "Audio", description: "Audio", icon: Icons.audio_file);
  }

  @override
  LoggableUiHelper getUiHelper() {
    return _audioUiHelper ??= AudioUiHelper();
  }

  @override
  LoggableType get type => LoggableType.audio;
}
