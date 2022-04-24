import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:super_logger/features/composite/interfaces/computable_loggable.dart';

import 'package:super_logger/features/composite/models/composite_log.dart';
import 'package:super_logger/features/composite/models/composite_properties.dart';

enum NumericCalculationType { aggregation, operation }

enum NumericAggregationType { min, max, count }

enum NumericOperationType { add, subtract, multiply, divide }

enum ComputableOrigin { loggable, rawValue, computable }

abstract class NumericAggregation {
  NumericAggregationType get type;
  num call(List<num> list);
}

abstract class NumericOperation {
  NumericOperationType get type;
  double call(double a, double b);
}

NumericOperation getOperation(NumericOperationType type) {
  switch (type) {
    case NumericOperationType.add:
      return AddOperation();
    case NumericOperationType.subtract:
      return SubtractOperation();
    case NumericOperationType.multiply:
      return MultiplyOperation();
    case NumericOperationType.divide:
      return DivideOperation();
  }
}

class Computable {
  final String? _id;
  final double? _value;
  final String? _computationName;
  final ComputableOrigin _origin;
  Computable._(this._id, this._value, this._computationName, this._origin);
  factory Computable.fromValue(double value) =>
      Computable._(null, value, null, ComputableOrigin.rawValue);
  factory Computable.fromLoggableId(String id) =>
      Computable._(id, null, null, ComputableOrigin.loggable);
  factory Computable.fromComputation(String name) =>
      Computable._(null, null, name, ComputableOrigin.computable);

  R when<R>(
      {required R Function(String) loggableId,
      required R Function(double) value,
      required R Function(String) computation}) {
    if (_id != null) {
      return loggableId(_id!);
    } else if (_value != null) {
      return value(_value!);
    } else {
      return computation(_computationName!);
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {'origin': _origin.name};
    switch (_origin) {
      case ComputableOrigin.loggable:
        map.putIfAbsent('value', () => _id);
        break;
      case ComputableOrigin.rawValue:
        map.putIfAbsent('value', () => _value);
        break;
      case ComputableOrigin.computable:
        map.putIfAbsent('value', () => _computationName);
        break;
    }
    return map;
  }

  factory Computable.fromJson(Map<String, dynamic> json) {
    final origin = ComputableOrigin.values.firstWhere((element) => element.name == json['origin']);
    switch (origin) {
      case ComputableOrigin.loggable:
        return Computable.fromLoggableId(json['value']);
      case ComputableOrigin.rawValue:
        return Computable.fromValue(json['value']);
      case ComputableOrigin.computable:
        return Computable.fromComputation(json['value']);
    }
  }
}

class CountAggregation implements NumericAggregation {
  @override
  int call(List<num> list) {
    return list.length;
  }

  @override
  NumericAggregationType get type => NumericAggregationType.count;
}

class MaxAggregation implements NumericAggregation {
  @override
  num call(List<num> list) {
    return list.max;
  }

  @override
  NumericAggregationType get type => NumericAggregationType.max;
}

class MinAggregation implements NumericAggregation {
  @override
  num call(List<num> list) {
    return list.min;
  }

  @override
  NumericAggregationType get type => NumericAggregationType.min;
}

class NumericCalculation {
  final String name;
  final String prefix;
  final String suffix;
  final ComputableInformation info;
  final IList<Computable> computables;
  final NumericOperation _operation;

  const NumericCalculation({
    required this.info,
    required this.name,
    required this.computables,
    required this.prefix,
    required this.suffix,
    required NumericOperation operation,
  }) : _operation = operation;

  //double performOperation(double a, double b);

  double? _computeLoggable(ComputableInformation info, double? result, String loggableId,
      CompositeLog log, CompositeProperties properties) {
    final entry = log.entryList.firstWhereOrNull((entry) => entry.loggableId == loggableId);
    if (entry == null) return null;
    return entry.when(
      singleEntry: (singleEntry) {
        // should be either CatType.number or other loggable that has a numeric value
        if (result == null) {
          return singleEntry.value as double;
        } else {
          final nestedProperty =
              properties.loggables.firstWhereOrNull((cat) => cat.id == loggableId);
          if (nestedProperty == null) return null;
          final entryComputableValue = (nestedProperty as ComputableLoggable)
              .getComputableValue(info, properties, singleEntry.value);
          if (entryComputableValue == null) return null;
          return _operation(result, entryComputableValue);
        }
      },
      multiEntry: (multiEntry) {
        // group of values from a numeric loggable
        double? res = result;
        for (final entryValue in multiEntry.values) {
          if (res == null) {
            res = entryValue as double;
          } else {
            res = _operation(res, entryValue);
          }
        }
        return res;
      },
    );
  }

  // returns null when no computable loggable or value is found in the log
  double? performComputation(CompositeLog log, CompositeProperties properties) {
    double? result;
    for (final computable in computables) {
      result = computable.when(
        loggableId: (loggableId) {
          return _computeLoggable(info, result, loggableId, log, properties);
        },
        value: (value) {
          if (result == null) {
            return value;
          } else {
            return _operation(result, value);
          }
        },
        computation: (name) {
          final calc =
              properties.calculations.firstWhereOrNull((calculation) => calculation.name == name);
          return calc?.performComputation(log, properties);
        },
      );
    }
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'computables': computables.map((computable) => computable.toJson()).toList(),
      'type': _operation.type.name
    };
  }

  factory NumericCalculation.fromJson(Map<String, dynamic> map) {
    final computables = (map['computables'] as List)
        .map((computableMap) => Computable.fromJson(computableMap))
        .toIList();

    final operation = getOperation(
      NumericOperationType.values.firstWhere((element) => element.name == map['type']),
    );

    return NumericCalculation(
      info: map['info'],
      computables: computables,
      name: map['name'],
      suffix: map['suffix'],
      prefix: map['prefix'],
      operation: operation,
    );
  }

  factory NumericCalculation.makeEmpty() {
    return NumericCalculation(
      info: EmptyComputableInformation(),
      name: '',
      computables: <Computable>[].lock,
      prefix: '',
      suffix: '',
      operation: getOperation(NumericOperationType.add),
    );
  }
}

class EmptyComputableInformation implements ComputableInformation {
  @override
  // TODO: implement displayInformation
  String get displayInformation => throw UnimplementedError();
}

class AddOperation implements NumericOperation {
  @override
  double call(double a, double b) {
    return a + b;
  }

  @override
  NumericOperationType get type => NumericOperationType.add;
}

class SubtractOperation implements NumericOperation {
  @override
  double call(double a, double b) {
    return a - b;
  }

  @override
  NumericOperationType get type => NumericOperationType.subtract;
}

class MultiplyOperation implements NumericOperation {
  @override
  double call(double a, double b) {
    return a * b;
  }

  @override
  NumericOperationType get type => NumericOperationType.multiply;
}

class DivideOperation implements NumericOperation {
  @override
  double call(double a, double b) {
    return a / b;
  }

  @override
  NumericOperationType get type => NumericOperationType.divide;
}

class G {
  final String name;
  final IList<Computable> computables;
  G({
    required this.name,
    required this.computables,
  });
}
