import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/filters.dart';
import 'package:super_logger/core/presentation/screens/loggable_details/loggable_details_screen.dart';
import 'package:super_logger/core/presentation/screens/home/widgets/card_date_list.dart';
import 'package:super_logger/core/presentation/widgets/animated_log_details_list.dart';
import 'package:super_logger/core/presentation/widgets/base.dart';
import 'package:super_logger/core/presentation/widgets/base_main_card.dart';
import 'package:super_logger/core/presentation/widgets/development_warning.dart';
import 'package:super_logger/features/color/models/color_log.dart';
import 'package:super_logger/features/color/models/color_properties.dart';
import 'package:super_logger/features/color/presentation/color_display_widget.dart';
import 'package:super_logger/features/color/presentation/color_picker_dialog.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/models/mappable_object.dart';

import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/id_generator.dart';
import 'package:super_logger/utils/value_controller.dart';

class ColorUiHelper extends BaseLoggableUiHelper {
  @override
  Widget getGeneralConfigForm(
      {MappableObject? originalProperties,
      required ValueEitherValidOrErrController<MappableObject> propertiesController}) {
    propertiesController.setRightValue(ColorProperties.defaults());
    return const DevelopmentWarning();
  }

  @override
  Widget getEditEntryValueWidget(
      MappableObject properties, ValueEitherController valueController, logValue,
      {bool forComposite = false, bool forDialog = false}) {
    if (logValue != null) valueController.setRightValue(logValue);
    return EditColorLog(
      valueController: valueController as ValueEitherController<ColorLog>,
      properties: properties as ColorProperties,
    );
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
    return getDisplayLogValueWidget(log.value, size: LogDisplayWidgetSize.medium);
  }

  @override
  Future<Log<Object>?> newLog(BuildContext context, LoggableController<Object> controller) async {
    // ColorLog? result = await showDialog<ColorLog>(
    //   context: context,
    //   builder: (context) => ColorPickerDialog(
    //     enableAlpha: (controller.loggable.loggableProperties as ColorProperties).enableAlpha,
    //   ),
    // );

    ColorLog? result = await editColorLogDialog(
        context, controller.loggable.loggableProperties as ColorProperties, null);

    if (result == null) return null;

    return Log<ColorLog>(
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
        //icon: Icons.add,
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
      DateLog? dateLog, LoggableController loggableController, bool isCardSelected) {
    if (dateLog != null) {
      ColorLog colorLog = (dateLog as DateLog<ColorLog>).logs.last.value;
      return getDisplayLogValueWidget(
        colorLog,
        size: LogDisplayWidgetSize.large,
      );
    } else {
      return const Text("No data");
    }
  }

  Widget _getCardDetailsLog(DateLog? dateLog, LoggableController controller, bool isCardSelected) {
    return CardDetailsLogBase(
      details: dateLog != null
          ? AnimatedLogDetailList(
              dateLog: dateLog,
              maxEntries: 5,
              mapper: (context, log) => getDisplayLogValueWidget(
                (log as Log<ColorLog>).value,
                size: LogDisplayWidgetSize.small,
              ),
            )
          : null,
    );
  }

  @override
  LoggableType get type => LoggableType.color;

  @override
  Widget getDisplayLogValueWidget(dynamic logValue,
      {LogDisplayWidgetSize size = LoggableUiHelper.defaultLogDisplaySize,
      MappableObject? properties}) {
    double fontSize = size.when(isSmall: 12, isMedium: 14, isLarge: 16);
    double circleSize = size.when(isSmall: 24, isMedium: 32, isLarge: 42);
    return DisplayColor(
      logValue as ColorLog,
      size: circleSize,
      fontSize: fontSize,
      //hasShadow: false,
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
