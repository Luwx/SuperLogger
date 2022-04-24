import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/presentation/widgets/base_main_card.dart';
import 'package:super_logger/features/composite/models/composite_log.dart';
import 'package:super_logger/features/composite/models/composite_properties.dart';
import 'package:super_logger/features/composite/presentation/composite_input_form.dart';
import 'package:super_logger/utils/id_generator.dart';

enum _IconStatus { normal, confirm, discart }

class AddButtonWithConfirmation extends StatefulWidget {
  const AddButtonWithConfirmation({Key? key, required this.controller}) : super(key: key);
  final LoggableController controller;

  @override
  _AddButtonWithConfirmationState createState() => _AddButtonWithConfirmationState();
}

class _AddButtonWithConfirmationState extends State<AddButtonWithConfirmation> {
  _IconStatus _status = _IconStatus.normal;

  Widget _buildIcon(_IconStatus status) {
    bool isConfirm = status == _IconStatus.confirm;
    return Padding(
      key: ValueKey(isConfirm ? "confirm" : "discart"),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4),
      child: IconButton(
        onPressed: () {},
        icon: Icon(
          isConfirm ? Icons.check : Icons.close,
          color: isConfirm ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OpenContainer<CompositeLog>(
      transitionDuration: kThemeAnimationDuration * 2,
      closedBuilder: (context, openContainer) {
        return PageTransitionSwitcher(
          duration: kThemeAnimationDuration * 2,
          layoutBuilder: (List<Widget> entries) {
            return Stack(
              children: entries,
              alignment: Alignment.topLeft,
            );
          },
          transitionBuilder:
              (Widget child, Animation<double> animation, Animation<double> secondaryAnimation) {
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          child: _status == _IconStatus.normal
              ? Material(
                color: Colors.transparent,
                child: MainCardButton(
                    loggableController: widget.controller,
                    color: Theme.of(context).colorScheme.primary,
                    shadowColor: null, //const Color(0x501B59F3),
                    //shadowColor: Theme.of(context).colorScheme.primaryVariant.withAlpha(100),
                    //icon: Icons.add,
                    onTap: () async {
                      openContainer();
                      // final log = await newLog(context, controller);
                      // if (log != null) {
                      //   await controller.addLog(log);
                      // }
                    },
                  ),
              )
              : _buildIcon(_status),
        );
      },
      closedElevation: 0,
      closedShape: const CircleBorder(),
      closedColor: Theme.of(context).colorScheme.background,
      //closedColor: Colors.green,
      onClosed: (compositeLog) async {
        if (compositeLog != null) {
          final log = Log<CompositeLog>(
              id: generateId(), timestamp: DateTime.now(), value: compositeLog, note: "");
          setState(() {
            _status = _IconStatus.confirm;
          });
          await Future.delayed(kThemeAnimationDuration * 2);
          await widget.controller.addLog(log);
          await Future.delayed(kThemeAnimationDuration);
          setState(() {
            _status = _IconStatus.normal;
          });
        } else {
          setState(() {
            _status = _IconStatus.discart;
          });
          await Future.delayed(kThemeAnimationDuration * 2);
          setState(() {
            _status = _IconStatus.normal;
          });
        }
      },
      openBuilder: (context, onSave) {
        return CompositeInputForm(
          compositeProperties: widget.controller.loggable.loggableProperties as CompositeProperties,
          title: widget.controller.loggable.title,
        );
      },
    );
  }
}
