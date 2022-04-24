import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:super_logger/core/models/file_path.dart';

part 'audio_log.freezed.dart';

@freezed
class AudioLog with _$AudioLog implements Fileable {
  const AudioLog._();

  const factory AudioLog({
    required String name,
    required FilePath filePath,
    required IList<AudioMark> marks,
  }) = _AudioLog;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'marks': marks.map((mark) => mark.toJson()).toList(),
      'filePaths': filePaths.map((filePath) => filePath.path).toList(),
    };
  }

  factory AudioLog.fromJson(Map<String, dynamic> json) {
    return AudioLog(
      name: json['name'],
      marks: List<Map<String, dynamic>>.from(json['marks']).map((markMap) => AudioMark.fromJson(markMap)).toIList(),
      filePath: SavedFilePath.fromPath(path: json['filePath'], fileType: FileType.audio),
    );
  }

  @override
  IList<FilePath> get filePaths => [filePath].lock;

  @override
  AudioLog copyWithFilePath(IList<FilePath> filePaths) {
    assert(filePaths.length == 1);
    return copyWith(filePath: filePaths.first);
  }
}

@freezed
class AudioMark with _$AudioMark {
  const AudioMark._();
  const factory AudioMark({required String name, required int seconds}) = _AudioMark;

  Map<String, dynamic> toJson() {
    return {'name': name, 'seconds': seconds};
  }

  factory AudioMark.fromJson(Map<String, dynamic> json) {
    return AudioMark(name: json['name'], seconds: json['seconds']);
  }
}
