import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:super_logger/core/models/file_path.dart';

part 'image_log.freezed.dart';

@freezed
class ImageLog with _$ImageLog implements Fileable {
  const ImageLog._();

  const factory ImageLog({
    required String name,
    required IList<FilePath> filePaths,
  }) = _ImageLog;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'filePaths': filePaths.map((filePath) => filePath.path).toList(),
    };
  }

  factory ImageLog.fromJson(Map<String, dynamic> json) {
    return ImageLog(
      name: json['name'],
      filePaths: <FilePath>[
        ...List<String>.from(json['filePaths'])
            .map((e) => SavedFilePath.fromPath(path: e, fileType: FileType.image)),
      ].lock,
    );
  }

  @override
  ImageLog copyWithFilePath(IList<FilePath> filePaths) => copyWith(filePaths: filePaths);
}
