import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggable_factory.dart';
import 'package:super_logger/core/main_controller.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/id_generator.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({Key? key}) : super(key: key);

  @override
  _AppSettingsScreenState createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appSettings),
      ),
      body: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        TextButton(
          child:
              _isLoading == true ? const CircularProgressIndicator() : Text(context.l10n.exportAll),
          onPressed: _isLoading == true
              ? null
              : () async {
                  setState(() {
                    _isLoading = true;
                  });

                  final categories = locator.get<MainController>().loggablesList;

                  List<Map<String, dynamic>> loggableMapList = [];

                  for (final loggable in categories) {
                    final loggableController =
                        locator.get<MainFactory>().makeLoggableController(loggable);
                    final logs = await loggableController.getAllLogs();

                    Map<String, dynamic> loggableMap = loggable.toJson()
                      ..removeWhere((key, value) => key == 'id');
                    final logToMap =
                        locator.get<MainFactory>().getFactoryFor(loggable.type).logToMap;

                    loggableMap['logs'] = logs.map((log) {
                      final map = logToMap(log);
                      map.removeWhere(
                        (key, value) => key == 'id',
                      );
                      return map;
                    }).toList();

                    loggableMapList.add(loggableMap);
                  }

                  Map<String, dynamic> db = {'st_version': 0.55, 'categories': loggableMapList};

                  final ext = await getExternalStorageDirectory();
                  String filePath = '${ext!.path}/stdb.json';
                  File file = File(filePath);

                  await file.create();
                  await file.writeAsString(jsonEncode(db));

                  final params = SaveFileDialogParams(sourceFilePath: filePath);
                  /*final savedFilePath= */ await FlutterFileDialog.saveFile(params: params);
                  //print(savedFilePath);

                  setState(() {
                    _isLoading = false;
                  });
                },
        ),
        TextButton(
          child: _isLoading == true ? const CircularProgressIndicator() : const Text("Import db"),
          onPressed: _isLoading == true
              ? null
              : () async {
                  setState(() {
                    _isLoading = true;
                  });

                  //final existingCategories = locator.get<MainController>().categoriesList;

                  const params = OpenFileDialogParams(fileExtensionsFilter: ['json']
                      //dialogType: OpenFileDialogType,
                      //sourceType: SourceType.photoLibrary,
                      );
                  //return;
                  final filePath = await FlutterFileDialog.pickFile(params: params);
                  //print(filePath);

                  if (filePath == null) {
                    return;
                  }

                  File file = File(filePath);

                  if (!file.existsSync()) {
                    return;
                  }

                  String fileString = "";
                  try {
                    fileString = await file.readAsString();
                  } catch (e) {
                    log(e.toString());
                  }

                  try {
                    Map<String, dynamic> db = jsonDecode(fileString);

                    final loggableMapList = db['categories'] as List<dynamic>;

                    for (final loggableMap in loggableMapList) {
                      // create the id
                      loggableMap.putIfAbsent('id', () => generateId());

                      Loggable importedLoggable =
                          locator.get<MainFactory>().loggableFromMap(loggableMap);

                      LoggableFactory loggableFactory =
                          locator.get<MainFactory>().getFactoryFor(importedLoggable.type);

                      List<Log> logs = (loggableMap['logs'] as List<dynamic>).map((logMap) {
                        Map<String, dynamic> map = logMap;
                        map.putIfAbsent('id', () => generateId());
                        return loggableFactory.logFromMap(map);
                      }).toList();

                      await MainController.addLoggable(importedLoggable);
                      LoggableController controller =
                          locator.get<MainFactory>().makeLoggableController(importedLoggable);
                      await controller.addLogs(logs);
                    }
                  } catch (e) {
                    log(e.toString());
                    setState(() {
                      _isLoading = false;
                    });
                    rethrow;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("importing successful"),
                    duration: Duration(seconds: 10),
                  ));

                  setState(() {
                    _isLoading = false;
                  });
                },
        )
      ]),
    );
  }
}
