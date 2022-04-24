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
import 'package:super_logger/core/presentation/widgets/base_main_card.dart';
import 'package:super_logger/core/presentation/widgets/base.dart';
import 'package:super_logger/core/presentation/widgets/development_warning.dart';
import 'package:super_logger/features/duration/models/duration_log.dart';
import 'package:super_logger/features/duration/models/duration_properties.dart';
import 'package:super_logger/features/duration/presentation/display_duration.dart';
import 'package:super_logger/features/duration/presentation/duration_input_widgets.dart';
import 'package:super_logger/features/duration/presentation/duration_properties_form.dart';
import 'package:super_logger/features/duration/presentation/play_pause_stop_button.dart';

import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/id_generator.dart';
import 'package:super_logger/utils/value_controller.dart';

class DurationUiHelper extends BaseLoggableUiHelper {
  @override
  Widget getGeneralConfigForm(
      {MappableObject? originalProperties,
      required ValueEitherValidOrErrController<MappableObject> propertiesController}) {
    return DurationPropertiesForm(
      propertiesController: propertiesController,
      properties: originalProperties as DurationProperties?,
    );
  }

  @override
  Widget getEditEntryValueWidget(
      MappableObject properties, ValueEitherController valueController, logValue,
      {bool forComposite = false, bool forDialog = false}) {
    if (logValue != null) valueController.setRightValue(logValue, notify: false);
    if (forComposite) {
      return DurationInputForComposite(
          forDialog: forDialog,
          valueController: valueController as ValueEitherController<DurationLog>,
          properties: properties as DurationProperties);
    } else {
      return DynamicDurationInput(
        valueController: valueController as ValueEitherController<DurationLog>,
        properties: properties as DurationProperties,
      );
    }
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
    return Text(log.value.formattedDuration);
  }

  @override
  Future<Log<Object>?> newLog(BuildContext context, LoggableController<Object> controller) async {
    return Log<DurationLog>(
      id: generateId(),
      timestamp: DateTime.now(),
      value: DurationLog.createRunningDuration(),
      note: "",
    );
  }

  Widget? _getPrimaryCardButton(LoggableController controller) {
    return Builder(builder: (context) {
      return PlayPauseStopButtonMainCardWrapper(controller: controller, onTap: () {});
    });
  }

  Widget _getCardValue(
      DateLog? dateLog, LoggableController loggableController, bool isCardSelected) {
    assert(dateLog == null || dateLog is DateLog<DurationLog>,
        "Required: DateLog<DurationLogValue>, found: ${dateLog.runtimeType}");

    if (dateLog != null) {
      final logVal = (dateLog as DateLog<DurationLog>).logs.last.value;
      return DisplayDuration(
        duration: logVal,
        textSize: 24,
      );
    } else {
      return const Text("No data");
    }
  }

  Widget _getCardDetailsLog(DateLog? dateLog, LoggableController controller, bool isCardSelected) {
    Widget mapper(context, Log log) {
      final durationLog = log as Log<DurationLog>;
      return Builder(
        builder: (context) {
          if (durationLog.value is RunningDuration) {
            return Text(context.l10n.durationRunningLabel);
          } else if (durationLog.value is PausedDuration) {
            return Text(
                "${durationLog.value.formattedDuration} ${context.l10n.durationPausedLogLabel}");
          } else {
            return Text(durationLog.value.formattedDuration);
          }
        },
      );
    }

    return CardDetailsLogBase(
      details: dateLog != null
          ? AnimatedLogDetailList(
              dateLog: dateLog,
              maxEntries: 5,
              mapper: mapper,
            )
          : null,
    );
  }

  @override
  LoggableType get type => LoggableType.duration;

  @override
  Widget getDisplayLogValueWidget(dynamic logValue,
      {LogDisplayWidgetSize size = LoggableUiHelper.defaultLogDisplaySize,
      MappableObject? properties}) {
    return Text("${(logValue as DurationLog).seconds} seconds");
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
