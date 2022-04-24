
// start time and end time are unix timestamp in seconds
import 'package:super_logger/core/models/mappable_object.dart';

abstract class DurationLog implements MappableObject {
  final int seconds;
  Duration get duration => Duration(seconds: seconds);
  String get formattedDuration =>
      (duration.inHours > 0 ? duration.inHours.toString().padLeft(2, '0') + ":" : "") +
      duration.inMinutes.remainder(60).toString().padLeft(2, '0') +
      ":" +
      duration.inSeconds.remainder(60).toString().padLeft(2, '0');

  DurationLog({
    required this.seconds,
  });

  //void when () {}

  factory DurationLog.createRunningDuration() {
    return RunningDuration._(seconds: 0, startTime: DateTime.now().millisecondsSinceEpoch ~/ 1000);
  }

  factory DurationLog.createFinishedDuration(int duration) {
    return FinishedDuration._(seconds: duration);
  }

  factory DurationLog.paused(RunningDuration runningDuration) {
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return PausedDuration._(seconds: now - runningDuration.startTime + runningDuration.seconds);
  }

  factory DurationLog.resumed(PausedDuration pausedDuration) {
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return RunningDuration._(startTime: now, seconds: pausedDuration.seconds);
  }

  factory DurationLog.finished(DurationLog durationLogValue) {
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (durationLogValue is RunningDuration) {
      return FinishedDuration._(
          seconds: now - durationLogValue.startTime + durationLogValue.seconds);
    } else if (durationLogValue is PausedDuration) {
      return FinishedDuration._(seconds: durationLogValue.seconds);
    } else {
      return durationLogValue;
    }
  }

  factory DurationLog.fromJson(Map<String, dynamic> json) {
    int? startTime = json['startTime'];
    int duration = json['seconds'];
    bool? paused = json['paused'];

    // running
    if (startTime != null) {
      return RunningDuration._(seconds: duration, startTime: startTime);
    }
    // paused
    else if (paused != null && paused) {
      return PausedDuration._(seconds: duration);
    }
    // finished
    else {
      return FinishedDuration._(seconds: duration);
    }
  }

  @override
  String toString() => '$seconds';
}

class RunningDuration extends DurationLog {
  int startTime;
  RunningDuration._({
    required int seconds,
    required this.startTime,
  }) : super(seconds: seconds);

  @override
  Map<String, dynamic> toJson() => {'seconds': seconds, 'startTime': startTime};

  @override
  Duration get duration =>
      Duration(seconds: seconds + (DateTime.now().millisecondsSinceEpoch ~/ 1000) - startTime);
}

class PausedDuration extends DurationLog {
  PausedDuration._({
    required int seconds,
  }) : super(seconds: seconds);

  @override
  Map<String, dynamic> toJson() => {'seconds': seconds, 'paused': true};
}

class FinishedDuration extends DurationLog {
  FinishedDuration._({
    required int seconds,
  }) : super(seconds: seconds);

  @override
  Map<String, dynamic> toJson() => {'seconds': seconds};
}
