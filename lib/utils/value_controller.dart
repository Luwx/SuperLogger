import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

//import 'package:super_logger/utils/value_valid_or_error.dart';

class ValueErr<T> {
  final String cause;
  final T invalidValue;
  ValueErr(this.cause, this.invalidValue);
}

class ValueWrapper<T> {
  T value;
  ValueWrapper({
    required this.value,
  });
}

class ValueController<T> extends ChangeNotifier {
  T? _value;
  T get value {
    assert(_value != null, "value cannot be null, is controller set up?");
    return _value!;
  }

  bool get isSetUp => _value != null;

  void setValue(T val) {
    _value = val;
    notifyListeners();
  }

  void setValueSkipNotify(T val) {
    _value = val;
  }
}

class ValueNotifierWithSkip<T> extends ChangeNotifier implements ValueListenable<T> {
  /// Creates a [ChangeNotifier] that wraps this value.
  ValueNotifierWithSkip(this._value);

  /// The current value stored in this notifier.
  ///
  /// When the value is replaced with something that is not equal to the old
  /// value as evaluated by the equality operator ==, this class notifies its
  /// listeners.
  @override
  T get value => _value;
  T _value;
  void setValue(T newValue, {bool notify = true}) {
    if (_value == newValue) return;
    _value = newValue;
    if (notify) notifyListeners();
  }

  @override
  String toString() => '${describeIdentity(this)}($value)';
}

class ValueEitherValidOrErrController<T> extends ValueController<Either<ValueErr<T>, T>> {
  T get valueNoValidation => value.fold((l) => l.invalidValue, (r) => r);
  void setErrorValue(ValueErr<T> valueError) {
    setValue(Left(valueError));
  }

  void setRightValue(T value) {
    setValue(Right(value));
  }
}

class ValueEitherController<T> extends ChangeNotifier {
  bool get isSetUp => _value != null;
  Either<String, T>? _value;
  Either<String, T> get value {
    assert(_value != null, "value cannot be null, is controller set up?");
    return _value!;
  }

  Option<T> _lastValidValue = Option<T>.none();
  Option<T> get lastValidValue => _lastValidValue;

  void setValue(Either<String, T> val, {bool notify = true}) {
    if (val.isLeft() && _value != null && _value!.isLeft()) {
      if (val.getLeft() == _value!.getLeft()) return;
    } else if (val.isRight() && _value != null && _value!.isRight()) {
      if (val.getRight() == _value!.getRight()) return;
    }

    if (_value != null && _value!.isRight()) {
      _lastValidValue = _value!.getRight();
    }
    _value = val;
    if (notify) {
      notifyListeners();
    }
  }

  void setErrorValue(String cause, {bool notify = true}) {
    setValue(Left(cause), notify: notify);
  }

  void setRightValue(T value, {bool notify = true}) {
    setValue(Right(value), notify: notify);
  }
}
