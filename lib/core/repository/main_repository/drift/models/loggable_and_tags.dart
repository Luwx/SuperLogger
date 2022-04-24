import 'package:drift/drift.dart';

class LoggableAndTags extends Table {
  TextColumn get loggable => text()();
  TextColumn get tag => text()();
}
