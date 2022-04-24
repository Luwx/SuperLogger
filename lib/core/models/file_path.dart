import 'dart:io';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:super_logger/utils/id_generator.dart';

enum FileType { image, audio }

abstract class Fileable {
  IList<FilePath> get filePaths;
  Fileable copyWithFilePath(IList<FilePath> filePaths);
}

/// Stores the path (relative or absolute) of a file
/// Only the values of SavedFilePath should be saved into the db
abstract class FilePath {
  final String path;
  final FileType fileType;
  FilePath(this.path, this.fileType);

  R when<R>(
      {required R Function(SavedFilePath) saved, required R Function(AbsoluteFilePath) absolute});
}

// should be in /files
class SavedFilePath extends FilePath {
  /// ONLY the filename, not the path
  SavedFilePath({required String filename, required FileType fileType})
      : super(p.join(fileType.name, filename), fileType);

  /// path should be something like "type/id"
  SavedFilePath.fromPath({required String path, required FileType fileType})
      : super(path, fileType);

  @override
  String toString() => 'SavedFilePath(path: $path, fileType: $fileType)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SavedFilePath && other.path == path && other.fileType == fileType;
  }

  @override
  int get hashCode => path.hashCode ^ fileType.hashCode;

  @override
  R when<R>(
      {required R Function(SavedFilePath p1) saved,
      required R Function(AbsoluteFilePath p1) absolute}) {
    return saved(this);
  }
}

// files from other places
class AbsoluteFilePath extends FilePath {
  AbsoluteFilePath({required String path, required FileType fileType}) : super(path, fileType);

  @override
  String toString() => 'AbsoluteFilePath(path: $path, fileType: $fileType)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AbsoluteFilePath && other.path == path && other.fileType == fileType;
  }

  @override
  int get hashCode => path.hashCode ^ fileType.hashCode;

  @override
  R when<R>(
      {required R Function(SavedFilePath p1) saved,
      required R Function(AbsoluteFilePath p1) absolute}) {
    return absolute(this);
  }
}

//---------------

class FilePathHelper {
  FilePathHelper._();

  static String getFileExtension(String fileName) {
    return "." + fileName.split('.').last;
  }

  static Future<IList<FilePath>> updateFilePaths(
      String loggableId, String logId, IList<FilePath> filePaths) async {
    final docsDirectory = await getApplicationDocumentsDirectory();

    List<FilePath> updatedFilePaths = [];
    for (final filePath in filePaths) {
      updatedFilePaths.add(
        await filePath.when(
          saved: (saved) async {
            String path = p.join(docsDirectory.path, saved.path);

            final file = File(path);
            bool exists = await file.exists();

            // check in tmp folder
            if (!exists) {
              String fileName = p.basename(saved.path);

              final tmpFile = File(p.join(docsDirectory.path, 'tmp', fileName));
              exists = await tmpFile.exists();

              // file is gone.. there is nothing we can do
              if (!exists) {
                return saved;
              } else {
                // restore file
                await File(path).create(recursive: true);
                await tmpFile.copy(path);
                await tmpFile.delete();
              }
            }
            // ok
            return saved;
          },
          absolute: (absolute) async {
            final file = File(filePath.path);

            SavedFilePath savedFilePath = SavedFilePath(
                filename: loggableId + logId + generateId() + getFileExtension(file.path),
                fileType: filePath.fileType);

            final path = p.join(docsDirectory.path, savedFilePath.path);
            await File(path).create(recursive: true);
            await file.copy(path);

            try {
              await file.delete();
            } catch (e) {
              //
            }

            return savedFilePath;
          },
        ),
      );
    }
    return updatedFilePaths.lock;
  }

  static Future<void> deleteFilePaths(IList<FilePath> filePaths) async {
    for (final filePath in filePaths) {
      await filePath.when(
        saved: (saved) async {
          final docsDirectory = await getApplicationDocumentsDirectory();
          final file = File(p.join(docsDirectory.path, saved.path));
          bool exists = await file.exists();
          if (!exists) {
            return;
          } else {
            // move to tmp
            String fileName = p.basename(saved.path);
            final tmpFile = File(p.join(docsDirectory.path, 'tmp', fileName));
            await tmpFile.create(recursive: true);
            await file.copy(tmpFile.path);
            await file.delete();
          }
        },
        absolute: (absolute) async {
          final file = File(filePath.path);
          try {
            await file.delete();
          } catch (e) {
            //
          }
        },
      );
    }
  }

  static Future<void> deleteAllFilesFromLoggable(String loggableId) async {
    final docsDirectory = await getApplicationDocumentsDirectory();
    // search in images
    if (await Directory(p.join(docsDirectory.path, FileType.image.name)).exists()) {
      var imageDir =
          await (Directory(p.join(docsDirectory.path, FileType.image.name)).list().toList());

      for (final file in imageDir) {
        String fileName = p.basename(file.path);
        if (fileName.startsWith(loggableId)) {
          await file.delete();
        }
      }
    }

    // search in audio
    if (await Directory(p.join(docsDirectory.path, FileType.audio.name)).exists()) {
      var audioDir =
          await (Directory(p.join(docsDirectory.path, FileType.audio.name)).list().toList());
      for (final file in audioDir) {
        String fileName = p.basename(file.path);
        if (fileName.startsWith(loggableId)) {
          await file.delete();
        }
      }
    }
  }
}
