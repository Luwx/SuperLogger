import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';

class TextLoggableController extends LoggableController<String> {
  TextLoggableController({required Loggable loggable, required MainRepository repository})
      : super(loggable: loggable, repository: repository);
}
