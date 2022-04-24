import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/file_path.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';
import 'package:super_logger/features/composite/models/composite_log.dart';

Future<void> updateFileables(
    String loggableId, String logId, CompositeLog compositeEntryList) async {
  for (final entry in compositeEntryList.entryList) {
    entry.when(
      singleEntry: (singleEntry) async {
        if (singleEntry.type == LoggableType.composite) {
          await updateFileables(loggableId, logId, singleEntry.value as CompositeLog);
        } else {
          if (singleEntry.value is Fileable) {
            Fileable fileable = (singleEntry as CompositeSingleEntry<Fileable>).value;
            singleEntry.value = fileable.copyWithFilePath(
              await FilePathHelper.updateFilePaths(loggableId, logId, singleEntry.value.filePaths),
            );
          }
        }
      },
      multiEntry: (multiEntry) async {
        for (final entry in multiEntry.values) {
          if (multiEntry.type == LoggableType.composite) {
            await updateFileables(loggableId, logId, entry.value as CompositeLog);
          } else {
            if (entry.value is Fileable) {
              Fileable fileable = (entry as CompositeSingleEntry<Fileable>).value;
              entry.value = fileable.copyWithFilePath(
                await FilePathHelper.updateFilePaths(loggableId, logId, entry.value.filePaths),
              );
            }
          }
        }
      },
    );
  }
}

class CompositeLoggableController extends LoggableController<CompositeLog> {
  CompositeLoggableController(MainRepository repository, Loggable loggable)
      : super(loggable: loggable, repository: repository);

  // @override
  // Future<void> addLog(Log<CompositeEntryList> log) async {
  //   // search for fileable values
  //   for (final entry in log.value.entryList) {
  //     entry.when(
  //       singleEntry: (singleEntry) {
  //         if (singleEntry.value is Fileable) {
  //           (singleEntry.value as Fileable).filePaths.when(
  //                 saved: (saved) {},
  //                 absolute: (absolute) {},
  //               );
  //         }
  //       },
  //       multiEntry: (multiEntry) {},
  //     );
  //   }

  //   await asyncTask(repository.addLog<CompositeEntryList>(loggable, log));
  // }

  @override
  Future<void> addLogs(List<Log> logs) async {
    await asyncTask(repository.addLogs<CompositeLog>(
        loggable, logs.map((log) => log as Log<CompositeLog>).toList()));
  }

  @override
  Future<void> updateLog(Log oldLog, Log newLog) async {
    await asyncTask(repository.updateLog<CompositeLog>(loggable,
        oldLog: oldLog as Log<CompositeLog>, newLog: newLog as Log<CompositeLog>));
  }

  @override
  Future<void> deleteLog(Log log) async {
    await deleteLogs([log]);
  }

  @override
  Future<void> deleteLogs(List<Log> logs) async {
    await asyncTask(repository.deleteLogs<CompositeLog>(
        loggable, logs.map((log) => log as Log<CompositeLog>).toList()));
  }
}
