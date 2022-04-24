import 'dart:io';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/main_controller.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/models/file_path.dart';
import 'package:super_logger/core/models/filters.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/core/presentation/screens/loggable_details/loggable_details_screen.dart';
import 'package:super_logger/core/presentation/screens/home/widgets/card_date_list.dart';
import 'package:super_logger/core/presentation/widgets/animated_log_details_list.dart';
import 'package:super_logger/core/presentation/widgets/base.dart';
import 'package:super_logger/core/presentation/widgets/base_main_card.dart';
import 'package:super_logger/core/presentation/widgets/development_warning.dart';
import 'package:super_logger/features/image/models/image_log.dart';
import 'package:super_logger/features/image/models/image_properties.dart';
import 'package:super_logger/features/image/presentation/image_confirm_dialog.dart';
import 'package:super_logger/features/image/presentation/image_log_edit_widget.dart';
import 'package:super_logger/locator.dart';

import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/id_generator.dart';
import 'package:super_logger/utils/value_controller.dart';

class ImageUiHelper extends BaseLoggableUiHelper {
  @override
  Widget getGeneralConfigForm(
      {MappableObject? originalProperties,
      required ValueEitherValidOrErrController<MappableObject> propertiesController}) {
    propertiesController.setRightValue(ImageProperties(o1: "o1"));
    return const DevelopmentWarning();
  }

  @override
  Widget getEditEntryValueWidget(
      MappableObject properties, ValueEitherController valueController, logValue,
      {bool forComposite = false, bool forDialog = false}) {
    if (logValue != null) valueController.setRightValue(logValue, notify: false);

    return ImageLogEditWidget(
        controller: valueController as ValueEitherController<ImageLog>,
        properties: properties as ImageProperties,
        title: "");
  }

  @override
  Widget getMainCard(
      {Key? key,
      required Loggable loggable,
      required DateTime date,
      required CardState state,
      required VoidCallback onTap,
      required VoidCallback onLongPress,
      required void Function(Loggable p1) onNoLogs,
      required OnLogDelete onLogDeleted}) {
    bool isToday = date.isToday;
    return BaseMainCard(
      key: key,
      loggable: loggable,
      date: date,
      state: state,
      onTap: onTap,
      onLongPress: onLongPress,
      onNoLogs: onNoLogs,
      onLogDeleted: onLogDeleted,
      cardValue: _getCardValue,
      cardLogDetails: _getCardDetailsLog,
      primaryButton: isToday ? _getPrimaryCardButton : null,
      //secondaryButton: isToday ? _getSecondaryCardButton : null,
      //color: _getPrimaryColor(loggable).withAlpha(20),
    );
  }

  @override
  Widget getTileTitleWidget(Log log, LoggableController<Object> controller) {
    return getDisplayLogValueWidget(log.value);
  }

  @override
  Future<Log<Object>?> newLog(BuildContext context, LoggableController<Object> controller) async {
    // Pick an image
    final XFile? image = await pickImageDialog(context);

    if (image == null) return null;

    final result = await showDialog<ImageLog>(
      context: context,
      builder: (BuildContext context) {
        return ImageConfirmDialog(
          imageLog: ImageLog(
            name: '',
            filePaths: [AbsoluteFilePath(path: image.path, fileType: FileType.image)].lock,
          ),
        );
      },
    );

    if (result == null) {
      // delete cached image
      File cachedImage = File(image.path);
      if (await cachedImage.exists()) {
        try {
          await cachedImage.delete();
        } catch (e) {
          //
        }
      }
      return null;
    }

    return Log<ImageLog>(
      id: generateId(),
      timestamp: DateTime.now(),
      value: result,
      note: "",
    );
  }

  Widget? _getPrimaryCardButton(LoggableController controller) {
    return Builder(builder: (context) {
      return MainCardButton(
        loggableController: controller,
        color: Theme.of(context).colorScheme.primary,
        shadowColor: null, //const Color(0x501B59F3),
        //shadowColor: Theme.of(context).colorScheme.primaryVariant.withAlpha(100),
        // icon: Icons.add,
        onTap: () async {
          final log = await newLog(context, controller);
          if (log != null) {
            await controller.addLog(log);
          }
        },
      );
    });
  }

  Widget _getCardValue(
      DateLog dateLog, LoggableController loggableController, bool isCardSelected) {
    return getDisplayLogValueWidget((dateLog as DateLog<ImageLog>).logs.last.value,
        size: LogDisplayWidgetSize.large);
  }

  Widget _getCardDetailsLog(DateLog? dateLog, LoggableController controller, bool isCardSelected) {
    assert(dateLog == null || dateLog is DateLog<ImageLog>,
        "Required: DateLog<String>, found: ${dateLog.runtimeType}");
    return CardDetailsLogBase(
      details: dateLog != null
          ? AnimatedLogDetailList(
              dateLog: dateLog,
              maxEntries: 5,
              mapper: (context, log) => getDisplayLogValueWidget(log.value),
            )
          : null,
    );
  }

  @override
  LoggableType get type => LoggableType.image;

  @override
  Widget getDisplayLogValueWidget(dynamic logValue,
      {LogDisplayWidgetSize size = LoggableUiHelper.defaultLogDisplaySize,
      MappableObject? properties}) {
    //final imageWidget = _imageWidget(isLarge, logValue);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: (logValue as ImageLog).name.isEmpty && logValue.filePaths.length == 1
          ? Align(
              alignment: Alignment.centerLeft,
              child: _imageWidget(size.isLarge, logValue.filePaths.first),
            )
          : Builder(builder: (context) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(16),
                    borderRadius: BorderRadius.circular(size.isLarge ? 8 : 6),
                  ),
                  padding: EdgeInsets.symmetric(
                      horizontal: logValue.filePaths.length > 1 ? 2 : 4, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        height: size.isLarge ? 250 : 80,
                        child: ListView(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          children: logValue.filePaths
                              .map((filePath) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: _imageWidget(size.isSmall, filePath),
                                  ))
                              .toList(),
                        ),
                      ),
                      if (logValue.name.isNotEmpty)
                        const SizedBox(
                          height: 4,
                        ),
                      if (logValue.name.isNotEmpty)
                        Text(logValue.name, style: Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
                ),
              );
            }),
    );
  }

  ClipRRect _imageWidget(bool isLarge, FilePath filePath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(isLarge ? 6 : 4),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: isLarge ? 250 : 80),
        child: FutureBuilder<String>(
            future: locator.get<MainController>().docsPath,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();

              final file = filePath.when(
                saved: (saved) {
                  return File(p.join(snapshot.data!, saved.path));
                },
                absolute: (absolute) {
                  return File(absolute.path);
                },
              );
              if (!file.existsSync()) {
                return Text(
                  context.l10n.imageNotFound,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
              return GestureDetector(
                child: Image.file(file),
              );
            }),
      ),
    );
  }

  @override
  Widget getLogFilterForm(
     LogValueFilterController controller, MappableObject properties) {
    return const DevelopmentWarning();
  }

  @override
  Widget? getLogSortForm(
      ValueEitherValidOrErrController<CompareLogs> controller, MappableObject properties) {
    return null;
  }

  @override
  Widget? getDateLogSortForm(
      ValueEitherValidOrErrController<CompareDateLogs> controller, MappableObject properties) {
    return null;
  }

  @override
  Widget? getDateLogFilterForm(
      DateLogValueFilterController controller, MappableObject properties) {
    return null;
  }
}
