import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/main_controller.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/loggable_settings.dart';
import 'package:super_logger/core/models/loggable_tag.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/core/presentation/screens/loggable_details/loggable_details_screen.dart';

import 'package:super_logger/core/presentation/theme/dimensions.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';
import 'package:super_logger/utils/id_generator.dart';

// final propertiesControllerProvider = Provider.autoDispose(
//   (ref) => ValueEitherValidOrErrController<MappableObject>(),
// );

class CreateLoggableScreen extends HookWidget {
  const CreateLoggableScreen({Key? key, required this.loggableType, this.loggable})
      : super(key: key);

  final LoggableType loggableType;
  final Loggable? loggable;

//   @override
//   _CreateLoggableScreenState createState() => _CreateLoggableScreenState();
// }

// class _CreateLoggableScreenState extends State<CreateLoggableScreen>
//     with SingleTickerProviderStateMixin {
  //bool _pinned = false;
  //int _maxEntriesPerDay = 1000;

  // @override
  // void initState() {
  //   super.initState();
  //   _titleController = TextEditingController(text: widget.loggable?.title);
  //   _titleFocusNode = FocusNode();
  //   _tabController = TabController(length: 2, vsync: this);
  // }

  @override
  Widget build(BuildContext context) {
    final _propertiesController =
        useMemoized(() => ValueEitherValidOrErrController<MappableObject>());
    final _settingsController =
        useMemoized(() => ValueEitherValidOrErrController<LoggableSettings>());

    final _titleController = useTextEditingController(text: loggable?.title);
    final _titleFocusNode = FocusNode();
    final _tabController = useTabController(initialLength: 2);

    final _busy = useState(false);

    void onSavePressed() async {
      assert(_settingsController.isSetUp, "settings controller is not setup");

      if (_titleController.text.isEmpty) {
        _titleFocusNode.requestFocus();
        _tabController.animateTo(0);
        return;
      }
      Loggable newLoggable;
      MappableObject? loggableProperties;
      String id;
      bool shouldUpdate;

      // loggable properties page has not been loaded
      if (_propertiesController.isSetUp == false) {
        // load from existing loggable
        if (loggable != null) {
          loggableProperties = loggable!.loggableProperties;
        } else {
          loggableProperties = locator.get<MainFactory>().makeDefaultProperties(loggableType);
        }
      } else {
        loggableProperties = _propertiesController.value.fold(
          (valueErr) => null,
          (value) => value,
        );
        if (loggableProperties == null) {
          return;
        }
      }

      final loggableSettings = _settingsController.value.fold(
        (valueErr) => null,
        (value) => value,
      );
      // non valid settings
      if (loggableSettings == null) {
        return;
      }

      // use existing id
      if (loggable != null) {
        // do nothing if no change was made
        if (_titleController.text == loggable!.title &&
            loggableProperties == loggable!.loggableProperties &&
            loggable!.loggableSettings == loggableSettings) {
          //TODO: no action done, show snackbar
          Navigator.pop(context);
          return;
        }
        id = loggable!.id;
        shouldUpdate = true;
      }
      // generate new
      else {
        id = generateId();
        shouldUpdate = false;
      }

      newLoggable = Loggable(
        loggableSettings: loggableSettings,
        type: loggableType,
        title: _titleController.text,
        creationDate: loggable?.creationDate ?? DateTime.now(),
        tags: <LoggableTag>[].lock,
        id: id,
        loggableConfig: LoggableProperties(
          generalConfig: loggableProperties,
          mainCardConfig: const EmptyProperty(),
          aggregationConfig: const EmptyProperty(),
        ),
      );

      _busy.value = true;

      if (shouldUpdate) {
        await MainController.updateLoggable(newLoggable);
      } else {
        await MainController.addLoggable(newLoggable);
      }
      await Future.delayed(const Duration(milliseconds: 500));
      _busy.value = false;
      await Future.delayed(const Duration(milliseconds: 100));

      Navigator.pop(context, shouldUpdate ? ActionDone.update : ActionDone.add);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
            bottom: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(
                  text: "Basics",
                ),
                Tab(
                  text: "Properties",
                ),
              ],
            ),
            title: Text(loggable == null ? context.l10n.createNewLoggable : loggable!.title),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  primary: Theme.of(context).appBarTheme.foregroundColor,
                ),
                child: Text(loggable == null ? context.l10n.create : context.l10n.save),
                onPressed: onSavePressed,
              )
            ]),
        body: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: [
                LoggableSettingsSection(
                  loggable: loggable,
                  titleController: _titleController,
                  settingsController: _settingsController,
                  titleFocusNode: _titleFocusNode,
                ),
                locator.get<MainFactory>().getUiHelper(loggableType).getGeneralConfigForm(
                    propertiesController: _propertiesController,
                    originalProperties: loggable?.loggableProperties)
              ],
            ),
            if (_busy.value)
              Container(
                color: Colors.black12,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
          ],
        ),
      ),
    );
  }
}

class LoggableSettingsSection extends StatefulWidget {
  const LoggableSettingsSection(
      {Key? key,
      this.loggable,
      required this.settingsController,
      required this.titleController,
      required this.titleFocusNode})
      : super(key: key);

  final Loggable? loggable;
  final ValueEitherValidOrErrController<LoggableSettings> settingsController;
  final TextEditingController titleController;
  final FocusNode titleFocusNode;

  @override
  _LoggableSettingsSectionState createState() => _LoggableSettingsSectionState();
}

class _LoggableSettingsSectionState extends State<LoggableSettingsSection> {
  //late LoggableSettings _loggableSettings;
  //bool _validMaxEntriesPerDay = true;
  bool _titleValid = true;

  //bool _exportButtonLoading = false;

  void _setProperties(LoggableSettings settings) {
    widget.settingsController.setValue(LoggableSettingsHelper.settingsValidator(settings));
  }

  LoggableSettings get _currentProperties {
    return widget.settingsController.valueNoValidation;
  }

  @override
  void initState() {
    super.initState();
    widget.settingsController.setValue(
      LoggableSettingsHelper.settingsValidator(widget.loggable == null
          ? const LoggableSettings(pinned: false, maxEntriesPerDay: 5, color: null, symbol: "")
          : widget.loggable!.loggableSettings),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(
            height: AppDimens.defaultSpacing,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.defaultSpacing),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: _currentProperties.symbol,
                    decoration: const InputDecoration(label: Text("Symbol")),
                    inputFormatters: <TextInputFormatter>[LengthLimitingTextInputFormatter(3)],
                    onChanged: (s) => _setProperties(_currentProperties.copyWith(symbol: s)),
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: widget.titleController,
                    focusNode: widget.titleFocusNode,
                    decoration: InputDecoration(
                        label: Text(context.l10n.loggableTitle),
                        errorText: _titleValid ? null : context.l10n.chooseAName),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        setState(() {
                          _titleValid = false;
                        });
                      } else if (!_titleValid && value.isNotEmpty) {
                        setState(() {
                          _titleValid = true;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // const SizedBox(
          //   height: AppDimens.defaultSpacing,
          // ),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: AppDimens.defaultSpacing),
          //   child: TextFormField(
          //     initialValue: _currentProperties.maxEntriesPerDay.toString(),
          //     keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: true),
          //     inputFormatters: <TextInputFormatter>[
          //       FilteringTextInputFormatter.allow(RegExp(r'^[1-9]{1}\d*$')),
          //     ],
          //     decoration: InputDecoration(
          //         label: Text(context.l10n.maxEntriesPerDay),
          //         errorText: _validMaxEntriesPerDay ? null : context.l10n.invalidValue),
          //     onChanged: (value) {
          //       try {
          //         int newValue = int.parse(value);
          //         _setProperties(_currentProperties.copyWith(maxEntriesPerDay: newValue));
          //         //_loggableSettings = _loggableSettings.copyWith(maxEntriesPerDay: newValue);
          //         setState(() {
          //           _validMaxEntriesPerDay = true;
          //         });
          //       } catch (e) {
          //         setState(() {
          //           _validMaxEntriesPerDay = false;
          //         });
          //       }
          //     },
          //   ),
          // ),
          const SizedBox(
            height: AppDimens.defaultSpacing / 2,
          ),
          // SwitchListTile(
          //   title: Padding(
          //     padding: const EdgeInsets.only(left: 14),
          //     child: Text(context.l10n.showMinusButton),
          //   ),
          //   //secondary: Icon(Icons.beach_access),
          //   //controlAffinity: ListTileControlAffinity.leading,
          //   value: _currentProperties.showMinusButton,
          //   onChanged: (bool value) {
          //     setState(() {
          //       _setProperties(_currentProperties.copyWith(showMinusButton: value));
          //       //_loggableSettings = _loggableSettings.copyWith(showMinusButton: value);
          //     });
          //   },
          // ),
          SwitchListTile(
            title: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(context.l10n.pinned),
            ),
            //secondary: const Icon(Icons.beach_access),
            value: _currentProperties.pinned,
            onChanged: (bool value) {
              setState(() {
                _setProperties(_currentProperties.copyWith(pinned: value));
                //_loggableSettings = _loggableSettings.copyWith(pinned: value);
              });
            },
          ),
          const Divider(),
          if (widget.loggable != null) ...[
            TextButton(
              onPressed: () async {
                // TODO: Confirmation dialog
                //await MainController.deleteLoggable(widget.loggable!);
                final controller =
                    locator.get<MainFactory>().makeLoggableController(widget.loggable!);
                await controller.deleteSelfLoggable();
                Navigator.pop(context, ActionDone.delete);
              },
              child: Text(context.l10n.deleteLoggable),
              style: TextButton.styleFrom(
                primary: Colors.red,
              ),
            ),
            // TextButton(
            //   onPressed: () async {
            //     setState(() {
            //       _exportButtonLoading = true;
            //     });
            //     final loggableController =
            //         locator.get<MainFactory>().makeLoggableController(widget.loggable!);
            //     final logs = await loggableController.getAllLogs();

            //     Map<String, dynamic> loggableMap = widget.loggable!.toJson()
            //       ..removeWhere((key, value) => key == 'id');

            //     final logToMap =
            //         locator.get<MainFactory>().getFactoryFor(widget.loggable!.type).logToMap;
            //     loggableMap['logs'] = logs.map((log) {
            //       final map = logToMap(log);
            //       map.removeWhere(
            //         (key, value) => key == 'id',
            //       );
            //       return map;
            //     }).toList();

            //     final ext = await getExternalStorageDirectory();
            //     String filePath = '${ext!.path}/${widget.loggable!.title}.json';
            //     File file = File(filePath);

            //     await file.create();
            //     await file.writeAsString(jsonEncode(loggableMap));

            //     final params = SaveFileDialogParams(sourceFilePath: filePath);
            //     /*final savedFilePath =*/ await FlutterFileDialog.saveFile(params: params);
            //     //print(savedFilePath);

            //     setState(() {
            //       _exportButtonLoading = false;
            //     });
            //   },
            //   child: _exportButtonLoading
            //       ? const CircularProgressIndicator()
            //       : Text(context.l10n.export),
            //   style: TextButton.styleFrom(
            //     primary: Colors.blue,
            //   ),
            // )
          ]
        ],
      ),
    );
  }
}
