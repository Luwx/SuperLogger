import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'package:super_logger/core/loggable_factory.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';

class CompositeLog {
  IList<CompositeEntry> entryList;
  CompositeLog({
    required this.entryList,
  });

  Map<String, dynamic> toMap() {
    List<Map<String, dynamic>> list = [];
    for (final entry in entryList) {
      var mapper = locator.get<MainFactory>().entryValueToMap(entry.type);
      list.add(entry.toMap(mapper));
    }
    return {'entries': list};
  }

  factory CompositeLog.fromMap(Map<String, dynamic> map) {
    List<Map<String, dynamic>> mapList = List<Map<String, dynamic>>.from(map['entries']);
    List<CompositeEntry> generatedList = [];
    for (final entryMap in mapList) {
      LoggableType type = LoggableTypeHelper.fromString(entryMap['type']);
      final mapper = locator.get<MainFactory>().entryValueFromMap(type);

      generatedList.add(CompositeEntry.fromMap(entryMap, mapper));
    }
    return CompositeLog(entryList: generatedList.lock);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is CompositeLog &&
      other.entryList == entryList;
  }

  @override
  int get hashCode => entryList.hashCode;
}

abstract class CompositeEntry {
  String loggableId;
  LoggableType type;
  CompositeEntry({
    required this.loggableId,
    required this.type,
  });

  R when<R>(
      {required R Function(CompositeSingleEntry) singleEntry,
      required R Function(CompositeMultiEntry) multiEntry});

  Map<String, dynamic> toMap(ValueToMap? valueToMap);

  factory CompositeEntry.fromMap(Map<String, dynamic> map, ValueFromMap? valueFromMap) {
    // multi saves with {... values: [x,x,x]}
    // single saves with {... value: x}
    if (map['values'] != null) {
      return CompositeMultiEntry.fromMap(map, valueFromMap);
    } else {
      return CompositeSingleEntry.fromMap(map, valueFromMap);
    }
  }
}

class CompositeSingleEntry<T> extends CompositeEntry {
  dynamic value;
  CompositeSingleEntry({
    required String loggableId,
    required LoggableType type,
    required this.value,
  }) : super(loggableId: loggableId, type: type);

  CompositeSingleEntry copyWith({
    String? loggableId,
    LoggableType? type,
    T? value,
  }) {
    return CompositeSingleEntry(
      loggableId: loggableId ?? this.loggableId,
      type: type ?? this.type,
      value: value ?? this.value,
    );
  }

  @override
  R when<R>(
      {required R Function(CompositeSingleEntry) singleEntry,
      required R Function(CompositeMultiEntry) multiEntry}) {
    return singleEntry(this);
  }

  @override
  Map<String, dynamic> toMap(ValueToMap? valueToMap) {
    return {
      'loggableId': loggableId,
      'type': type.toString(),
      'value': valueToMap == null ? value : valueToMap(value),
    };
  }

  factory CompositeSingleEntry.fromMap(Map<String, dynamic> map, ValueFromMap? valueFromMap) {
    return CompositeSingleEntry<T>(
      loggableId: map['loggableId'],
      type: LoggableTypeHelper.fromString(map['type']),
      value: valueFromMap?.call(map['value']) ?? map['value'],
    );
  }

  @override
  String toString() => 'CompositeSingleEntry(loggableId: $loggableId, type: $type, value: $value)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CompositeSingleEntry<T> &&
        other.loggableId == loggableId &&
        other.type == type &&
        other.value == value;
  }

  @override
  int get hashCode => loggableId.hashCode ^ type.hashCode ^ value.hashCode;
}

class CompositeMultiEntry extends CompositeEntry {
  IList<dynamic> values;
  CompositeMultiEntry({
    required String loggableId,
    required LoggableType type,
    required this.values,
  }) : super(loggableId: loggableId, type: type);

  @override
  R when<R>(
      {required R Function(CompositeSingleEntry) singleEntry,
      required R Function(CompositeMultiEntry) multiEntry}) {
    return multiEntry(this);
  }

  @override
  Map<String, dynamic> toMap(ValueToMap? valueToMap) {
    return {
      'loggableId': loggableId,
      'type': type.toString(),
      'values': valueToMap == null ? values.unlock : values.map((val) => valueToMap(val)).toList(),
    };
  }

  factory CompositeMultiEntry.fromMap(Map<String, dynamic> map, ValueFromMap? valueFromMap) {
    List<dynamic> values =
        valueFromMap == null ? map['values'] : map['values'].map((e) => valueFromMap(e)).toList();
    return CompositeMultiEntry(
      loggableId: map['loggableId'],
      type: LoggableTypeHelper.fromString(map['type']),
      values: values.lock,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CompositeMultiEntry && other.values == values;
  }

  @override
  int get hashCode => values.hashCode;
}
