import 'package:freezed_annotation/freezed_annotation.dart';
part 'loggable_tag.freezed.dart';

@freezed
class LoggableTag with _$LoggableTag {
  const LoggableTag._();

  const factory LoggableTag({
    required String name,
    required String id,
  }) = _LoggableTag;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory LoggableTag.fromJson(Map<String, dynamic> json) {
    return LoggableTag(
      name: json['name'],
      id: json['id'],
    );
  }
}
