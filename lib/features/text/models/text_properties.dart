import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:super_logger/core/models/mappable_object.dart';

part 'text_properties.freezed.dart';

@freezed
class TextProperties with _$TextProperties implements MappableObject {
  const TextProperties._();
  const factory TextProperties({
    required int maximumLength,
    required bool useLargeFont,
    required IList<String> suggestions,
  }) = _TextProperties;

  //factory TextProperties.fromJson(Map<String, dynamic> json) => _$TextPropertiesFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    return {
      'maximumLength': maximumLength,
      'useLargeFont': useLargeFont,
      'suggestions': suggestions.unlock,
    };
  }

  factory TextProperties.fromJson(Map<String, dynamic> json) {
    return TextProperties(
      maximumLength: json['maximumLength'],
      useLargeFont: json['useLargeFont'],
      suggestions: List<String>.from(json['suggestions']).lock,
    );
  }

  factory TextProperties.defaults() =>
      TextProperties(maximumLength: 5000, useLargeFont: false, suggestions: <String>[].lock);
}
