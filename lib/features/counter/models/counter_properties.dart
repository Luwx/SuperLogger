import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:super_logger/core/models/mappable_object.dart';

part 'counter_properties.freezed.dart';

enum AddButtonBehavior { defaultAction, addDialog }
enum MinusButtonBehavior { deleteLastEntry, minusOne }

@freezed
class CounterProperties with _$CounterProperties implements MappableObject {
  const CounterProperties._();

  const factory CounterProperties({
    required String prefix,
    required String suffix,
    required bool positiveOnly,
    required bool unitary,
    required bool showMinusButton,
    required MinusButtonBehavior minusButtonBehavior,
    required AddButtonBehavior addButtonBehavior,
    required IList<int> addButtonDialogValues,
  }) = _CounterProperties;

  @override
  Map<String, dynamic> toJson() {
    return {
      'prefix': prefix,
      'suffix': suffix,
      'positiveOnly': positiveOnly,
      'unitary': unitary,
      'showMinusButton': showMinusButton,
      'minusButtonBehavior': minusButtonBehavior.index,
      'addButtonBehavior': addButtonBehavior.index,
      'addButtonDialogValues': addButtonDialogValues.unlock,
    };
  }

  static CounterProperties fromJson(Map<String, dynamic> map) {
    return CounterProperties(
      prefix: map['prefix'],
      suffix: map['suffix'],
      positiveOnly: map['positiveOnly'],
      unitary: map['unitary'],
      showMinusButton: map['showMinusButton'],
      minusButtonBehavior: MinusButtonBehavior.values[map['minusButtonBehavior']],
      addButtonBehavior: AddButtonBehavior.values[map['addButtonBehavior']],
      addButtonDialogValues: List<int>.from(map['addButtonDialogValues']).lock,
    );
  }

  factory CounterProperties.defaults() {
    return CounterProperties(
        suffix: "",
        prefix: "",
        positiveOnly: true,
        unitary: false,
        showMinusButton: true,
        minusButtonBehavior: MinusButtonBehavior.deleteLastEntry,
        addButtonBehavior: AddButtonBehavior.defaultAction,
        addButtonDialogValues: [1].lock);
  }
}