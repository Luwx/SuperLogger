import 'dart:async';

import 'package:flutter/material.dart';
import 'package:super_logger/features/duration/models/duration_log.dart';

class DisplayDuration extends StatefulWidget {
  const DisplayDuration({
    Key? key,
    required this.duration,
    this.textColor,
    required this.textSize,
  }) : super(key: key);
  final Color? textColor;
  final int textSize;

  final DurationLog duration;

  @override
  _DisplayDurationState createState() => _DisplayDurationState();
}

class _DisplayDurationState extends State<DisplayDuration> {
  late final Timer _timer;

  void _updateCurrentDuration() {
    if (widget.duration is RunningDuration) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCurrentDuration());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.duration.formattedDuration,
      style: TextStyle(
        color: widget.textColor ?? (widget.duration is RunningDuration ? Colors.red : null),
        fontSize: widget.textSize.toDouble(),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
