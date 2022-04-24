
import 'package:super_logger/core/models/mappable_object.dart';

class ImageProperties implements MappableObject {
  final String o1;

  ImageProperties({required this.o1});

  @override
  Map<String, dynamic> toJson() {
    return {'o1': o1};
  }

  static ImageProperties fromJson(Map<String, dynamic> map) {
    return ImageProperties(o1: map['o1']);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is ImageProperties &&
      other.o1 == o1;
  }

  @override
  int get hashCode => o1.hashCode;
}
