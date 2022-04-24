
import 'package:super_logger/utils/extensions.dart';

class Log<T> {
  final String id;
  final DateTime timestamp;
  final T value;
  final String note;

  Log({required this.id, required this.timestamp, required this.value, required this.note});

  Log.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>)? valueFromMap)
      : id = json['id'],
        timestamp = DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
        value = valueFromMap == null ? json['value'] : valueFromMap(json['value']),
        note = json['note'] ?? "";

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T)? valueToMap) => {
        'id': id,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'value': valueToMap == null ? value : valueToMap(value),
        if (note != "") 'note': note,
      };

  @override
  String toString() {
    return 'Log(id: $id, timestamp: $timestamp, value: $value, note: $note)';
  }

  Log<T> copyWith({
    String? id,
    DateTime? timestamp,
    T? value,
    String? note,
  }) {
    return Log<T>(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      value: value ?? this.value,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Log<T> &&
      other.id == id &&
      other.timestamp == timestamp &&
      other.value == value &&
      other.note == note;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      timestamp.hashCode ^
      value.hashCode ^
      note.hashCode;
  }
}

extension LogHelpers on Log {
  String get dateAsISO8601 => timestamp.asISO8601;
  String get formattedTime => timestamp.formattedTimeHMS;
}

