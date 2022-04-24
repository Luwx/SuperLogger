import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';

part 'base_loggable_for_composite.freezed.dart';

/// Wrapper around BaseLoggable to include Composite settings
@freezed
class LoggableForComposite with _$LoggableForComposite implements MappableObject {
  const LoggableForComposite._();

  const factory LoggableForComposite({
    //required Loggable loggable,
    required bool isArrayable,
    required bool isHiddenByDefault,
    required bool isDismissible,
    required bool hideTitle,
    required MappableObject properties,
    required LoggableType type,
    required String title,
    required String id,
  }) = _LoggableForComposite;

  //DateTime get creationDate => loggable.creationDate;
  //MappableObject get properties => loggable.loggableProperties;
  //LoggableType get type => loggable.type;
  //String get title => loggable.title;
  //String get id => loggable.id;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'title': title,
      'id': id,
      'properties': properties.toJson(),
      'isArrayable': isArrayable,
      'isHiddenByDefault': isHiddenByDefault,
      'isDismissible': isDismissible,
      'hideTitle': hideTitle,
    };
  }

  factory LoggableForComposite.fromJson(Map<String, dynamic> json) {
    // the loggable properties mapper will be automatically inserted from here
    final loggable = locator.get<MainFactory>().loggableFromMap(json);
    return LoggableForComposite(
      isArrayable: json['isArrayable'],
      isHiddenByDefault: json['isHiddenByDefault'],
      isDismissible: json['isDismissible'],
      hideTitle: json['hideTitle'],
      type: LoggableTypeHelper.fromString(json['type']),
      title: json['title'],
      id: json['id'],
      properties: json['properties'],
    );
  }
}
