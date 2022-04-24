import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';
import 'package:super_logger/features/internet_image/models/internet_image_log.dart';

String getFileExtension(String fileName) {
  return "." + fileName.split('.').last;
}

class InternetImageLoggableController extends LoggableController<InternetImageLog> {
  InternetImageLoggableController({required Loggable loggable, required MainRepository repository})
      : super(loggable: loggable, repository: repository);
}
