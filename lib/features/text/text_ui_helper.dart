import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/core/presentation/screens/loggable_details/loggable_details_screen.dart';
import 'package:super_logger/core/presentation/screens/home/widgets/card_date_list.dart';
import 'package:super_logger/core/presentation/widgets/animated_log_details_list.dart';
import 'package:super_logger/core/presentation/widgets/base.dart';
import 'package:super_logger/core/presentation/widgets/base_main_card.dart';
import 'package:super_logger/core/presentation/widgets/development_warning.dart';
import 'package:super_logger/features/text/models/text_properties.dart';
import 'package:super_logger/features/text/presentation/add_text_log_dialog.dart';
import 'package:super_logger/features/text/presentation/text_edit_widget.dart';

import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/id_generator.dart';
import 'package:super_logger/utils/value_controller.dart';

class TextUiHelper extends BaseLoggableUiHelper {
  @override
  Widget getGeneralConfigForm(
      {MappableObject? originalProperties,
      required ValueEitherValidOrErrController<MappableObject> propertiesController}) {
    propertiesController.setRightValue(TextProperties.defaults());
    return const DevelopmentWarning();
  }

  @override
  Widget getEditEntryValueWidget(
      MappableObject properties, ValueEitherController valueController, Object? logValue,
      {bool forComposite = false, bool forDialog = false}) {
    if (logValue != null && (logValue as String).isNotEmpty) {
      valueController.setRightValue(logValue);
    }

    return TextEditWidget(
        valueController: (valueController as ValueEitherController<String>),
        properties: properties as TextProperties);
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
    return Text(log.value);
  }

  @override
  Future<Log<Object>?> newLog(BuildContext context, LoggableController<Object> controller) async {
    String? result = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) =>
          AddTextLogDialog(properties: controller.loggable.loggableProperties as TextProperties),
    );

    if (result == null) return null;

    return Log<String>(
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
            controller.addLog(log);
          }
        },
      );
    });
  }

  Widget _getCardValue(
      DateLog? dateLog, LoggableController loggableController, bool isCardSelected) {
    if (dateLog != null) {
      return Text((dateLog as DateLog<String>).logs.last.value.toString());
    } else {
      return const Text("No data");
    }
  }

  Widget _getCardDetailsLog(DateLog? dateLog, LoggableController controller, bool isCardSelected) {
    return CardDetailsLogBase(
      details: dateLog != null ? AnimatedLogDetailList(dateLog: dateLog, maxEntries: 5) : null,
    );
  }

  @override
  LoggableType get type => LoggableType.text;

  @override
  Widget getDisplayLogValueWidget(dynamic logValue,
      {LogDisplayWidgetSize size = LoggableUiHelper.defaultLogDisplaySize,
      MappableObject? properties}) {
    return size.isLarge && (logValue as String).length < 32
        ? Text(logValue,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: logValue.length < 4 ? 32 : 18,
            ))
        : Text(logValue);
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
