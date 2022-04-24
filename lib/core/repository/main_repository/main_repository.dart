import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/db_helper_models.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/models/filters.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/core/presentation/screens/loggable_details/sort_log_list_form.dart';

abstract class MainRepository {
  // loggable related
  Future<Map<String, dynamic>> getLoggable(String loggableId);
  Future<void> addLoggable(Loggable loggable);
  Future<void> updateLoggable(Loggable loggable);
  Future<void> deleteLoggable(String loggableId);
  Future<List<Map<String, dynamic>>> getLoggables();
  Stream<List<Map<String, dynamic>>> getLoggablesStream();

  // Datelog related
  // Stream
  Stream<DateLog<T>?> getDateLogStreamForDate<T>(Loggable loggable, String date);
  Stream<List<Log<T>>> getLogsStream<T>(
    Loggable loggable, {
    NullableDateLimits dateLimits = const NullableDateLimits(),
    SortingOrder order = SortingOrder.descending,
  });

  Stream<int> getSingleDateAndLogCount(String date);

  // Add
  Future<void> addLog<T>(
    Loggable loggable,
    Log<T> log, {
    MappableObject Function(DateLog)? generateProperties,
  });
  Future<void> addLogs<T>(
    Loggable loggable,
    List<Log<T>> logs, {
    MappableObject Function(DateLog<T>)? generateProperties,
  });

  // Update
  Future<void> updateLog<T>(
    Loggable loggable, {
    required Log<T> oldLog,
    required Log<T> newLog,
    MappableObject Function(DateLog<T>)? generateProperties,
  });

  // Delete
  Future<void> deleteLog<T>(
    Loggable loggable,
    Log<T> log, {
    MappableObject Function(DateLog<T>)? generateProperties,
  });
  Future<void> deleteLogs<T>(
    Loggable loggable,
    List<Log<T>> logs, {
    MappableObject Function(DateLog<T>)? generateProperties,
  });

  // Get
  Future<List<Log<T>>> getLogs<T>(Loggable loggable);
  Future<DateLog<T>?> getDateLog<T>(Loggable loggable, String date);
  // Future<void> updateDateLogProperties(
  //     String loggableId, String date, Map<String, dynamic> properties);
  Future<List<LoggableIdAndLastLogTime>> categoriesAndLastLogTime(String date);
  Future<int?> latestLogTime<T>(Loggable loggable, String date);

  Future<bool> hasLogsAtDate(String loggableId, String date);
  Future<IMap<String, int>> getDateAndLogCount(String minDate, String maxDate);
}
