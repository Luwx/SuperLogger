import 'package:flutter/material.dart';
import 'package:super_logger/features/color/models/color_log.dart';

class DisplayColor extends StatelessWidget {
  const DisplayColor(this.colorLog,
      {Key? key, this.valid = true, this.size, this.onTap, this.hasShadow = true, this.fontSize})
      : super(key: key);
  final ColorLog colorLog;
  final bool valid;
  final double? size;
  final void Function(ColorLog selectedColor)? onTap;
  final bool hasShadow;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorLog.label.isNotEmpty ? colorLog.color.withAlpha(30) : null,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColorCircle(colorLog, valid: valid, size: size, onTap: onTap, hasShadow: true),
          if (colorLog.label.isNotEmpty) ...[
            const SizedBox(
              width: 8,
            ),
            Text(
              colorLog.label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                  fontSize: fontSize ?? 12,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic),
            ),
            const SizedBox(
              width: 12,
            ),
          ]
        ],
      ),
    );
  }
}

class ColorCircle extends StatelessWidget {
  const ColorCircle(
    this.colorLog, {
    Key? key,
    this.valid = true,
    this.size,
    this.onTap,
    this.hasShadow = true,
  }) : super(key: key);
  final ColorLog colorLog;
  final bool valid;
  final double? size;
  final void Function(ColorLog selectedColor)? onTap;
  final bool hasShadow;

  @override
  Widget build(BuildContext context) {
    final double max = size ?? 46;
    final double borderRadius = max / 2;
    final double padding = hasShadow ? 2 : 1;
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Container(
        width: max - padding * 2,
        height: max - padding * 2,
        decoration: BoxDecoration(
            color: colorLog.color,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: !hasShadow
                ? null
                : [
                    const BoxShadow(
                        // color: color.withOpacity(0.8),
                        color: Colors.black12,
                        //offset: const Offset(0, 0),
                        blurRadius: 2.0,
                        blurStyle: BlurStyle.outer)
                  ]),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashFactory: InkRipple.splashFactory,
            onTap: onTap != null ? () => onTap!(colorLog) : null,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
