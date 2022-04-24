import 'dart:io';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';

import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/datelog.dart';

import 'package:super_logger/core/models/filters.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/core/presentation/screens/loggable_details/loggable_details_screen.dart';
import 'package:super_logger/core/presentation/screens/home/widgets/card_date_list.dart';
import 'package:super_logger/core/presentation/widgets/animated_log_details_list.dart';
import 'package:super_logger/core/presentation/widgets/base.dart';
import 'package:super_logger/core/presentation/widgets/base_main_card.dart';
import 'package:super_logger/core/presentation/widgets/development_warning.dart';
import 'package:super_logger/features/audio/models/audio_log.dart';
import 'package:super_logger/features/audio/presentation/record_audio_screen.dart';

import 'package:super_logger/features/image/models/image_properties.dart';

import 'package:super_logger/utils/extensions.dart';

import 'package:super_logger/utils/value_controller.dart';

class AudioUiHelper extends BaseLoggableUiHelper {
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

    return const DevelopmentWarning();

    // print("??????");
    // return AudioLogEditWidget(
    //     controller: valueController as ValueEitherController<AudioLog>,
    //     properties: properties as ImageProperties,
    //     title: "");
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

    final File? audio = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RecordAudioScreen(),
      ),
    );

    if (audio == null) return null;

    // final result = await showDialog<ImageLog>(
    //   context: context,
    //   builder: (BuildContext context) {
    //     return ImageConfirmDialog(
    //       imageLog: ImageLog(
    //         name: '',
    //         filePaths: [AbsoluteFilePath(path: image.path, fileType: FileType.image)].lock,
    //       ),
    //     );
    //   },
    // );

    return null;

    // return Log<AudioLog>(
    //   id: generateId(),
    //   timestamp: DateTime.now(),
    //   value: AudioLog(),
    //   note: "",
    // );
  }

  Widget? _getPrimaryCardButton(LoggableController controller) {
    return Builder(builder: (context) {
      return MainCardButton(
        loggableController: controller,
        color: Theme.of(context).colorScheme.primary,
        shadowColor: null, //const Color(0x501B59F3),
        //shadowColor: Theme.of(context).colorScheme.primaryVariant.withAlpha(100),
        //icon: Icons.add,
        onTap: () async {
          await newLog(context, controller);
        },
      );
    });
  }

  Widget _getCardValue(
      DateLog dateLog, LoggableController loggableController, bool isCardSelected) {
    return getDisplayLogValueWidget((dateLog as DateLog<AudioLog>).logs.last.value,
        size: LogDisplayWidgetSize.large);
  }

  Widget _getCardDetailsLog(DateLog? dateLog, LoggableController controller, bool isCardSelected) {
    assert(dateLog == null || dateLog is DateLog<AudioLog>,
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
  LoggableType get type => LoggableType.audio;

  @override
  Widget getDisplayLogValueWidget(dynamic logValue,
      {LogDisplayWidgetSize size = LoggableUiHelper.defaultLogDisplaySize,
      MappableObject? properties}) {
    //final imageWidget = _imageWidget(isLarge, logValue);
    return const Text("Nope");
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

//   ClipRRect _imageWidget(bool isLarge, FilePath filePath) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(isLarge ? 6 : 4),
//       child: ConstrainedBox(
//         constraints: BoxConstraints(maxHeight: isLarge ? 250 : 80),
//         child: FutureBuilder<String>(
//             future: locator.get<MainController>().docsPath,
//             builder: (context, snapshot) {
//               if (!snapshot.hasData) return const CircularProgressIndicator();

//               final file = filePath.when(
//                 saved: (saved) {
//                   return File(p.join(snapshot.data!, saved.path));
//                 },
//                 absolute: (absolute) {
//                   return File(absolute.path);
//                 },
//               );
//               if (!file.existsSync()) {
//                 return Text(
//                   context.l10n.imageNotFound,
//                   style: const TextStyle(
//                     color: Colors.red,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 );
//               }
//               return GestureDetector(
//                 child: Image.file(file),
//               );
//             }),
//       ),
//     );
//   }
}
