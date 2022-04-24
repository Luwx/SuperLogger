import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggable_factory.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/loggable_type_description.dart';
import 'package:super_logger/features/composite/composite_loggable_controller.dart';
import 'package:super_logger/features/composite/composite_ui_helper.dart';
import 'package:super_logger/features/composite/models/base_loggable_for_composite.dart';
import 'package:super_logger/features/composite/models/composite_log.dart';
import 'package:super_logger/features/composite/models/composite_properties.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/features/composite/models/computations.dart';

class CompositeFactory extends BaseLoggableFactory<CompositeLog> {
  LoggableUiHelper? _compositeUiHelper;

  @override
  Loggable loggableFromMap(Map<String, dynamic> map) {
    return Loggable.fromJson(
      map,
      generalMapper: CompositeProperties.fromMap,
      mainCardMapper: EmptyProperty.fromMap,
      aggregationMapper: EmptyProperty.fromMap,
    );
  }

  @override
  LoggableController<Object> createLoggableController(
      MainRepository repository, Loggable loggable) {
    return CompositeLoggableController(repository, loggable);
  }

  @override
  MappableObject createDefaultProperties() {
    return CompositeProperties.defaults();
  }

  @override
  ValueFromMap<CompositeLog>? entryValueFromMap() {
    return CompositeLog.fromMap;
  }

  @override
  ValueToMap? entryValueToMap() {
    return (logValue) => logValue.toMap();
  }

  @override
  LoggableTypeDescription getLoggableTypeDescription() {
    return const LoggableTypeDescription(
      title: "Composite",
      description: "A loggable that can be made of multiple categories",
      icon: Icons.multiple_stop,
    );
  }

  @override
  LoggableUiHelper getUiHelper() {
    return _compositeUiHelper ??= CompositeUiHelper();
  }

  @override
  LoggableType get type => LoggableType.composite;
}
