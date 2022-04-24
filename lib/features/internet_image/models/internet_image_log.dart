import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'internet_image_log.freezed.dart';

@freezed
class InternetImageLog with _$InternetImageLog {
  const InternetImageLog._();

  const factory InternetImageLog({
    required String name,
    required IList<String> urls,
  }) = _InternetImageLog;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'urls': urls.unlock,
    };
  }

  factory InternetImageLog.fromJson(Map<String, dynamic> json) {
    return InternetImageLog(
      name: json['name'],
      urls: List<String>.from(json['urls']).lock,
    );
  }

}
