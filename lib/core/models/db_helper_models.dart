
class LoggableIdAndLastLogTime {
  String id;
  int? lastLogTime;
  LoggableIdAndLastLogTime({
    required this.id,
    this.lastLogTime,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LoggableIdAndLastLogTime && other.id == id && other.lastLogTime == lastLogTime;
  }

  @override
  int get hashCode => id.hashCode ^ lastLogTime.hashCode;
}

class DateAndLogCount {
  String date;
  int logCount;
  DateAndLogCount({
    required this.date,
    required this.logCount,
  });

  DateAndLogCount copyWith({
    String? date,
    int? logCount,
  }) {
    return DateAndLogCount(
      date: date ?? this.date,
      logCount: logCount ?? this.logCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'logCount': logCount,
    };
  }

  factory DateAndLogCount.fromMap(Map<String, dynamic> map) {
    return DateAndLogCount(
      date: map['date'] ?? '',
      logCount: map['logCount']?.toInt() ?? 0,
    );
  }

  @override
  String toString() => 'DateAndLogCount(date: $date, logCount: $logCount)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is DateAndLogCount &&
      other.date == date &&
      other.logCount == logCount;
  }

  @override
  int get hashCode => date.hashCode ^ logCount.hashCode;
}
