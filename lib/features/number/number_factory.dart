import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggable_factory.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/loggable_type_description.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/features/number/models/number_properties.dart';
import 'package:super_logger/features/number/number_loggable_controller.dart';
import 'package:super_logger/features/number/number_ui_helper.dart';

class NumberFactory extends BaseLoggableFactory<double> {
  static LoggableUiHelper? _valueUiHelper;

  @override
  Loggable loggableFromMap(Map<String, dynamic> map) {
    return Loggable.fromJson(
      map,
      generalMapper: NumberProperties.fromJson,
      mainCardMapper: EmptyProperty.fromMap,
      aggregationMapper: EmptyProperty.fromMap,
    );
  }

  @override
  LoggableController createLoggableController(MainRepository repository, Loggable loggable) {
    return ValueLoggableController(repository, loggable);
  }

  @override
  MappableObject createDefaultProperties() {
    return NumberProperties.defaults();
  }

  @override
  LoggableTypeDescription getLoggableTypeDescription() {
    return const LoggableTypeDescription(
        title: "Number", description: "A numeric value", icon: Icons.numbers);
  }

  @override
  LoggableUiHelper getUiHelper() {
    return _valueUiHelper ??= NumberUiHelper();
  }

  @override
  LoggableType get type => LoggableType.number;
}
