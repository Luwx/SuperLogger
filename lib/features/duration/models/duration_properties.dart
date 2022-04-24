
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:super_logger/core/models/mappable_object.dart';

part 'duration_properties.freezed.dart';
part 'duration_properties.g.dart';

@freezed
class DurationProperties with _$DurationProperties implements MappableObject {
  const factory DurationProperties({
    required bool showTotalDurationOfDay,
    required bool canBePaused,
    required bool usePlayStopButton,
    required int? minDuration,
    required int? maxDuration,
  }) = _DurationProperties;

  factory DurationProperties.fromJson(Map<String, dynamic> json) =>
      _$DurationPropertiesFromJson(json);

  factory DurationProperties.defaults() => const DurationProperties(
      showTotalDurationOfDay: true,
      canBePaused: false,
      usePlayStopButton: true,
      minDuration: null,
      maxDuration: null);
}
