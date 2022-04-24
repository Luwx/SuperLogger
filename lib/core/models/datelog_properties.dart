import 'package:super_logger/core/models/mappable_object.dart';

/// holds computed data of date x, e.g total value of some loggable in 2022-04-05
class DateLogProperties {
  final String date;
  final int logCount;
  final MappableObject? properties;
  DateLogProperties({
    required this.date,
    required this.logCount,
    required this.properties,
  });

  // DateLogProperties copyWith({
  //   String? date,
  //   int? logCount,
  //   MappableObject? properties,
  // }) {
  //   return DateLogProperties(
  //     date: date ?? this.date,
  //     logCount: logCount ?? this.logCount,
  //     properties: properties ?? this.properties,
  //   );
  // }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {'date': date, 'logCount': logCount};
    if (properties != null) {
      map.putIfAbsent('properties', () => properties!.toJson());
    }
    return map;
  }

  factory DateLogProperties.fromMap(Map<String, dynamic> map, MappableObject Function(Map<String, dynamic>)? propertyFromMap) {
    return DateLogProperties(
      date: map['date'],
      logCount: map['logCount'],
      properties: propertyFromMap?.call(map['properties']),
    );
  }

  @override
  String toString() => 'DateLogProperties(date: $date, logCount: $logCount, properties: $properties)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is DateLogProperties &&
      other.date == date &&
      other.logCount == logCount &&
      other.properties == properties;
  }

  @override
  int get hashCode => date.hashCode ^ logCount.hashCode ^ properties.hashCode;
}
