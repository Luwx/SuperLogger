import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggable_factory.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/loggable_type_description.dart';
import 'package:super_logger/features/color/color_loggable_controller.dart';
import 'package:super_logger/features/color/color_ui_helper.dart';
import 'package:super_logger/features/color/models/color_log.dart';
import 'package:super_logger/features/color/models/color_properties.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';

class ColorFactory extends BaseLoggableFactory<ColorLog> {
  static ColorUiHelper? _colorUiHelper;

  @override
  Loggable loggableFromMap(Map<String, dynamic> map) {
    return Loggable.fromJson(
      map,
      generalMapper: ColorProperties.fromJson,
      mainCardMapper: EmptyProperty.fromMap,
      aggregationMapper: EmptyProperty.fromMap,
    );
  }

  @override
  LoggableController<Object> createLoggableController(
      MainRepository repository, Loggable loggable) {
    return ColorLoggableController(loggable: loggable, repository: repository);
  }

  @override
  MappableObject createDefaultProperties() {
    return ColorProperties.defaults();
  }

  @override
  ValueFromMap<ColorLog>? entryValueFromMap() {
    return ColorLog.fromJson;
  }

  @override
  ValueToMap? entryValueToMap() {
    return (entry) => (entry as ColorLog).toJson();
  }

  @override
  LoggableTypeDescription getLoggableTypeDescription() {
    return const LoggableTypeDescription(
        title: "Color", description: "Describes a color and its label", icon: Icons.colorize);
  }

  @override
  LoggableUiHelper getUiHelper() {
    return _colorUiHelper ??= ColorUiHelper();
  }

  @override
  LoggableType get type => LoggableType.color;
}
