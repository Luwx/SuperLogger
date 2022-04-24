import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:super_logger/core/loggables_types.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension DateHelpers on DateTime {
  String get asISO8601 =>
      year.toString() +
      "-" +
      month.toString().padLeft(2, '0') +
      "-" +
      day.toString().padLeft(2, '0');
  String get formattedTimeHMS =>
      hour.toString().padLeft(2, '0') +
      ":" +
      minute.toString().padLeft(2, '0') +
      ":" +
      second.toString().padLeft(2, '0');

  String get formattedTimeHM =>
      hour.toString().padLeft(2, '0') + ":" + minute.toString().padLeft(2, '0');
  bool get isToday {
    DateTime now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  static int numOfWeeks(int year) {
    DateTime dec28 = DateTime(year, 12, 28);
    int dayOfDec28 = int.parse(DateFormat("D").format(dec28));
    return ((dayOfDec28 - dec28.weekday + 10) / 7).floor();
  }

  /// Calculates week number from a date as per https://en.wikipedia.org/wiki/ISO_week_date#Calculation
  int get weekNumber {
    int dayOfYear = int.parse(DateFormat("D").format(this));
    int weekOfYear = ((dayOfYear - weekday + 10) / 7).floor();
    if (weekOfYear < 1) {
      weekOfYear = numOfWeeks(year - 1);
    } else if (weekOfYear > numOfWeeks(year)) {
      weekOfYear = 1;
    }
    return weekOfYear;
  }

  // static DateTime fromSecondsSinceEpoch(int seconds) {
  //   return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  // }

  //int get secondsSinceEpoch => millisecondsSinceEpoch ~/ 1000;
}

// extension Time on int {
//   DateTime get dateTimeFromSecondsSinceEpoch => DateTime.fromMillisecondsSinceEpoch(this * 1000);
// }

extension EmailValidator on String {
  bool isValidEmail() {
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(this);
  }
}

extension DoubleExtension on double {
  double roundDouble(int precision) {
    double mod = pow(10.0, precision) as double;
    return ((this * mod).round().toDouble() / mod);
  }

  String get formatWithPrecision4 => toStringAsFixed(4).replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), '');
}

extension LoggableTypeHelper on LoggableType {
  static LoggableType fromString(String value) =>
      LoggableType.values.firstWhere((type) => type.toString() == value);
}

extension ContextHelpers on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  ColorScheme get colors => Theme.of(this).colorScheme;
}

// extension Let<T> on T {
//   R let<R>(R Function(T) block) => block(this);
// }



// extension _Let<T> on T {
//   U let<U>(U Function(T) block) => block(this);
// }