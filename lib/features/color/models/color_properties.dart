
import 'package:super_logger/core/models/mappable_object.dart';

class ColorProperties implements MappableObject {
  final bool enableAlpha;

  ColorProperties({required this.enableAlpha});

  @override
  Map<String, dynamic> toJson() {
    return {'enableAlpha': enableAlpha};
  }

  static ColorProperties fromJson(Map<String, dynamic> map) {
    return ColorProperties(enableAlpha: map['enableAlpha']);
  }

  factory ColorProperties.defaults() {
    return ColorProperties(enableAlpha: false);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ColorProperties && other.enableAlpha == enableAlpha;
  }

  @override
  int get hashCode => enableAlpha.hashCode;
}
