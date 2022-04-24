import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/models/log.dart';

class AnimatedLogDetailList extends StatefulWidget {
  const AnimatedLogDetailList(
      {Key? key, required this.dateLog, required this.maxEntries, this.mapper})
      : super(key: key);
  final DateLog dateLog;
  final int maxEntries;
  final Widget Function(BuildContext context, Log log)? mapper;

  @override
  State<AnimatedLogDetailList> createState() => _AnimatedLogDetailListState();
}

class _AnimatedLogDetailListState extends State<AnimatedLogDetailList> {
  bool _reverse = false;
  Log? _lastLog;
  Log? _previousLastLog;

  @override
  void didUpdateWidget(covariant AnimatedLogDetailList oldWidget) {
    _lastLog = widget.dateLog.logs.isNotEmpty ? widget.dateLog.logs.last : null;
    _previousLastLog = oldWidget.dateLog.logs.isNotEmpty ? oldWidget.dateLog.logs.last : null;
    if (oldWidget.dateLog.logs.length > widget.dateLog.logs.length) {
      if (_lastLog != null && _previousLastLog != null && _lastLog!.id != _previousLastLog!.id) {
        _reverse = true;
      }
    } else {
      _reverse = false;
    }
    super.didUpdateWidget(oldWidget);
  }

  Container _generateRow(BuildContext context, int index, Log log) {
    final timeStyle = Theme.of(context).textTheme.caption ?? TextStyle(color: Colors.blueGrey[700]);
    return Container(
      //key: ValueKey(log.formattedTime),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      decoration: BoxDecoration(
        color: index % 2 == 0
            ? Colors.transparent
            : Theme.of(context).colorScheme.primary.withAlpha(10),
        borderRadius: const BorderRadius.all(
          Radius.circular(8),
        ),
      ),
      child: Row(
        //mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment:
            widget.mapper != null ? CrossAxisAlignment.center : CrossAxisAlignment.end,
        children: <Widget>[
          Text((index + 1).toString() + "     ", style: timeStyle),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: widget.mapper != null
                ? widget.mapper!(context, log)
                : Text(/*countAtIndexForDate(date, index).toString()*/ log.value.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ),
          Text(log.formattedTime, style: timeStyle),
          // TweenAnimationBuilder<double>(
          //     tween: Tween<double>(begin: 0, end: 1.0),
          //     duration: kThemeAnimationDuration * 1.5,
          //     builder: (context, val, child) {
          //       return Container(
          //         color: Theme.of(context)
          //             .colorScheme
          //             .primary
          //             .withAlpha(val < 0.5 ? (160 * val).toInt() : (160 * (1 - val)).toInt()),
          //         child: Text(log.formattedTime, style: timeStyle),
          //       );
          //     })
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> logDetailList = [];

    int total = 0;
    for (int i = (widget.dateLog.logs.length - 1); i >= 0; i--) {
      Log log = widget.dateLog.logs[i];
      if (total >= widget.maxEntries) {
        logDetailList.add(TranslateAnimation(
          reverse: !_reverse,
          fade: true,
          key: ValueKey(log.id + "exit"),
          duration: 400,
          offset: const Offset(0, 10),
          child: _generateRow(context, i, log),
        ));
        break;
      }
      total++;

      if (i == widget.dateLog.logs.length - 1) {
        // deleted value exit animation
        if (_reverse && _previousLastLog != null) {
          total++;
          logDetailList.add(TranslateAnimation(
            reverse: true,
            fade: true,
            key: ValueKey(_previousLastLog!.id + "old"),
            duration: 400,
            offset: const Offset(-20, 0),
            child: _generateRow(context, i + 1, _previousLastLog!),
          ));
          logDetailList.add(_generateRow(context, i, log));
        } else {
          logDetailList.add(TranslateAnimation(
            reverse: _reverse,
            fade: true,
            key: ValueKey(log.id + "new"),
            duration: 400,
            offset: const Offset(-20, 0),
            child: _generateRow(context, i, log),
          ));
        }
      } else {
        logDetailList.add(_generateRow(context, i, log));
      }
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...logDetailList,
        AnimatedCrossFade(
          firstChild: PageTransitionSwitcher(
            duration: const Duration(milliseconds: 400),
            child: widget.dateLog.logs.length > widget.maxEntries
                ? Container(
                    key: ValueKey(widget.dateLog.logs.length - widget.maxEntries),
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text("+" + (widget.dateLog.logs.length - widget.maxEntries).toString(),
                            style: TextStyle(color: Colors.green[700]))
                      ],
                    ),
                  )
                : const SizedBox(),
            transitionBuilder: (child, animation, secondaryAnimation) {
              return SharedAxisTransition(
                fillColor: Colors.transparent,
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                child: child,
                transitionType: SharedAxisTransitionType.scaled,
              );
            },
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: widget.dateLog.logs.length > widget.maxEntries
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeOutQuad,
        )
      ],
    );
  }
}

class TranslateAnimation extends StatelessWidget {
  const TranslateAnimation(
      {Key? key,
      required this.child,
      required this.offset,
      this.initialDelay = 0,
      this.duration = 1600,
      this.reverse = false,
      this.fade = false})
      : super(key: key);

  final Widget child;
  final bool reverse;
  final int initialDelay;
  final int duration;
  final Offset offset;
  final bool fade;

  @override
  Widget build(BuildContext context) {
    final totalTime = initialDelay + duration;
    final initialTimePercent = initialDelay.toDouble() / (totalTime.toDouble());
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reverse ? 0 : 1, end: reverse ? 1 : 0),
      duration: Duration(milliseconds: totalTime),
      //curve: Curves.easeInOutBack,
      curve: Interval(initialTimePercent, 1, curve: Curves.easeInOutBack),
      builder: (context, value, child) {
        return Align(
          heightFactor: (1 - value).clamp(0, 2),
          child: Transform.translate(
            offset: Offset(offset.dx * value, offset.dy * value),
            child: !fade
                ? child
                : Opacity(
                    opacity: 1 - value.clamp(0, 1),
                    child: child,
                  ),
          ),
        );
      },
      child: child,
    );
  }
}
