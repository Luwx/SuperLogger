import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/db_helper_models.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';
import 'package:super_logger/core/usecases/core_usecases.dart';
import 'package:collection/collection.dart';

import 'package:super_logger/locator.dart';

class PremiumUser {}

class MainController extends ChangeNotifier {
  late Stream<List<Loggable>> _loggablesStream;
  Stream<List<Loggable>> get loggablesStream => _loggablesStream;

  final MainRepository _repository;

  //void setUser(User)

  //final List<>

  // String? _playingLog;
  // void setPlaying(String loggableId, String logId, ) {
  //   // stopCurrentPlaying();
  //   _playingLog = logId;
  // }

  String? _docsPath;
  Future<String> get docsPath async {
    if (_docsPath == null) {
      final directory = await getApplicationDocumentsDirectory();
      _docsPath = directory.path;
    }
    return Future.value(_docsPath);
  }

  List<Loggable> _loggablesList = [];
  List<Loggable> get loggablesList => List.unmodifiable(_loggablesList);

  Loggable? loggableById(String id) {
    return _loggablesList.firstWhereOrNull((loggable) => loggable.id == id);
  }

  MainController(this._repository) {
    _loggablesStream = _coreUsecases.getLoggablesStream();
    _loggablesStream.listen((categories) {
      _loggablesList = categories;

    });
  }


  static final CoreUsecases _coreUsecases = CoreUsecases(repository: locator.get<MainRepository>());

  // Future<void> loadCategories({VoidCallback? onDone}) async {
  //   _categories = await _coreUsecases.getCategories();
  //   if (onDone != null) onDone();
  // }

  static Future<void> addLoggable(Loggable loggable) async {
    await _coreUsecases.addLoggable(loggable);
    //await loadCategories();
  }

  static Future<void> updateLoggable(Loggable loggable) async {
    await _coreUsecases.updateLoggable(loggable);
    //await loadCategories();
  }

  Future<List<LoggableIdAndLastLogTime>> categoriesAndLastLogTime(String date) async {
    return _repository.categoriesAndLastLogTime(date);
  }

  Future<IMap<String, int>> getLogCount(String minDate, String maxDate) async {
    //print('minDate: $minDate, maxDate: $maxDate');
    return _repository.getDateAndLogCount(minDate, maxDate);
  }

  Stream<int> getSingleDateAndLogCount(String date) {
    return _repository.getSingleDateAndLogCount(date);
  }
}

class UniquePlayerManager extends ChangeNotifier {
  void stopPlaying() {
    notifyListeners();
  }
}
