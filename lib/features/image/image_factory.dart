import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggable_factory.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/loggable_type_description.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/features/image/image_loggable_controller.dart';
import 'package:super_logger/features/image/image_ui_helper.dart';
import 'package:super_logger/features/image/models/image_log.dart';
import 'package:super_logger/features/image/models/image_properties.dart';

class ImageFactory extends BaseLoggableFactory<ImageLog> {
  static ImageUiHelper? _imageUiHelper;

  @override
  Loggable loggableFromMap(Map<String, dynamic> map) {
    return Loggable.fromJson(
      map,
      generalMapper: ImageProperties.fromJson,
      mainCardMapper: EmptyProperty.fromMap,
      aggregationMapper: EmptyAggregationConfig.fromMap,
    );
  }

  @override
  MappableObject generalConfigFromMap(Map<String, dynamic> map) => ImageProperties.fromJson(map);

  @override
  LoggableController<Object> createLoggableController(
      MainRepository repository, Loggable loggable) {
    return ImageLoggableController(loggable: loggable, repository: repository);
  }

  @override
  MappableObject createDefaultProperties() {
    return ImageProperties(o1: "o1");
  }

  @override
  ValueFromMap<ImageLog>? entryValueFromMap() {
    return ImageLog.fromJson;
  }

  @override
  ValueToMap? entryValueToMap() {
    return (entry) => (entry as ImageLog).toJson();
  }

  @override
  LoggableTypeDescription getLoggableTypeDescription() {
    return const LoggableTypeDescription(title: "Image", description: "Image", icon: Icons.image);
  }

  @override
  LoggableUiHelper getUiHelper() {
    return _imageUiHelper ??= ImageUiHelper();
  }

  @override
  LoggableType get type => LoggableType.image;
}
