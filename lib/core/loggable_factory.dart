import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/loggable_type_description.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';
import 'package:super_logger/utils/value_controller.dart';

typedef ValueToMap<T> = Map<String, dynamic> Function(T);
typedef ValueFromMap<T> = T Function(Map<String, dynamic>);

abstract class LoggableFactory<T> {
  LoggableType get type;

  LoggableTypeDescription getLoggableTypeDescription();
  LoggableUiHelper getUiHelper();

  ValueEitherController createValueController();
  MappableObject createDefaultProperties();

  LoggableController createLoggableController(MainRepository repository, Loggable loggable);

  Log makeNewLog({
    required String id,
    required DateTime timestamp,
    required Object value,
    required String note,
  });

  ValueToMap? entryValueToMap();
  ValueFromMap<T>? entryValueFromMap();

  Loggable loggableFromMap(Map<String, dynamic> map);

  MappableObject generalConfigFromMap(Map<String, dynamic> map);

  Map<String, dynamic> logToMap(Log log);
  DateLog createDateLog(String date);
  Log logFromMap(Map<String, dynamic> map);
}

abstract class BaseLoggableFactory<T> implements LoggableFactory<T> {
  @override
  Log makeNewLog({
    required String id,
    required DateTime timestamp,
    required Object value,
    required String note,
  }) {
    return Log<T>(id: id, timestamp: timestamp, value: value as T, note: note);
  }

  @override
  ValueEitherController createValueController() {
    return ValueEitherController<T>();
  }

  @override
  Map<String, dynamic> logToMap(Log log) {
    return log.toJson(entryValueToMap());
  }

  @override
  ValueToMap? entryValueToMap() => null;

  @override
  ValueFromMap<T>? entryValueFromMap() => null;

  @override
  Log logFromMap(Map<String, dynamic> map) {
    return Log<T>.fromJson(map, entryValueFromMap());
  }

  @override
  DateLog createDateLog(String date) {
    return DateLog<int>(date: date, logs: []);
  }
}
