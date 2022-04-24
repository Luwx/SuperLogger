import 'package:flutter/material.dart';
import 'package:super_logger/core/main_controller.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/core/models/loggable_type_description.dart';
import 'package:super_logger/core/presentation/screens/loggable_details/loggable_details_screen.dart';
import 'package:super_logger/core/presentation/screens/create_loggable/create_loggable_screen.dart';
import 'package:super_logger/core/presentation/widgets/loggable_card.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';

class SelectNewLoggableScreen extends StatefulWidget {
  const SelectNewLoggableScreen({Key? key}) : super(key: key);

  @override
  State<SelectNewLoggableScreen> createState() => _SelectNewLoggableScreenState();
}

class _SelectNewLoggableScreenState extends State<SelectNewLoggableScreen> {
  final _mainController = locator.get<MainController>();

  List<Widget> buildLoggableList() {
    List<Widget> list = [];
    for (var loggableFactory in locator.get<MainFactory>().getFactories()) {
      LoggableTypeDescription description = loggableFactory.getLoggableTypeDescription();
      list.add(
        LoggableCard(
          loggableTitle: description.title,
          loggableDescription: description.description,
          leadingWidget: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor.withOpacity(0.06),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              description.icon,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
          ),
          trailingWidget: Icon(Icons.keyboard_arrow_right_outlined,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7)),
          onLoggableAddPage: () async {},
          ontap: () async {
            ActionDone? action = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CreateLoggableScreen(
                  loggableType: loggableFactory.type,
                ),
              ),
            );

            if (action != null && action == ActionDone.add) {
              Navigator.pop(context);
            }
          },
        ),
      );
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(context.l10n.createNewLoggable),
            ),
            body: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                      child: Text(
                        'Types',
                        style: Theme.of(context).textTheme.headline4,
                      ),
                    ),
                  ),
                  ...buildLoggableList()
                ],
              ),
            ),
          );
        });
  }
}
