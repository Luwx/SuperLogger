import 'dart:convert';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:super_logger/core/loggable_factory.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/db_helper_models.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/models/filters.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/core/presentation/screens/loggable_details/sort_log_list_form.dart';
import 'package:super_logger/core/repository/main_repository/drift/drift_db.dart';
import 'package:super_logger/core/repository/main_repository/drift/models/logs.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';

class DriftRepository implements MainRepository {
  final _db = AppDatabase();
  late LoggableDao _loggableDao;
  late LogEntryDao _logEntryDao;
  DriftRepository() {
    _loggableDao = _db.loggableDao;
    _logEntryDao = _db.logEntryDao;
  }

  @override
  Future<Map<String, dynamic>> getLoggable(String loggableId) async {
    return _loggableDao.getLoggable(loggableId).then((loggable) => loggable.toJson());
  }

  @override
  Future<void> addLoggable(Loggable loggable) async {
    return _loggableDao.addLoggable(LoggableWithTags.fromLoggable(loggable));
  }

  @override
  Future<void> deleteLoggable(String loggableId) async {
    return _loggableDao.deleteLoggable(loggableId);
  }

  @override
  Future<void> updateLoggable(Loggable loggable) async {
    return _loggableDao.addLoggable(LoggableWithTags.fromLoggable(loggable));
  }

  @override
  Future<List<Map<String, dynamic>>> getLoggables() async {
    return _loggableDao
        .getLoggables()
        .then((categories) => categories.map((loggable) => loggable.toJson()).toList());
  }

  @override
  Stream<List<Map<String, dynamic>>> getLoggablesStream() {
    return _loggableDao
        .getCategoriesStream()
        .map((categories) => categories.map((loggable) => loggable.toJson()).toList());
  }

  @override
  Stream<DateLog<T>?> getDateLogStreamForDate<T>(
    Loggable loggable,
    String date,
  ) {
    ValueFromMap<T>? valueFromMap =
        locator.get<MainFactory>().entryValueFromMap(loggable.type) as ValueFromMap<T>?;
    return _logEntryDao.getLogsForDateStream(loggable.id, date).map(
          (event) => event.isEmpty
              ? null
              : DateLog<T>(
                  date: date,
                  logs: event
                      .map((log) => Log<T>(
                          id: log.id,
                          timestamp: DateTime.fromMillisecondsSinceEpoch(log.timestamp),
                          value: valueFromMap?.call(jsonDecode(log.value)) ?? jsonDecode(log.value),
                          note: log.note ?? ""))
                      .toList(),
                ),
        );
  }

  @override
  Future<DateLog<T>?> getDateLog<T>(
    Loggable loggable,
    String date,
  ) async {
    ValueFromMap<T>? valueFromMap =
        locator.get<MainFactory>().entryValueFromMap(loggable.type) as ValueFromMap<T>?;
    final logs = await _logEntryDao.getLogsForDate(loggable.id, date);
    if (logs.isEmpty) return null;

    return DateLog<T>(
      date: date,
      logs: logs
          .map((log) => Log<T>(
              id: log.id,
              timestamp: DateTime.fromMillisecondsSinceEpoch(log.timestamp),
              value: valueFromMap?.call(jsonDecode(log.value)) ?? jsonDecode(log.value),
              note: log.note ?? ""))
          .toList(),
    );
  }

  // @override
  // Future<void> updateDateLogProperties(
  //     String loggableId, String date, Map<String, dynamic> properties) async {
  //   await _dateLogPropertiesDao.insert(
  //     DriftDateLogPropertie(
  //       loggableId: loggableId,
  //       date: date,
  //       properties: properties.toString(),
  //     ),
  //   );
  // }

  @override
  Future<void> deleteLog<T>(
    Loggable loggable,
    Log<T> log, {
    MappableObject Function(DateLog<T>)? generateProperties,
  }) async =>
      deleteLogs(loggable, [log], generateProperties: generateProperties);

  @override
  Future<void> deleteLogs<T>(
    Loggable loggable,
    List<Log<T>> logs, {
    //MappableObject Function(DateLog<T>, Log<T>)? onDelete,
    MappableObject Function(DateLog<T>)? generateProperties,
  }) async {
    //final Map<String, List<Log>> dateAndId = {};

    for (final log in logs) {
      await _logEntryDao.deleteById(log.id);
    }
  }

  @override
  Future<void> addLog<T>(
    Loggable loggable,
    Log<T> log, {
    MappableObject Function(DateLog<T>)? generateProperties,
  }) async {
    await addLogs(loggable, [log], generateProperties: generateProperties);
  }

  @override
  Future<void> addLogs<T>(
    Loggable loggable,
    List<Log<T>> logs, {
    MappableObject Function(DateLog<T>)? generateProperties,
  }) async {
    ValueToMap<T>? valueToMap = locator.get<MainFactory>().entryValueToMap(loggable.type);

    if (logs.length == 1) {
      await _logEntryDao.insertLog(LogEntryConverter.driftFromBaseLog(
          logs[0].toJson(valueToMap), loggable.id, logs[0].dateAsISO8601));
    } else {
      await _logEntryDao.insertMultipleLogs(logs
          .map((log) => LogEntryConverter.driftFromBaseLog(
              log.toJson(valueToMap), loggable.id, log.dateAsISO8601))
          .toList());
    }
  }

  @override
  Future<void> updateLog<T>(
    Loggable loggable, {
    required Log<T> oldLog,
    required Log<T> newLog,
    MappableObject Function(DateLog<T>)? generateProperties,
  }) async {
    // DateLog<T>? dateLog;
    // String date = oldLog.dateAsISO8601;

    ValueToMap<T>? valueToMap = locator.get<MainFactory>().entryValueToMap(loggable.type);

    await _logEntryDao.updateLog(LogEntryConverter.driftFromBaseLog(
        newLog.toJson(valueToMap), loggable.id, newLog.dateAsISO8601));
  }

  @override
  Future<List<Log<T>>> getLogs<T>(
    Loggable loggable, {
    NullableDateLimits dateLimits = const NullableDateLimits(),
  }) async {
    ValueFromMap<T>? valueFromMap =
        locator.get<MainFactory>().entryValueFromMap(loggable.type) as ValueFromMap<T>?;

    final logs = await _logEntryDao.getAllLogs(
      loggable.id,
      maxDate: dateLimits.maxDate?.asISO8601,
      minDate: dateLimits.minDate?.asISO8601,
    );

    return logs
        .map((logData) => Log<T>(
            id: logData.id,
            timestamp: DateTime.fromMillisecondsSinceEpoch(logData.timestamp),
            value: valueFromMap?.call(jsonDecode(logData.value)) ?? jsonDecode(logData.value),
            note: logData.note ?? ""))
        .toList();
  }

  @override
  Stream<List<Log<T>>> getLogsStream<T>(
    Loggable loggable, {
    NullableDateLimits dateLimits = const NullableDateLimits(),
    SortingOrder order = SortingOrder.descending,
  }) {
    ValueFromMap<T>? valueFromMap =
        locator.get<MainFactory>().entryValueFromMap(loggable.type) as ValueFromMap<T>?;

    return _logEntryDao
        .getAllLogsStream(loggable.id,
            maxDate: dateLimits.maxDate?.asISO8601,
            minDate: dateLimits.minDate?.asISO8601,
            isDescending: order == SortingOrder.descending)
        .map((logDataList) => logDataList
            .map((logData) => Log<T>(
                id: logData.id,
                timestamp: DateTime.fromMillisecondsSinceEpoch(logData.timestamp),
                value: valueFromMap?.call(jsonDecode(logData.value)) ?? jsonDecode(logData.value),
                note: logData.note ?? ""))
            .toList());
  }

  @override
  Future<bool> hasLogsAtDate(String loggableId, String date) {
    return _logEntryDao.existsInDate(loggableId, date);
  }

  @override
  Future<int?> latestLogTime<T>(Loggable loggable, String date) {
    return _logEntryDao.latestLogTimeOfDate(loggable.id, date);
  }

  @override
  Future<List<LoggableIdAndLastLogTime>> categoriesAndLastLogTime(String date) async {
    return _loggableDao.categoriesAndLastLogTime(date);
  }

  @override
  Future<IMap<String, int>> getDateAndLogCount(String minDate, String maxDate) {
    return _logEntryDao.getDateAndLogCount(minDate, maxDate);
  }

  @override
  Stream<int> getSingleDateAndLogCount(String date) {
    return _logEntryDao.getSingleDateAndLogCount(date);
  }
}
