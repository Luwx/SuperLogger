import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggable_factory.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/loggable_type_description.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/features/internet_image/internet_image_loggable_controller.dart';
import 'package:super_logger/features/internet_image/internet_image_ui_helper.dart';
import 'package:super_logger/features/internet_image/models/internet_image_log.dart';
import 'package:super_logger/features/internet_image/models/internet_image_properties.dart';

class InternetImageFactory extends BaseLoggableFactory<InternetImageLog> {
  static InternetImageUiHelper? _internetImageUiHelper;

  @override
  Loggable loggableFromMap(Map<String, dynamic> map) {
    return Loggable.fromJson(
      map,
      generalMapper: InternetImageProperties.fromJson,
      mainCardMapper: EmptyProperty.fromMap,
      aggregationMapper: EmptyAggregationConfig.fromMap,
    );
  }

  @override
  LoggableController<Object> createLoggableController(
      MainRepository repository, Loggable loggable) {
    return InternetImageLoggableController(loggable: loggable, repository: repository);
  }

  @override
  MappableObject generalConfigFromMap(Map<String, dynamic> map) => InternetImageProperties.fromJson(map);

  @override
  MappableObject createDefaultProperties() {
    return InternetImageProperties(o1: "o1");
  }

  @override
  ValueFromMap<InternetImageLog>? entryValueFromMap() {
    return InternetImageLog.fromJson;
  }

  @override
  ValueToMap? entryValueToMap() {
    return (entry) => (entry as InternetImageLog).toJson();
  }

  @override
  LoggableTypeDescription getLoggableTypeDescription() {
    return const LoggableTypeDescription(
        title: "Internet Image", description: "Internet Image", icon: Icons.image);
  }

  @override
  LoggableUiHelper getUiHelper() {
    return _internetImageUiHelper ??= InternetImageUiHelper();
  }

  @override
  LoggableType get type => LoggableType.internetImage;
}
