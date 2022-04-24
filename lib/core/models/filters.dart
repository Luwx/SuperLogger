import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/models/log.dart';

part 'filters.freezed.dart';

abstract class ValueFilter<T> {
  bool shouldRemove(T value);
}

abstract class DateLogFilter<T> {
  bool shouldRemove(DateLog<T> log);
}

@freezed
class NullableDateLimits with _$NullableDateLimits {
  const factory NullableDateLimits({DateTime? maxDate, DateTime? minDate}) = _NullableDateLimits;
}

@freezed
class DateLimits with _$DateLimits {
  const factory DateLimits({required DateTime maxDate, required DateTime minDate}) = _DateLimits;
}

class NumFilterOutLargerThan implements ValueFilter<num> {
  final num val;
  NumFilterOutLargerThan(this.val);
  @override
  bool shouldRemove(num value) {
    return value > val;
  }
}

class NumFilterOutLessThan implements ValueFilter<num> {
  final num val;
  NumFilterOutLessThan(this.val);
  @override
  bool shouldRemove(num value) {
    return value < val;
  }
}

class NumFilterOutNotEqualTo implements ValueFilter<num> {
  final num val;
  NumFilterOutNotEqualTo(this.val);
  @override
  bool shouldRemove(num value) {
    return value != val;
  }
}

class NumFilterOutNotInBetween implements ValueFilter<num> {
  final num max;
  final num min;
  NumFilterOutNotInBetween(this.max, this.min);
  @override
  bool shouldRemove(num value) {
    return value <= min || value >= max;
  }
}
