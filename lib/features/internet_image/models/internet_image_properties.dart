
import 'package:super_logger/core/models/mappable_object.dart';

class InternetImageProperties implements MappableObject {
  final String o1;

  InternetImageProperties({required this.o1});

  @override
  Map<String, dynamic> toJson() {
    return {'o1': o1};
  }

  static InternetImageProperties fromJson(Map<String, dynamic> map) {
    return InternetImageProperties(o1: map['o1']);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is InternetImageProperties &&
      other.o1 == o1;
  }

  @override
  int get hashCode => o1.hashCode;
}
