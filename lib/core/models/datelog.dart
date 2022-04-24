import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/models/mappable_object.dart';

class DateLog<T> {
  final String date;
  //final MappableObject properties;
  final List<Log<T>> _logs;
  List<Log<T>> get logs => List.unmodifiable(_logs);

  const DateLog({required this.date, required List<Log<T>> logs})
      : _logs = logs;

  factory DateLog.fromJson(
    Map<String, dynamic> json,
    //MappableObject Function(Map<String, dynamic>) propertyFromMap,
    T Function(Map<String, dynamic>)? valueFromMap,
  ) {
    List<Log<T>> tmpLogs = [];
    for (Map<String, dynamic> log in json['logs']) {
      tmpLogs.add(Log<T>.fromJson(log, valueFromMap));
    }
    return DateLog<T>(
      date: json['date'],
      //properties: propertyFromMap(json['properties']),
      logs: tmpLogs,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T)? valueToMap) => {
        'date': date,
        //'properties': properties.toJson(),
        'logs': logs.map((log) => log.toJson(valueToMap)).toList()
      };

  DateLog<T> copyWith({
    String? date,
    MappableObject? properties,
    List<Log<T>>? logs,
  }) {
    return DateLog<T>(
      date: date ?? this.date,
      //properties: properties ?? this.properties,
      logs: logs ?? _logs,
    );
  }
}

// class DateLogHelper {
//   DateLogHelper._();
//   static DateLog<T> withAddedLogs<T>(DateLog<T> dateLog, List<Log<T>> logs,
//       {MappableObject Function(DateLog<T>)? onAddCompleted}) {
//     bool shouldSort = false;

//     final existingLogs = [...dateLog.logs];

//     for (final log in logs) {
//       assert(dateLog.date == log.dateAsISO8601,
//           "Dates don't match, dateLog: ${dateLog.date}, log: ${log.dateAsISO8601}");
//       if (existingLogs.any((existingLog) => existingLog.id == log.id)) {
//         throw Exception("Trying to add an already existing log ${log.id}");
//       }
//       // sorting is needed
//       if (existingLogs.isNotEmpty && log.timestamp < existingLogs.last.timestamp) {
//         shouldSort = true;
//       }
//       existingLogs.add(log);
//     }

//     if (shouldSort) {
//       existingLogs.sort((log1, log2) => log1.timestamp.compareTo(log2.timestamp));
//     }

//     var newDateLog = dateLog.copyWith(logs: existingLogs);
//     newDateLog = newDateLog.copyWith(properties: onAddCompleted?.call(newDateLog));
//     return newDateLog;
//   }

//   static DateLog<T> withAddedLog<T>(DateLog<T> dateLog, Log<T> log,
//           {MappableObject Function(DateLog<T>)? onAddCompleted}) =>
//       withAddedLogs<T>(dateLog, [log], onAddCompleted: onAddCompleted);

//   static DateLog<T> withDeletedLogs<T>(
//     DateLog<T> dateLog,
//     List<Log> logs, {
//     MappableObject Function(DateLog<T>)? onDeleteCompleted,
//   }) {
//     final existingLogs = [...dateLog.logs];

//     // checks if all logs to be deleted are in the existingLogs
//     // this may not be needed..
//     // if (!logs.every((log) => existingLogs.any((existingLog) => log.id == existingLog.id))) {
//     //   // find non existing log
//     //   Log? lostLog =
//     //       logs.firstWhere((log) => existingLogs.any((existingLog) => log.id == existingLog.id));
//     //   throw Exception("Log $lostLog was not found and cannot be deleted");
//     // }

//     existingLogs.removeWhere((existingLog) {
//       if (logs.any((log) => log.id == existingLog.id)) {
//         return true;
//       }
//       return false;
//     });

//     var newDateLog = dateLog.copyWith(logs: existingLogs);
//     newDateLog = newDateLog.copyWith(properties: onDeleteCompleted?.call(newDateLog));
//     return newDateLog;
//   }

//   static DateLog<T> withDeletedLog<T>(
//     DateLog<T> dateLog,
//     Log<T> log, {
//     MappableObject Function(DateLog<T>)? onDeleteCompleted,
//   }) =>
//       withDeletedLogs<T>(dateLog, [log], onDeleteCompleted: onDeleteCompleted);
// }
