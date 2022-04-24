import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/models/log.dart';

import 'package:super_logger/features/duration/models/duration_log.dart';
import 'package:super_logger/features/duration/models/duration_properties.dart';
import 'package:super_logger/utils/id_generator.dart';

class PlayPauseStopButtonMainCardWrapper extends StatefulWidget {
  const PlayPauseStopButtonMainCardWrapper({
    Key? key,
    required this.controller,
    required this.onTap,
  }) : super(key: key);
  final LoggableController controller;
  final VoidCallback onTap;
  @override
  _PlayPauseStopButtonMainCardWrapperState createState() =>
      _PlayPauseStopButtonMainCardWrapperState();
}

class _PlayPauseStopButtonMainCardWrapperState extends State<PlayPauseStopButtonMainCardWrapper> {
  @override
  void initState() {
    super.initState();
    //widget.controller.setupDateLogStream();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Log>>(
      //animation: widget.controller,
      stream: widget.controller.getAllLogsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        final dateLogList = snapshot.data;
        if (dateLogList == null) {
          return const CircularProgressIndicator();
        }
        final activeLog = findActiveLog(dateLogList);
        return PlayPauseStopButton(
          canCreateDuration: true,
          properties: widget.controller.loggable.loggableProperties as DurationProperties,
          duration: activeLog?.value,
          onDurationFinished: widget.controller.isBusy
              ? null
              : (finishedDuration) => widget.controller.updateLog(
                    activeLog!,
                    Log<DurationLog>(
                        id: activeLog.id,
                        timestamp: DateTime.now(),
                        value: finishedDuration,
                        note: activeLog.note),
                  ),
          onDurationResumed: widget.controller.isBusy
              ? null
              : (runningDuration) => widget.controller.updateLog(
                    activeLog!,
                    Log<RunningDuration>(
                        id: activeLog.id,
                        timestamp: activeLog.timestamp,
                        value: runningDuration,
                        note: activeLog.note),
                  ),
          onDurationPaused: widget.controller.isBusy
              ? null
              : (pausedDuration) => widget.controller.updateLog(
                  activeLog!,
                  Log<PausedDuration>(
                      id: activeLog.id,
                      timestamp: activeLog.timestamp,
                      value: pausedDuration,
                      note: activeLog.note)),
          onRunningDurationCreated: widget.controller.isBusy
              ? null
              : (newLog) => widget.controller.addLog(Log<RunningDuration>(
                    id: generateId(),
                    timestamp: DateTime.now(),
                    value: newLog,
                    note: "",
                  )),
        );
      },
    );
  }
}

class PlayPauseStopButton extends StatefulWidget {
  const PlayPauseStopButton({
    Key? key,
    required this.properties,
    required this.duration,
    required this.onRunningDurationCreated,
    required this.onDurationPaused,
    required this.onDurationResumed,
    required this.onDurationFinished,
    required this.canCreateDuration,
  }) : super(key: key);
  final DurationProperties properties;
  final DurationLog? duration;
  final void Function(RunningDuration createdDuration)? onRunningDurationCreated;
  final void Function(PausedDuration pausedDuration)? onDurationPaused;
  final void Function(RunningDuration resumedDuration)? onDurationResumed;
  final void Function(FinishedDuration finishedDuration)? onDurationFinished;
  final bool canCreateDuration;

  @override
  _PlayPauseStopButtonState createState() => _PlayPauseStopButtonState();
}

class _PlayPauseStopButtonState extends State<PlayPauseStopButton>
    with SingleTickerProviderStateMixin {
  late AnimationController iconAnimationController;

  bool _canBePaused() {
    return true;
    //return widget.properties.canBePaused;
  }

  // wrap callbacks with nullable functions
  VoidCallback? _setFinished(DurationLog duration) {
    if (widget.onRunningDurationCreated != null) {
      return () => widget.onDurationFinished!(
            DurationLog.finished(duration) as FinishedDuration,
          );
    } else {
      return null;
    }
  }

  VoidCallback? _onCreateDuration() {
    if (widget.onRunningDurationCreated != null && widget.canCreateDuration) {
      return () => widget.onRunningDurationCreated!(
            DurationLog.createRunningDuration() as RunningDuration,
          );
    } else {
      return null;
    }
  }

  VoidCallback? _onAnimatedIconPressedFunction(DurationLog? duration) {
    if (duration == null || duration is FinishedDuration) {
      return _onCreateDuration();
    } else if (duration is RunningDuration) {
      if (widget.onDurationPaused != null) {
        return () => widget.onDurationPaused!(DurationLog.paused(duration) as PausedDuration);
      }
    } else if (duration is PausedDuration) {
      if (widget.onDurationPaused != null) {
        return () => widget.onDurationResumed!(DurationLog.resumed(duration) as RunningDuration);
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    iconAnimationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    iconAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.duration == null) {
      iconAnimationController.reverse();
    } else if (widget.duration! is RunningDuration) {
      iconAnimationController.forward();
    } else if (widget.duration! is PausedDuration) {
      iconAnimationController.reverse();
    } else if (widget.duration! is FinishedDuration) {
      iconAnimationController.reverse();
    }

    final showStopButton = widget.duration != null && (widget.duration is! FinishedDuration);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _canBePaused()
            ? IconButton(
                icon: AnimatedIcon(
                  icon: AnimatedIcons.play_pause,
                  progress: iconAnimationController,
                ),
                onPressed: _onAnimatedIconPressedFunction(widget.duration),
              )
            : IconButton(
                onPressed:
                    widget.duration == null ? _onCreateDuration() : _setFinished(widget.duration!),
                icon: AnimatedSwitcher(
                    child: widget.duration == null
                        ? const Icon(
                            Icons.play_arrow,
                            key: ValueKey("play"),
                          )
                        : const Icon(Icons.stop, key: ValueKey("stop"), color: Colors.redAccent),
                    duration: kThemeAnimationDuration),
              ),
        if (_canBePaused())
          AnimatedSize(
            duration: kThemeAnimationDuration,
            curve: Curves.easeInOutCubic,
            child: AnimatedOpacity(
              opacity: showStopButton ? 1 : 0,
              duration: kThemeAnimationDuration,
              child: AnimatedScale(
                duration: kThemeAnimationDuration,
                scale: showStopButton ? 1 : 0.5,
                child: showStopButton
                    ? IconButton(
                        onPressed: _setFinished(widget.duration!),
                        icon: const Icon(
                          Icons.stop,
                          color: Colors.redAccent,
                        ))
                    : const SizedBox.shrink(),
              ),
            ),
          ),
      ],
    );
  }
}

class PlayPauseButtonForComposite extends StatefulWidget {
  const PlayPauseButtonForComposite(
      {Key? key, required this.isRunning, required this.onPause, required this.onResume})
      : super(key: key);
  final bool isRunning;
  final VoidCallback onResume;
  final VoidCallback onPause;

  @override
  _PlayPauseButtonForCompositeState createState() => _PlayPauseButtonForCompositeState();
}

class _PlayPauseButtonForCompositeState extends State<PlayPauseButtonForComposite>
    with SingleTickerProviderStateMixin {
  late AnimationController iconAnimationController;

  @override
  void initState() {
    super.initState();
    iconAnimationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isRunning) {
      iconAnimationController.forward();
    } else {
      iconAnimationController.reverse();
    }

    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.play_pause,
        progress: iconAnimationController,
      ),
      onPressed: widget.isRunning ? widget.onPause : widget.onResume,
    );
  }
}

// active: running or paused
Log<DurationLog>? findActiveLog(List<Log> logs) {
  for (final log in logs) {
    final logVal = (log as Log<DurationLog>).value;
    if (logVal is RunningDuration || logVal is PausedDuration) {
      return log;
    }
  }

  return null;
}
