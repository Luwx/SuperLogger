import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/repository/main_repository/drift/drift_db.dart';

@DataClassName('LoggableEntry')
class Loggables extends Table {
  TextColumn get id => text()();
  TextColumn get loggableSettings => text()();
  TextColumn get loggableProperties => text()();
  TextColumn get title => text()();
  DateTimeColumn get creationDate => dateTime()();
  TextColumn get type => text().withLength(max: 30)();

  @override
  Set<Column> get primaryKey => {id};
}

class LoggableConverver {
  LoggableConverver._();
  static Map<String, dynamic> driftLoggableToJson(LoggableEntry loggable) {
    return {
      'id': loggable.id,
      'loggableSettings': jsonDecode(loggable.loggableSettings),
      'loggableProperties': jsonDecode(loggable.loggableProperties),
      'title': loggable.title,
      'creationDate': loggable.creationDate.millisecondsSinceEpoch,
      'type': loggable.type,
    };
  }

  static LoggableEntry driftFromBaseLoggable(Loggable loggable) {
    return LoggableEntry(
      id: loggable.id,
      loggableSettings: jsonEncode(loggable.loggableSettings.toJson()),
      loggableProperties: jsonEncode(loggable.loggableProperties.toJson()),
      title: loggable.title,
      creationDate: loggable.creationDate,
      type: loggable.type.toString(),
    );
  }
}
