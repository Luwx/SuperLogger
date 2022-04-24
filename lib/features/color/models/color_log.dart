
import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'color_log.freezed.dart';

@freezed
class ColorLog with _$ColorLog {
  const ColorLog._();
  const factory ColorLog({required String label, required Color color}) = _ColorLog;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {'color': color.value};
    if (label.isNotEmpty) {
      map.putIfAbsent('label', () => label);
    }
    return map;
  }

  factory ColorLog.fromJson(Map<String, dynamic> json) {
    return ColorLog(color: Color(json['color']), label: json['label'] ?? '');
  }
}
