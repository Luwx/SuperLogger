import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggable_factory.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/loggable_type_description.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/mappable_object.dart';

import 'package:super_logger/features/counter/counter_loggable_controller.dart';
import 'package:super_logger/features/counter/counter_ui_helper.dart';

import 'models/counter_properties.dart';

class CounterFactory extends BaseLoggableFactory<int> {
  LoggableUiHelper? _counterUiHelper;
  //LoggableController? _controller;

  @override
  Loggable loggableFromMap(Map<String, dynamic> map) {
    return Loggable.fromJson(
      map,
      generalMapper: CounterProperties.fromJson,
      mainCardMapper: EmptyProperty.fromMap,
      aggregationMapper: EmptyAggregationConfig.fromMap,
    );
  }

  @override
  LoggableTypeDescription getLoggableTypeDescription() {
    return const LoggableTypeDescription(
      title: "Counter",
      description: "A simple counter",
      icon: Icons.add,
    );
  }

  @override
  LoggableUiHelper getUiHelper() {
    return _counterUiHelper ??= CounterUiHelper();
  }

  @override
  LoggableController createLoggableController(MainRepository repository, Loggable loggable) {
    return CounterLoggableController(repository, loggable);
  }

  @override
  MappableObject generalConfigFromMap(Map<String, dynamic> map) => CounterProperties.fromJson(map);

  @override
  MappableObject createDefaultProperties() {
    return CounterProperties.defaults();
  }

  @override
  LoggableType get type => LoggableType.counter;
}
