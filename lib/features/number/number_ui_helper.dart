import 'package:flutter/material.dart';

import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/core/presentation/screens/home/widgets/card_date_list.dart';
import 'package:super_logger/core/presentation/widgets/base_main_card.dart';
import 'package:super_logger/core/presentation/widgets/num_log_filter_form.dart';
import 'package:super_logger/features/number/models/number_properties.dart';
import 'package:super_logger/features/number/presentation/number_input_widgets.dart';
import 'package:super_logger/features/number/presentation/number_main_card_wrapper.dart';
import 'package:super_logger/features/number/presentation/number_properties_form.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/id_generator.dart';
import 'package:super_logger/utils/value_controller.dart';

import 'presentation/number_add_log_dialog.dart';

class NumberUiHelper extends BaseLoggableUiHelper {
  @override
  LoggableType get type => LoggableType.number;

  @override
  Widget getGeneralConfigForm(
      {MappableObject? originalProperties,
      required ValueEitherValidOrErrController<MappableObject> propertiesController}) {
    return EditValuePropertiesForm(
      valueProperties: originalProperties as NumberProperties?,
      propertiesController: propertiesController,
    );
  }

  @override
  Widget getTileTitleWidget(Log log, LoggableController controller) {
    //return Text(CounterUseCases.totalCountAtIndex(dateLog as DateLog<int>, logIndex).toString());
    return Text(log.value.toString());
  }

  @override
  Widget getEditEntryValueWidget(
      MappableObject properties, ValueEitherController valueController, dynamic logValue,
      {bool forComposite = false, bool forDialog = false}) {
    if (logValue != null) {
      valueController.setRightValue(logValue);
    }

    return Builder(builder: (context) {
      return NumberPropertiesHelper.shouldUseSlider((properties as NumberProperties)) &&
              properties.isStringValueValid(logValue?.toString() ??
                  NumberPropertiesHelper.getValidValue(properties).toString())
          ? ValueSlider(
              controller: valueController as ValueEitherController<double>,
              valueProperties: properties,
              title: forComposite ? "" : context.l10n.amount,
            )
          : NumberTextField(
              valueController: valueController as ValueEitherController<double>,
              valueProperties: properties,
              shouldHaveInitialFocus: forDialog && !forComposite,
              title: forComposite ? "" : context.l10n.amount,
            );
    });
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
    return NumberMainCardWrapper(
      key: key,
      loggable: loggable,
      date: date,
      state: state,
      onTap: onTap,
      onLongPress: onLongPress,
      onNoLogs: onNoLogs,
      onLogDeleted: onLogDeleted,
      uiHelper: this
    );
  }

  @override
  Future<Log<Object>?> newLog(BuildContext context, LoggableController controller) async {
    double? result = await showDialog<double>(
        context: context,
        builder: (context) {
          return NumberAddButtonDialog(
            valueProperties: controller.loggable.loggableProperties as NumberProperties,
          );
        });

    if (result == null) return null;

    return Log<double>(
      id: generateId(),
      timestamp: DateTime.now(),
      value: result,
      note: "",
    );
  }

  @override
  Widget getDisplayLogValueWidget(dynamic logValue,
      {LogDisplayWidgetSize size = LoggableUiHelper.defaultLogDisplaySize,
      MappableObject? properties}) {
    String preffix = (properties as NumberProperties?)?.prefix ?? "";
    String suffix = properties?.suffix ?? "";
    if (preffix.isNotEmpty) preffix = preffix + " ";
    if (suffix.isNotEmpty) suffix = " " + suffix;
    return Text("$preffix${(logValue as double).formatWithPrecision4}$suffix");
  }

  @override
  Widget getLogFilterForm(LogValueFilterController controller, MappableObject properties) {
    return NumLogFilterForm(controller: controller);
  }
}
