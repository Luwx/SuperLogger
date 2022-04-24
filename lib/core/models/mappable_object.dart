abstract class MappableObject {
  Map<String, dynamic> toJson();
}

class EmptyProperty implements MappableObject {
  const EmptyProperty();
  @override
  Map<String, dynamic> toJson() {
    return {};
  }

  static EmptyProperty fromMap(Map<String, dynamic> map) {
    return const EmptyProperty();
  }
}
