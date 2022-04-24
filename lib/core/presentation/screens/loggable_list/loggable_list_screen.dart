import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/main_controller.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/presentation/screens/loggable_details/loggable_details_screen.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class LoggablesScreen extends StatefulWidget {
  const LoggablesScreen({Key? key}) : super(key: key);
  //final List<BaseCategory> categories;

  @override
  State<LoggablesScreen> createState() => _LoggablesScreenState();
}

class _LoggablesScreenState extends State<LoggablesScreen> {
  LoggableType? _filterType;

  late MainController mainController;
  bool _isImporting = false;

  //String? _newCategoryId;

  @override
  void initState() {
    super.initState();
    mainController = locator.get<MainController>();
    _isImporting = false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Loggable>>(
      initialData: mainController.loggablesList,
      stream: mainController.loggablesStream,
      builder: (context, snapshot) {
        List<Loggable> loggables = snapshot.data ?? [];

        final filteredLoggableList = _filterType == null
            ? loggables
            : loggables.where((cat) => cat.type == _filterType).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.loggables),
            // actions: [
            //   TextButton.icon(
            //     onPressed: () async {
            //       const params = OpenFileDialogParams(fileExtensionsFilter: ['json']
            //           //dialogType: OpenFileDialogType,
            //           //sourceType: SourceType.photoLibrary,
            //           );
            //       //return;
            //       final filePath = await FlutterFileDialog.pickFile(params: params);

            //       if (filePath == null) {
            //         return;
            //       }

            //       File file = File(filePath);

            //       if (!file.existsSync()) {
            //         return;
            //       }

            //       setState(() {
            //         _isImporting = true;
            //       });

            //       String fileString = "";
            //       try {
            //         fileString = await file.readAsString();
            //       } catch (e) {
            //         log(e.toString());
            //       }

            //       String? loggableId;

            //       try {
            //         Map<String, dynamic> loggableMap = jsonDecode(fileString);

            //         // create the id
            //         loggableMap.putIfAbsent('id', () => generateId());

            //         Category importedCategory =
            //             locator.get<MainFactory>().loggableFromMap(loggableMap);

            //         CategoryFactory loggableFactory =
            //             locator.get<MainFactory>().getFactoryFor(importedCategory.type);

            //         List<Log> logs = (loggableMap['logs'] as List<dynamic>).map((logMap) {
            //           Map<String, dynamic> map = logMap;
            //           map.putIfAbsent('id', () => generateId());
            //           return loggableFactory.logFromMap(map);
            //         }).toList();

            //         await MainController.addCategory(importedCategory);
            //         CategoryController controller =
            //             locator.get<MainFactory>().makeCategoryController(importedCategory);
            //         await controller.addLogs(logs);
            //         await Future.delayed(const Duration(milliseconds: 500));
            //         loggableId = importedCategory.id;
            //       } catch (e) {
            //         log(e.toString());
            //         rethrow;
            //       }

            //       setState(() {
            //         if (loggableId != null) {
            //           //_newCategoryId = loggableId;
            //         }
            //         _isImporting = false;
            //       });
            //     },
            //     icon: const Icon(Icons.download),
            //     label: const Text("Import"),
            //     style: TextButton.styleFrom(
            //       primary: Colors.white,
            //     ),
            //   )
            // ],
          ),
          body: _isImporting
              ? Container(
                  color: Theme.of(context).primaryColor.withAlpha(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(
                        width: double.infinity,
                      ),
                      Text(
                        "Importing Category",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor.withAlpha(192),
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(
                        height: 22,
                      ),
                      const CircularProgressIndicator(),
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.search),
                                ),
                                hintText: context.l10n.search,
                              ),
                            ),
                          ),
                          PopupMenuButton<LoggableType?>(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(Icons.filter_alt),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Text(_filterType == null ? "all" : _filterType!.name),
                                ],
                              ),
                            ),
                            onSelected: (type) {
                              setState(() {
                                _filterType = type;
                              });
                            },
                            itemBuilder: (BuildContext context) {
                              return [null, ...LoggableType.values].map((LoggableType? type) {
                                return PopupMenuItem<LoggableType?>(
                                  // onTap: () {
                                  //   context.pop();
                                  //   setState(() {
                                  //     _filterType = type;
                                  //   });
                                  // },
                                  value: type,
                                  child: Text(type == null ? "all" : type.name),
                                );
                              }).toList();
                            },
                          ),
                        ],
                      ),
                    ),
                    filteredLoggableList.isEmpty
                        ? Expanded(child: Center(child: _buildNoLoggableBody(context)))
                        : Expanded(child: _buildMainBody(filteredLoggableList)),
                  ],
                ),
        );
      },
    );
  }

  Column _buildNoLoggableBody(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (_filterType != null)
          Icon(
            Icons.filter_alt,
            color: Theme.of(context).primaryColor.withAlpha(96),
            size: 96,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 44),
          child: Text(
            _filterType == null ? "No loggable" : "No loggable of type ${_filterType!.name}",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).primaryColor.withAlpha(96),
              fontSize: 26,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainBody(List<Loggable> filteredLoggableList) {
    return GridView.count(
      padding: const EdgeInsets.all(12),
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      children: List.generate(
        filteredLoggableList.length,
        (index) {
          return LoggableCard(
            loggable: filteredLoggableList[index],
          );
        },
      ),
    );
  }
}

class LoggableCard extends StatelessWidget {
  const LoggableCard({Key? key, required this.loggable}) : super(key: key);
  final Loggable loggable;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: loggable.isNew
              ? Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.6), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: loggable.isNew
                  ? colorScheme.primary.withOpacity(0.4)
                  : colorScheme.secondary.withOpacity(0.4).darken(10),
              blurRadius: 12,
              spreadRadius: -2,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: loggable.isNew
                  ? colorScheme.primary.withOpacity(0.4)
                  : colorScheme.secondary.withOpacity(0.4).darken(20),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        //height: 20,
        child: Material(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          //color: Theme.of(context).colorScheme.primary.withAlpha(16),
          color: colorScheme.secondary,
          child: InkWell(
            splashFactory: InkSplash.splashFactory,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoggableDetailsScreen(
                    loggableId: loggable.id,
                  ),
                ),
              );
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: loggable.loggableSettings.symbol.isNotEmpty
                      ? Row(
                          children: [
                            const Spacer(
                              flex: 3,
                            ),
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(0),
                                child: Opacity(
                                  opacity: 0.36,
                                  child: Container(
                                    //margin: const EdgeInsets.symmetric(horizontal: 16),
                                    // decoration: BoxDecoration(
                                    //     color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                    //     //borderRadius: BorderRadius.circular(16),
                                    //     shape: BoxShape.circle),
                                    padding: const EdgeInsets.all(16),
                                    child: FittedBox(
                                      child: Text(
                                        loggable.loggableSettings.symbol,
                                        style: TextStyle(color: colorScheme.onPrimary),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        //mainAxisSize: MainAxisSize.min,
                        //crossAxisAlignment: CrossAxisAlignment.baseline,
                        //ktextBaseline: TextBaseline.alphabetic,
                        children: <Widget>[
                          // if (loggable.loggableSettings.symbol.isNotEmpty) ...[
                          //   Container(
                          //     width: 40,
                          //     height: 40,
                          //     //margin: const EdgeInsets.symmetric(horizontal: 16),
                          //     decoration: BoxDecoration(
                          //       color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                          //       //borderRadius: BorderRadius.circular(16),
                          //       shape: BoxShape.circle,
                          //     ),
                          //     padding: const EdgeInsets.all(4),
                          //     child: FittedBox(
                          //       child: Text(
                          //         loggable.loggableSettings.symbol,
                          //         style: TextStyle(color: Theme.of(context).primaryColor),
                          //       ),
                          //     ),
                          //   ),
                          //   const SizedBox(
                          //     width: 8,
                          //   ),
                          // ],
                          if (loggable.isNew) ...[
                            Text(
                              " New!",
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            )
                          ],
                          Expanded(
                            child: Text(
                              loggable.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: colorScheme.onPrimary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      Text(
                        loggable.type.name,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: colorScheme.onPrimary.withOpacity(0.5),
                            ),
                      ),
                      Expanded(
                        child: Container(),
                      ),
                      Text(
                        context.l10n.entryAmountInformation(99),
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      Text(
                        context.l10n.entryDaysInformation(99),
                        style: TextStyle(color: colorScheme.onPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
