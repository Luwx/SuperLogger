import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/file_path.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';
import 'package:super_logger/features/image/models/image_log.dart';

String getFileExtension(String fileName) {
  return "." + fileName.split('.').last;
}

class ImageLoggableController extends LoggableController<ImageLog> {
  ImageLoggableController({required Loggable loggable, required MainRepository repository})
      : super(loggable: loggable, repository: repository);

  @override
  Future<void> addLogs(List<Log> logs) async {
    final newLogs = logs.map((log) => log as Log<ImageLog>).toList();
    for (int i = 0; i < newLogs.length; i++) {
      newLogs[i] = newLogs[i].copyWith(
        value: newLogs[i].value.copyWith(
              filePaths: await FilePathHelper.updateFilePaths(
                  loggable.id, newLogs[i].id, newLogs[i].value.filePaths),
            ),
      );
    }
    await asyncTask(
      repository.addLogs<ImageLog>(
        loggable,
        newLogs,
      ),
    );
  }

  @override
  Future<void> deleteLogs(List<Log> logs) async {
    final deletedLogs = List<Log<ImageLog>>.from(logs);
    for (int i = 0; i < deletedLogs.length; i++) {
      await FilePathHelper.deleteFilePaths(deletedLogs[i].value.filePaths);
    }
    await asyncTask(
      repository.deleteLogs<ImageLog>(
        loggable,
        deletedLogs,
      ),
    );
  }

  @override
  Future<void> updateLog(Log oldLog, Log newLog) async {
    // delete oldLog images
    await FilePathHelper.deleteFilePaths((oldLog.value as ImageLog).filePaths);
    newLog = newLog.copyWith(
      value: newLog.value.copyWith(
        filePaths:
            await FilePathHelper.updateFilePaths(loggable.id, newLog.id, newLog.value.filePaths),
      ),
    );

    await asyncTask(repository.updateLog<ImageLog>(loggable,
        oldLog: oldLog as Log<ImageLog>, newLog: newLog as Log<ImageLog>));
  }

  @override
  Future<void> deleteSelfLoggable() async {
    await FilePathHelper.deleteAllFilesFromLoggable(loggable.id);
    await asyncTask(repository.deleteLoggable(loggable.id));
  }
}
