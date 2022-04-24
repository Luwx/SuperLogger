import 'package:flutter/material.dart';

class DevelopmentWarning extends StatelessWidget {
  const DevelopmentWarning({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(24),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.warning_rounded,
              color: Colors.red,
              size: 32,
            ),
            SizedBox(
              width: 12,
            ),
            Text(
              "In development",
              style: TextStyle(color: Colors.red, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
