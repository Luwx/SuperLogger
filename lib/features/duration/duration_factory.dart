import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggable_factory.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/loggable_type_description.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/features/duration/duration_loggable_controller.dart';
import 'package:super_logger/features/duration/duration_ui_helper.dart';
import 'package:super_logger/features/duration/models/duration_log.dart';
import 'package:super_logger/features/duration/models/duration_properties.dart';

class DurationFactory extends BaseLoggableFactory<DurationLog> {
  static DurationUiHelper? _durationUiHelper;

  @override
  Loggable loggableFromMap(Map<String, dynamic> map) {
    return Loggable.fromJson(
      map,
      generalMapper: DurationProperties.fromJson,
      mainCardMapper: EmptyProperty.fromMap,
      aggregationMapper: EmptyProperty.fromMap,
    );
  }

  @override
  LoggableController<Object> createLoggableController(
      MainRepository repository, Loggable loggable) {
    return DurationLoggableController(loggable: loggable, repository: repository);
  }

  @override
  MappableObject createDefaultProperties() {
    return DurationProperties.defaults();
  }

  @override
  ValueFromMap<DurationLog>? entryValueFromMap() {
    return DurationLog.fromJson;
  }

  @override
  ValueToMap? entryValueToMap() {
    return (entry) => (entry as DurationLog).toJson();
  }

  @override
  LoggableTypeDescription getLoggableTypeDescription() {
    return const LoggableTypeDescription(
        title: "Duration", description: "Duration", icon: Icons.timelapse);
  }

  @override
  LoggableUiHelper getUiHelper() {
    return _durationUiHelper ??= DurationUiHelper();
  }

  @override
  LoggableType get type => LoggableType.duration;
}
