import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggable_factory.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/loggable_type_description.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/value_controller.dart';

class MainFactory {
  final Map<LoggableType, LoggableFactory> _factoryMap;
  MainFactory(List<LoggableFactory> factories)
      : _factoryMap = {for (var factry in factories) factry.type: factry};

  List<LoggableFactory> getFactories() {
    return _factoryMap.entries.map((e) => e.value).toList();
  }

  // int counter = 0;
  // this is getting called too many times..
  LoggableFactory getFactoryFor(LoggableType type) {
    //print(counter++);
    final loggableFactory = _factoryMap[type];
    if (loggableFactory == null) {
      throw Exception("Loggable of type $type not found");
    }
    return loggableFactory;
  }

  MappableObject generalConfigFromMap(Map<String, dynamic> map, LoggableType type) {
    return getFactoryFor(type).generalConfigFromMap(map);
  }

  LoggableUiHelper getUiHelper(LoggableType type) {
    return getFactoryFor(type).getUiHelper();
  }

  LoggableTypeDescription getLoggableTypeDescription(LoggableType type) {
    return getFactoryFor(type).getLoggableTypeDescription();
  }

  ValueEitherController makeValueController(LoggableType type) {
    return getFactoryFor(type).createValueController();
  }

  MappableObject makeDefaultProperties(LoggableType type) {
    return getFactoryFor(type).createDefaultProperties();
  }

  LoggableController makeLoggableController(Loggable loggable) {
    return getFactoryFor(loggable.type)
        .createLoggableController(locator.get<MainRepository>(), loggable);
  }

  ValueEitherController createValueController(LoggableType type) {
    return getFactoryFor(type).createValueController();
  }

  Log makeNewLog(
    LoggableType type, {
    required String id,
    required DateTime timestamp,
    required Object value,
    required String note,
  }) {
    return getFactoryFor(type).makeNewLog(
      id: id,
      timestamp: timestamp,
      value: value,
      note: note,
    );
  }

  Loggable loggableFromMap(Map<String, dynamic> map) {
    String typeString = map['type'];
    LoggableType type =
        LoggableType.values.firstWhere((loggableType) => loggableType.toString() == typeString);
    return getFactoryFor(type).loggableFromMap(map);
  }

  Map<String, dynamic> logToMap(LoggableType type, Log log) {
    return getFactoryFor(type).logToMap(log);
  }

  DateLog<T> createDateLog<T>(LoggableType type, String date) {
    return getFactoryFor(type).createDateLog(date) as DateLog<T>;
  }

  ValueToMap? entryValueToMap(LoggableType type) {
    return getFactoryFor(type).entryValueToMap();
  }

  ValueFromMap<T>? entryValueFromMap<T>(LoggableType type) {
    return getFactoryFor(type).entryValueFromMap() as ValueFromMap<T>?;
  }
}
