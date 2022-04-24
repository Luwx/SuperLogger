import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:super_logger/core/repository/main_repository/drift/drift_db.dart';

@DataClassName('LogEntry')
class Logs extends Table {
  TextColumn get id => text()();
  TextColumn get loggableId => text().customConstraint('REFERENCES loggables(id)')();
  TextColumn get date => text().withLength(max: 12)();
  IntColumn get timestamp => integer()();
  TextColumn get value => text()();
  TextColumn get note => text().nullable().withLength(max: 200)();

  @override
  Set<Column> get primaryKey => {id};
}

class LogEntryConverter {
  LogEntryConverter._();
  // static Map<String, dynamic> driftLogToJson(LogEntry log) {
  //   return {
  //     'id': log.id,
  //     //'loggableId': '',
  //     'value': jsonEncode(log.value),
  //     'timestamp': log.timestamp.millisecondsSinceEpoch ~/1000,
  //     'note': log.note,
  //   };
  // }

  static LogEntry driftFromBaseLog(Map<String, dynamic> logMap, String loggableId, String date) {
    return LogEntry(
      id: logMap['id'],
      loggableId: loggableId,
      date: date,
      timestamp: logMap['timestamp'],
      value: jsonEncode(logMap['value']),
      note: logMap['note'] ?? "",
    );
  }
}
