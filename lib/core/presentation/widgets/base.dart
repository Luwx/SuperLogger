import 'package:flutter/material.dart';

// Widgets that will be used by various categories

class CardDetailsLogBase extends StatelessWidget {
  const CardDetailsLogBase({Key? key, this.details}) : super(key: key);

  final Widget? details;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        const Divider(),
        if (details == null)
          const Padding(
            padding: EdgeInsets.all(4.0),
            child: Center(child: Text("No entries")),
          )
        else
        details!
          /*AnimatedSwitcher(
            duration: kThemeAnimationDuration,
            child: Column(
              key: UniqueKey(),
              children: details!,
            ),
          )*/
      ],
    );
  }
}
