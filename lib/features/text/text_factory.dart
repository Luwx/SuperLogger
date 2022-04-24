import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggable_factory.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/loggable_type_description.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/features/text/models/text_properties.dart';
import 'package:super_logger/features/text/text_loggable_controller.dart';
import 'package:super_logger/features/text/text_ui_helper.dart';

class TextFactory extends BaseLoggableFactory<String> {
  static TextUiHelper? _textUiHelper;

  @override
  Loggable loggableFromMap(Map<String, dynamic> map) {
    return Loggable.fromJson(
      map,
      generalMapper: TextProperties.fromJson,
      mainCardMapper: EmptyProperty.fromMap,
      aggregationMapper: EmptyProperty.fromMap,
    );
  }

  @override
  LoggableController<Object> createLoggableController(
      MainRepository repository, Loggable loggable) {
    return TextLoggableController(loggable: loggable, repository: repository);
  }

  @override
  MappableObject createDefaultProperties() {
    return TextProperties.defaults();
  }

  @override
  LoggableTypeDescription getLoggableTypeDescription() {
    return const LoggableTypeDescription(title: "Text", description: "Text", icon: Icons.note);
  }

  @override
  LoggableUiHelper getUiHelper() {
    return _textUiHelper ??= TextUiHelper();
  }

  @override
  LoggableType get type => LoggableType.text;
}
