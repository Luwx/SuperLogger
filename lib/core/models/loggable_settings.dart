import 'dart:ui';

import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:super_logger/utils/value_controller.dart';

part 'loggable_settings.freezed.dart';
part 'loggable_settings.g.dart';

int? _colorToInt(Color? col) => col?.value;
Color? _intToColor(Object? json) => json == null ? null : Color(json as int);

@freezed
class LoggableSettings with _$LoggableSettings {
  const LoggableSettings._();
  const factory LoggableSettings({
    required bool pinned,
    required int? maxEntriesPerDay,
    required String symbol,
    // ignore: invalid_annotation_target
    @JsonKey(fromJson: _intToColor, toJson: _colorToInt) required Color? color,
  }) = _LoggableSettings;

  factory LoggableSettings.fromJson(Map<String, dynamic> json) => _$LoggableSettingsFromJson(json);

  factory LoggableSettings.defauls() =>
      const LoggableSettings(pinned: false, maxEntriesPerDay: 5, symbol: "", color: null);
}

class LoggableSettingsHelper {
  LoggableSettingsHelper._();
  static Either<ValueErr<LoggableSettings>, LoggableSettings> settingsValidator(
      LoggableSettings settings) {
    if (settings.maxEntriesPerDay != null && settings.maxEntriesPerDay! <= 0) {
      return Left(ValueErr("Invalid max entries per day", settings));
    } else {
      return Right(settings);
    }
  }
}
