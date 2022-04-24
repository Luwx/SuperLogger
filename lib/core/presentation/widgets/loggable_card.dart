import 'package:flutter/material.dart';
import 'package:super_logger/utils/extensions.dart';

class FreeLimit {
  final int currentAmount;
  final int maxAmount;

  FreeLimit(this.currentAmount, this.maxAmount);

  bool get limitReached => currentAmount >= maxAmount;
}

class LoggableCard extends StatelessWidget {
  final String loggableTitle;
  final String loggableDescription;
  final Widget leadingWidget;
  final Widget? trailingWidget;
  final Function? onLoggableAddPage;
  final VoidCallback ontap;

  const LoggableCard({
    Key? key,
    required this.loggableTitle,
    required this.loggableDescription,
    required this.leadingWidget,
    required this.ontap,
    this.trailingWidget,
    this.onLoggableAddPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Theme.of(context).primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: leadingWidget,
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            loggableTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.maxFinite,
                        child: Text(
                          loggableDescription,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: trailingWidget,
                ),
              ],
            ),
          ),
          onTap: ontap,
        ),
      ),
    );
  }
}
