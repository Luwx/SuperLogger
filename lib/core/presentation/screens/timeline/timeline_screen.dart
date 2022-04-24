import 'package:flutter/material.dart';

import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/main_controller.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';

enum _Status { mounting, done }

class _LoggableAndController {
  Loggable loggable;
  LoggableController controller;
  _LoggableAndController({
    required this.loggable,
    required this.controller,
  });
}

class _LogAndLoggableId {
  Log log;
  String loggableId;
  _LogAndLoggableId({
    required this.log,
    required this.loggableId,
  });
}

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({Key? key}) : super(key: key);

  @override
  _TimelineScreenState createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  late MainController mainController;
  final Map<String, _LoggableAndController> _loggableAndController = {};
  _Status _status = _Status.mounting;

  int _totalCategories = 0;
  int _currentProcessedLoggable = 0;

  List<_LogAndLoggableId> logs = [];

  Future<void> _setupTimeline() async {
    if (_status != _Status.mounting) {
      setState(() {
        _status = _Status.mounting;
      });
    }

    logs = [];
    final categories = mainController.loggablesList;

    _totalCategories = categories.length;

    await Future.delayed(const Duration(milliseconds: 500));

    int count = 0;
    // get all logs
    for (final loggable in categories) {
      final controller = locator.get<MainFactory>().makeLoggableController(loggable);
      _loggableAndController.putIfAbsent(
          loggable.id, () => _LoggableAndController(loggable: loggable, controller: controller));
      final loggableLogs = await controller.getAllLogs();
      logs.addAll(loggableLogs.map((log) => _LogAndLoggableId(log: log, loggableId: loggable.id)));
      setState(() {
        _currentProcessedLoggable = count++;
      });
    }

    // sort dates
    logs.sort((a, b) => b.log.timestamp.compareTo(a.log.timestamp));

    setState(() {
      _status = _Status.done;
    });
  }

  @override
  void initState() {
    super.initState();
    mainController = locator.get<MainController>();
    _setupTimeline();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.timeline),
      ),
      body: _status == _Status.mounting
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  Text("Processing loggable $_currentProcessedLoggable of $_totalCategories")
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(22),
              child: ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];

                  bool showDateHeader = false;
                  if (index == 0) {
                    showDateHeader = true;
                  } else {
                    if (logs[index - 1].log.dateAsISO8601 != log.log.dateAsISO8601) {
                      showDateHeader = true;
                    }
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (showDateHeader)
                        Padding(
                          padding: const EdgeInsets.only(top: 22.0),
                          child: Text(log.log.dateAsISO8601,
                              style: const TextStyle(
                                fontSize: 18,
                              )),
                        ),
                      Row(
                        //mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text("($index) " +
                              _loggableAndController[log.loggableId]!.loggable.title +
                              ": " +
                              log.log.value.toString()),
                          Text(log.log.formattedTime),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
