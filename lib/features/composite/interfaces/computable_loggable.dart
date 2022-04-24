import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/models/mappable_object.dart';

abstract class ComputableInformation {
  String get displayInformation;
}

abstract class ComputableLoggable {
  IList<ComputableInformation> get computablesInformation;
  double? getComputableValue(ComputableInformation info, MappableObject properties, Log log);
}
