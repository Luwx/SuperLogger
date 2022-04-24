import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';
import 'package:super_logger/features/duration/models/duration_log.dart';

class DurationLoggableController extends LoggableController<DurationLog> {
  DurationLoggableController({required Loggable loggable, required MainRepository repository})
      : super(loggable: loggable, repository: repository);
}
