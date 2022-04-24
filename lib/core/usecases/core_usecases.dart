import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';
import 'package:super_logger/locator.dart';

class CoreUsecases {
  final _GetLoggables getLoggables;
  MainRepository repository;

  CoreUsecases({required this.repository}) : getLoggables = _GetLoggables(repository);

  Future<void> addLoggable(Loggable loggable) async {
    await repository.addLoggable(loggable);
  }

  Future<void> updateLoggable(Loggable loggable) async {
    await repository.updateLoggable(loggable);
  }

  Stream<List<Loggable>> getLoggablesStream() {
    return repository.getLoggablesStream().map((loggables) => loggables
        .map((loggableMap) => locator.get<MainFactory>().loggableFromMap(loggableMap))
        .toList());
  }
}

class _GetLoggables {
  final MainRepository _repository;

  _GetLoggables(MainRepository repository) : _repository = repository;

  Future<List<Loggable>> call() async {
    List<Map<String, dynamic>> loggablesMap = await _repository.getLoggables();

    List<Loggable> loggables = [];

    for (var loggable in loggablesMap) {
      loggables.add(locator.get<MainFactory>().loggableFromMap(loggable));
    }

    return loggables;
  }
}

// class BaseCategoryController<T> {
//   final Repository _repository;
  
//   BaseCategory loggable;
//   CoreCategoryUseCases(Repository repository) : _repository = repository;

//   //Future<void> 
// }


