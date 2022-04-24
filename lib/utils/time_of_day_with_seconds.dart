import 'package:flutter/material.dart';

@immutable
class TimeOfDayWithSeconds {
  /// Creates a time of day.
  ///
  /// The [hour] argument must be between 0 and 23, inclusive. The [minute]
  /// argument must be between 0 and 59, inclusive.
  const TimeOfDayWithSeconds({required this.hour, required this.minute, required this.second});

  /// Creates a time of day based on the given time.
  ///
  /// The [hour] is set to the time's hour and the [minute] is set to the time's
  /// minute in the timezone of the given [DateTime].
  TimeOfDayWithSeconds.fromDateTime(DateTime time)
      : hour = time.hour,
        minute = time.minute,
        second = time.second;

  /// Creates a time of day based on the current time.
  ///
  /// The [hour] is set to the current hour and the [minute] is set to the
  /// current minute in the local time zone.
  factory TimeOfDayWithSeconds.now() {
    return TimeOfDayWithSeconds.fromDateTime(DateTime.now());
  }

  /// The number of hours in one day, i.e. 24.
  static const int hoursPerDay = 24;

  /// The number of hours in one day period (see also [DayPeriod]), i.e. 12.
  static const int hoursPerPeriod = 12;

  /// The number of minutes in one hour, i.e. 60.
  static const int minutesPerHour = 60;

  /// The number of seconds in one minute, i.e. 60.
  static const int secondsPerMinute = 60;

  /// Returns a new TimeOfDay with the hour and/or minute replaced.
  TimeOfDayWithSeconds replacing({int? hour, int? minute, int? second}) {
    assert(hour == null || (hour >= 0 && hour < hoursPerDay));
    assert(minute == null || (minute >= 0 && minute < minutesPerHour));
    assert(second == null || (second >= 0 && second < secondsPerMinute));
    return TimeOfDayWithSeconds(
        hour: hour ?? this.hour, minute: minute ?? this.minute, second: second ?? this.second);
  }

  /// The selected hour, in 24 hour time from 0..23.
  final int hour;

  /// The selected minute.
  final int minute;

  /// The selected second.
  final int second;

  /// Whether this time of day is before or after noon.
  DayPeriod get period => hour < hoursPerPeriod ? DayPeriod.am : DayPeriod.pm;

  /// Which hour of the current period (e.g., am or pm) this time is.
  int get hourOfPeriod => hour - periodOffset;

  /// The hour at which the current period starts.
  int get periodOffset => period == DayPeriod.am ? 0 : hoursPerPeriod;

  String get hourString => hour.toString().padLeft(2, '0');

  String get minuteString => minute.toString().padLeft(2, '0');

  String get secondString => second.toString().padLeft(2, '0');

  /// Returns the localized string representation of this time of day.
  ///
  /// This is a shortcut for [MaterialLocalizations.formatTimeOfDay].
  String format(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(
      TimeOfDay(hour: hour, minute: minute),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
  }

  TimeOfDay toTimeOfDay() {
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  bool operator ==(Object other) {
    return other is TimeOfDayWithSeconds &&
        other.hour == hour &&
        other.minute == minute &&
        other.second == second;
  }

  @override
  int get hashCode => hashValues(hour, minute, second);

  @override
  String toString() {
    String _addLeadingZeroIfNeeded(int value) {
      if (value < 10) return '0$value';
      return value.toString();
    }

    final String hourLabel = _addLeadingZeroIfNeeded(hour);
    final String minuteLabel = _addLeadingZeroIfNeeded(minute);
    final String secondLabel = _addLeadingZeroIfNeeded(second);

    return '$TimeOfDayWithSeconds($hourLabel:$minuteLabel:$secondLabel)';
  }
}
