import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ValueShimmer extends StatelessWidget {
  const ValueShimmer({
    Key? key,
    required this.height,
  }) : super(key: key);

  final double height;

  @override
  Widget build(BuildContext context) {
    Color baseColor =
        Color.lerp(Theme.of(context).primaryColor, Theme.of(context).colorScheme.onPrimary, 0.5)!;
    Color highLightColor =
        Color.lerp(Theme.of(context).primaryColor, Theme.of(context).colorScheme.onPrimary, 0.8)!;
    return Shimmer.fromColors(
      highlightColor: highLightColor,
      period: kThemeAnimationDuration * 3,
      baseColor: baseColor,
      child: LayoutBuilder(builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth / 4,
          // I'll break the rule here, we should not depend on any loggable implementation in the core
          height: height,
          decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4)),
        );
      }),
    );
  }
}
