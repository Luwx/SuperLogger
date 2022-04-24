import 'package:nanoid/nanoid.dart';

String generateId() {
  return nanoid(12);
}

String generateSmallId() {
  return nanoid(8);
}
