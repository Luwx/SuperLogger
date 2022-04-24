import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggable_factory.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/loggable_type_description.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/features/choice/choice_loggable_controller.dart';
import 'package:super_logger/features/choice/choice_ui_helper.dart';
import 'package:super_logger/features/choice/models/choice_properties.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';

class ChoiceFactory extends BaseLoggableFactory<String> {
  static ChoiceUiHelper? _choiceUiHelper;

  @override
  Loggable loggableFromMap(Map<String, dynamic> map) {
    return Loggable.fromJson(
      map,
      generalMapper: ChoiceProperties.fromJson,
      mainCardMapper: EmptyProperty.fromMap,
      aggregationMapper: EmptyProperty.fromMap,
    );
  }

  @override
  LoggableController<Object> createLoggableController(
      MainRepository repository, Loggable loggable) {
    return ChoiceLoggableController(loggable: loggable, repository: repository);
  }

  @override
  MappableObject createDefaultProperties() {
    return ChoiceProperties(
      optionType: LoggableType.text,
      isRanked: false,
      useSlider: false,
      options: <ChoiceOption>[].lock,
      metadataTemplate: <ChoiceOptionMetadataPropertyTemplate>[].lock,
    );
  }

  @override
  LoggableTypeDescription getLoggableTypeDescription() {
    return const LoggableTypeDescription(title: "Choice", description: "Choice", icon: Icons.list);
  }

  @override
  LoggableUiHelper getUiHelper() {
    return _choiceUiHelper ??= ChoiceUiHelper();
  }

  @override
  LoggableType get type => LoggableType.choice;
}
