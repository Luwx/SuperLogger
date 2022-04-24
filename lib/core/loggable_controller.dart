import 'package:flutter/widgets.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/models/filters.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/presentation/screens/loggable_details/loggable_details_screen.dart';
import 'package:super_logger/core/presentation/screens/loggable_details/sort_log_list_form.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';

abstract class LoggableController<T extends Object> extends ChangeNotifier {
  LoggableController({required Loggable loggable, required this.repository}) : _loggable = loggable;

  @protected
  MainRepository repository;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  bool _busy = false;
  bool get isBusy => _busy;
  @protected
  void setBusy() {
    assert(_busy == false);
    _busy = true;
    notifyListeners();
  }

  @protected
  void setIdle() {
    assert(_busy == true);
    _busy = false;
    notifyListeners();
  }

  @protected
  Future<void> asyncTask(Future<void> task) async {
    // complete the task anyway
    if (_disposed) {
      await task;
      return;
    } else {
      setBusy();
      await task;
      setIdle();
    }
  }

  Loggable _loggable;
  Loggable get loggable => _loggable;
  Future<void> refreshLoggable() async {
    await asyncTask(() async {
      _loggable = locator.get<MainFactory>().loggableFromMap(
            await repository.getLoggable(loggable.id),
          );
    }());
  }

  //--------------
  // Streams
  //--------------
  // listen to a single datelog

  DateLog<T>? _cachedDateLog;
  Future<DateLog<T>> getCachedDateLog(String date) async {
    if (_cachedDateLog == null) {
      _cachedDateLog = (await getDateLog(date)) as DateLog<T>;
    } else {
      if (_cachedDateLog!.date != date) {
        _cachedDateLog = (await getDateLog(date)) as DateLog<T>;
      }
    }
    return Future.value(_cachedDateLog);
  }

  Stream<DateLog<T>?>? _currentDateLog;
  Stream<DateLog<T>?> get currentDateLog {
    assert(_currentDateLog != null, "current dateLog stream is not set up");
    return _currentDateLog!;
  }

  void setupDateLogStream(DateTime date) {
    _currentDateLog = repository.getDateLogStreamForDate<T>(loggable, date.asISO8601);
    onSetupDateLogStream();
  }

  // extending classes will use this to listen to the current date log, if needed
  //@Deprecated("")
  @protected
  void onSetupDateLogStream() {}

  // // listen to all datelogs
  // Stream<List<DateLog<T>>>? _dateLogListStream;
  // @Deprecated("use get allLogsStream")
  // Stream<List<DateLog<T>>> get dateLogsStream {
  //   //assert(_dateLogListStream != null, "dateLog list stream is not set up");
  //   if (_dateLogListStream == null) {
  //     _dateLogListStream = repository.getDateLogsStream<T>(loggable);
  //     _dateLogListStream!.listen((dateLogs) {
  //       _dateLogsList = dateLogs;
  //       _cachedDateLog = null;
  //       notifyListeners();
  //     });
  //     onSetupDateLogListStream();
  //   }

  //   return _dateLogListStream!;
  // }

  @protected
  void onSetupAllLogsStream() {}

  // // store the latest valid resulf of stream
  // List<DateLog<T>>? _dateLogsList;
  // List<DateLog<T>>? get dateLogsList {
  //   assert(_dateLogListStream != null,
  //       "dateLog list stream is not set up, did you call setupDateLogListStream()?");
  //   return _dateLogsList;
  // }

  // extending classes will use this to listen to the current date log, if needed
  @protected
  void onSetupDateLogListStream() {}

  // listen to all logs
  NullableDateLimits? _currentDateLimitParemeter;
  SortingOrder _currentSortingOrder = SortingOrder.descending;
  Stream<List<Log<T>>>? _allLogsStream;
  Stream<List<Log<T>>> getAllLogsStream({
    NullableDateLimits dateLimits = const NullableDateLimits(),
    SortingOrder order = SortingOrder.descending,
  }) {
    if (_allLogsStream == null ||
        dateLimits != _currentDateLimitParemeter ||
        order != _currentSortingOrder) {
      _allLogsStream = repository.getLogsStream<T>(loggable, dateLimits: dateLimits, order: order);
      _currentDateLimitParemeter = dateLimits;
      _currentSortingOrder = order;

      //! see _allLogsList
      // _allLogsStream!.listen((logs) {
      //   _allLogsList = logs;
      //   _cachedDateLog = null;
      //   notifyListeners();
      // });
      onSetupDateLogListStream();
    }

      return _allLogsStream!;
  }

  //! was useful when using firebase, for some reason the stream would not load a second time, so some caching was need
  // store the latest valid resulf of stream
  // List<Log<T>>? _allLogsList;
  // List<Log<T>>? get allLogsList {
  //   assert(_allLogsStream != null,
  //       "dateLog list stream is not set up, did you call setupDateLogListStream()?");
  //   return _allLogsList;
  // }

  //--------------
  // CRUD
  //--------------
  Future<void> addLog(Log<T> log) async {
    await addLogs([log]);
  }

  Future<void> addLogs(List<Log> logs) async {
    await asyncTask(repository.addLogs<T>(loggable, logs.map((log) => log as Log<T>).toList()));
  }

  Future<void> updateLog(Log oldLog, Log newLog) async {
    await asyncTask(
        repository.updateLog<T>(loggable, oldLog: oldLog as Log<T>, newLog: newLog as Log<T>));
  }

  Future<void> deleteLog(Log log) async {
    await deleteLogs([log]);
  }

  Future<void> deleteLogs(List<Log> logs) async {
    await asyncTask(repository.deleteLogs<T>(loggable, logs.map((log) => log as Log<T>).toList()));
  }

  Future<void> deleteSelfLoggable() async {
    await asyncTask(repository.deleteLoggable(loggable.id));
  }

  Future<DateLog?> getDateLog(String date) async {
    return repository.getDateLog<T>(loggable, date);
  }

  Future<List<Log>> getAllLogs() async {
    return repository.getLogs<T>(loggable);
  }

  //--------------
  // Functionality
  //--------------

  bool hasString(String search, Log log) {
    if (log.value.toString().contains(search) || log.note.contains(search)) {
      return true;
    }
    return false;
  }

  Future<bool> isRelevant(String date) {
    return repository.hasLogsAtDate(loggable.id, date);
  }

  Future<int?> latestLogTimeOfDate(String date) {
    return repository.latestLogTime(loggable, date);
  }

  Future<void> togglePin() async {
    setBusy();
    Loggable newLoggable = loggable.copyWith(
      loggableSettings:
          loggable.loggableSettings.copyWith(pinned: !loggable.loggableSettings.pinned),
    );
    await repository.updateLoggable(newLoggable);
    _loggable = newLoggable;
    setIdle();
  }
}
