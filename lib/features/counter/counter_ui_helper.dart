import 'dart:async';
import 'package:flutter/material.dart';

import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/core/presentation/screens/home/widgets/card_date_list.dart';
import 'package:super_logger/core/presentation/widgets/development_warning.dart';
import 'package:super_logger/features/counter/counter_loggable_controller.dart';
import 'package:super_logger/features/counter/presentation/counter_main_card_wrapper.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';
import 'package:super_logger/utils/id_generator.dart';

import 'models/counter_properties.dart';
import 'presentation/counter_value_edit_widget.dart';
import 'presentation/counter_properties_form.dart';

class CounterUiHelper extends BaseLoggableUiHelper {
  @override
  LoggableType get type => LoggableType.counter;

  @override
  Widget getGeneralConfigForm(
      {MappableObject? originalProperties,
      required ValueEitherValidOrErrController<MappableObject> propertiesController}) {
    return EditCounterPropertiesForm(
      counterProperties: originalProperties as CounterProperties?,
      propertiesController: propertiesController,
    );
  }


  @override
  Widget getTileTitleWidget(Log log, LoggableController controller) {
    return FutureBuilder<DateLog>(
        future: controller.getCachedDateLog(log.dateAsISO8601),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text(
              "Loading...",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }

          if (!snapshot.hasData) {
            return Text(
              context.l10n.counterErrorOcurred,
              style: const TextStyle(
                color: Colors.redAccent,
              ),
            );
          }

          List<Log> logs = snapshot.data!.logs;

          int logIndex = -1;
          for (int i = 0; i < logs.length; i++) {
            if (log.id == logs[i].id) {
              logIndex = i;
            }
          }
          if (logIndex == -1) {
            return Text(
              context.l10n.counterLogNotFound,
              style: const TextStyle(
                color: Colors.redAccent,
              ),
            );
          }

          return Text(CounterUseCases.totalCountAtIndex(snapshot.data as DateLog<int>, logIndex)
              .toString());
        });
  }

  @override
  Widget getEditEntryValueWidget(
      MappableObject properties, ValueEitherController valueController, dynamic logValue,
      {bool forComposite = false, bool forDialog = false}) {
    return CounterValueEditWidget(
        controller: valueController as ValueEitherController<int>,
        counterProperties: properties as CounterProperties,
        logValue: logValue as int?);
  }

  @override
  Widget getMainCard({
    Key? key,
    required Loggable loggable,
    required DateTime date,
    required CardState state,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
    required void Function(Loggable p1) onNoLogs,
    required OnLogDelete onLogDeleted,
  }) {
    return CounterMainCardWrapper(
      key: key,
      loggable: loggable,
      date: date,
      state: state,
      onTap: onTap,
      onLongPress: onLongPress,
      onNoLogs: onNoLogs,
      onLogDeleted: onLogDeleted,
      uiHelper: this,
    );
  }

  @override
  Future<Log<Object>?> newLog(BuildContext context, LoggableController controller) async {
    // just increase by one for now
    return Log<int>(
      id: generateId(),
      timestamp: DateTime.now(),
      value: 1,
      note: "",
    );
  }

  @override
  Widget getDisplayLogValueWidget(dynamic logValue,
      {LogDisplayWidgetSize size = LoggableUiHelper.defaultLogDisplaySize,
      MappableObject? properties}) {
    return Text(logValue.toString());
  }

  @override
  Widget getLogFilterForm(
      LogValueFilterController controller, MappableObject properties) {
    return const DevelopmentWarning();
  }
}
