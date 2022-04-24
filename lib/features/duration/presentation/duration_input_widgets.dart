import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:super_logger/core/presentation/theme/dimensions.dart';
import 'package:super_logger/features/duration/models/duration_log.dart';
import 'package:super_logger/features/duration/models/duration_properties.dart';
import 'package:super_logger/features/duration/presentation/display_duration.dart';
import 'package:super_logger/features/duration/presentation/play_pause_stop_button.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';

class StaticDurationInput extends StatefulWidget {
  const StaticDurationInput({Key? key, this.initialDuration, required this.onChange})
      : super(key: key);
  final VoidCallback onChange;
  final int? initialDuration;

  @override
  _StaticDurationInputState createState() => _StaticDurationInputState();
}

class _StaticDurationInputState extends State<StaticDurationInput> {
  int? _duration;

  @override
  void initState() {
    super.initState();
    _duration = widget.initialDuration;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary.withAlpha(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        splashFactory: InkRipple.splashFactory,
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPickDurationDialog(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          child: Text(_duration?.toString() ?? "no duration"),
        ),
      ),
    );
  }

  Future<void> _showPickDurationDialog(BuildContext context) async {
    final result = await showDialog<Either<EmptyDuration, Duration>>(
      context: context,
      builder: (context) {
        return PickDurationDialog(
          initialDuration: _duration != null ? Duration(seconds: _duration!) : null,
        );
      },
    );
    result?.fold((l) => _duration = null, (r) {
      setState(() {
        _duration = r.inSeconds;
      });
    });
  }
}

class DynamicDurationInput extends StatefulWidget {
  const DynamicDurationInput({
    Key? key,
    required this.valueController,
    required this.properties,
  }) : super(key: key);
  final ValueEitherController<DurationLog> valueController;
  final DurationProperties properties;

  @override
  _DynamicDurationInputState createState() => _DynamicDurationInputState();
}

class _DynamicDurationInputState extends State<DynamicDurationInput> {
  final DurationLog defaultDuration = DurationLog.createFinishedDuration(0);

  void _updateController(DurationLog value) {
    setState(() {
      widget.valueController.setRightValue(value);
    });
  }

  @override
  void initState() {
    super.initState();
    if (!widget.valueController.isSetUp) {
      widget.valueController.setRightValue(DurationLog.createFinishedDuration(0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary.withAlpha(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        child: Row(
          children: [
            DisplayDuration(
              textSize: 16,
              duration: widget.valueController.value.getOrElse((l) => defaultDuration),
            ),
            const SizedBox(
              width: 22,
            ),
            if (widget.properties.usePlayStopButton)
              PlayPauseStopButton(
                  canCreateDuration: false,
                  properties: widget.properties,
                  duration: widget.valueController.value.getOrElse((l) => defaultDuration),
                  onRunningDurationCreated: _updateController,
                  onDurationPaused: _updateController,
                  onDurationResumed: _updateController,
                  onDurationFinished: _updateController)
          ],
        ),
      ),
    );
  }
}

// A different widget is needed for composite,
// since it can not have paused or running state saved in the controller
// we have to implement the running state in a different way
class DurationInputForComposite extends StatefulWidget {
  const DurationInputForComposite(
      {Key? key, required this.valueController, required this.properties, required this.forDialog})
      : super(key: key);
  final ValueEitherController<DurationLog> valueController;
  final DurationProperties properties;
  final bool forDialog;

  @override
  _DurationInputForCompositeState createState() => _DurationInputForCompositeState();
}

class _DurationInputForCompositeState extends State<DurationInputForComposite> {
  late final Timer _timer;
  final DurationLog _defaultDuration = DurationLog.createFinishedDuration(0);
  bool _isRunning = false;

  //final int _duration = 0;

  void _updateCurrentDuration() {
    if (_isRunning) {
      // silently update
      widget.valueController.setRightValue(
        widget.valueController.value.fold(
          (l) => DurationLog.createFinishedDuration(0),
          (r) => DurationLog.createFinishedDuration(r.seconds + 1),
        ),
      );
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCurrentDuration());

    if (widget.valueController.isSetUp) {
      //
    } else {
      widget.valueController.setRightValue(DurationLog.createFinishedDuration(0), notify: false);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
      DisplayDuration(
        textColor: _isRunning ? Colors.redAccent : null,
        textSize: 16,
        duration: widget.valueController.value.getOrElse((l) => _defaultDuration),
      ),
      PlayPauseButtonForComposite(
        isRunning: _isRunning,
        onPause: () => setState(() {
          _isRunning = false;
        }),
        onResume: () => setState(
          () {
            _isRunning = true;
          },
        ),
      )
    ]);
  }
}

class PickDurationDialog extends StatefulWidget {
  const PickDurationDialog({Key? key, this.initialDuration}) : super(key: key);
  final Duration? initialDuration;

  @override
  _PickDurationDialogState createState() => _PickDurationDialogState();
}

class _PickDurationDialogState extends State<PickDurationDialog> {
  final _inputFormatter = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}')),
  ];
  final _textInputType = const TextInputType.numberWithOptions(decimal: false, signed: true);

  int? _days;
  int? _hours;
  int? _minutes;
  int? _seconds;

  @override
  void initState() {
    super.initState();
    _days = widget.initialDuration?.inDays;
    _hours = widget.initialDuration?.inHours.remainder(24);
    _minutes = widget.initialDuration?.inMinutes.remainder(60);
    _seconds = widget.initialDuration?.inSeconds.remainder(60);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.pickDurationLabel),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      actions: <Widget>[
        TextButton(
          child: Text(context.l10n.cancel),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text(context.l10n.ok),
          onPressed: () {
            if (_days == null && _hours == null && _minutes == null && _seconds == null) {
              Navigator.pop(context, Either<EmptyDuration, Duration>.left(EmptyDuration()));
            }
            int totalDurationSeconds = ((_days ?? 0) * 60 * 60 * 24) +
                ((_hours ?? 0) * 60 * 60) +
                ((_minutes ?? 0) * 60) +
                (_seconds ?? 0);
            Navigator.pop(context,
                Either<EmptyDuration, Duration>.of(Duration(seconds: totalDurationSeconds)));
          },
        ),
      ],
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          TextFormField(
            initialValue: _days?.toString(),
            decoration: const InputDecoration(labelText: 'days'),
            keyboardType: _textInputType,
            inputFormatters: _inputFormatter,
            onChanged: (value) {
              if (value.isEmpty) {
                _days = null;
              } else {
                _days = int.parse(value);
              }
            },
          ),
          const SizedBox(height: AppDimens.defaultSpacing),
          TextFormField(
            initialValue: _hours?.toString(),
            decoration: const InputDecoration(labelText: 'hours'),
            keyboardType: _textInputType,
            inputFormatters: _inputFormatter,
            onChanged: (value) {
              if (value.isEmpty) {
                _hours = null;
              } else {
                _hours = int.parse(value);
              }
            },
          ),
          const SizedBox(height: AppDimens.defaultSpacing),
          TextFormField(
            initialValue: _minutes?.toString(),
            decoration: const InputDecoration(labelText: 'minutes'),
            keyboardType: _textInputType,
            inputFormatters: _inputFormatter,
            onChanged: (value) {
              if (value.isEmpty) {
                _minutes = null;
              } else {
                _minutes = int.parse(value);
              }
            },
          ),
          const SizedBox(height: AppDimens.defaultSpacing),
          TextFormField(
            initialValue: _seconds?.toString(),
            decoration: const InputDecoration(labelText: 'seconds'),
            keyboardType: _textInputType,
            inputFormatters: _inputFormatter,
            onChanged: (value) {
              if (value.isEmpty) {
                _seconds = null;
              } else {
                _seconds = int.parse(value);
              }
            },
          ),
        ]),
      ),
    );
  }
}

class EmptyDuration {}
