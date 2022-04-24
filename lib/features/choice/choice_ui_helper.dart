import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/main_factory.dart';
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
import 'package:super_logger/features/choice/models/choice_properties.dart';
import 'package:super_logger/features/choice/presentation/choice_input_widget.dart';
import 'package:super_logger/features/choice/presentation/choice_properties_form/choice_properties_form.dart';
import 'package:super_logger/locator.dart';

import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/id_generator.dart';
import 'package:super_logger/utils/value_controller.dart';

class ChoiceUiHelper extends BaseLoggableUiHelper {
  @override
  Widget getGeneralConfigForm({
    MappableObject? originalProperties,
    required ValueEitherValidOrErrController<MappableObject> propertiesController,
  }) {
    return ChoicePropertiesForm(
      propertiesController: propertiesController,
      choiceProperties: originalProperties as ChoiceProperties?,
    );
  }

  @override
  Widget getEditEntryValueWidget(
      MappableObject properties, ValueEitherController valueController, logValue,
      {bool forComposite = false, bool forDialog = false}) {
    if (logValue != null) valueController.setRightValue(logValue, notify: false);

    bool propertiesHaveLogId =
        (properties as ChoiceProperties).options.none((option) => option.id == logValue);

    // use slider only when the log option id is valid
    if (propertiesHaveLogId && properties.shouldUseSlider) {
      return ChoiceSlider(
        controller: valueController as ValueEitherController<String>,
        properties: properties,
        title: "",
      );
    } else {
      return Builder(
        builder: (context) => ChoiceDropdownButton(
          title: forComposite ? "" : context.l10n.selectedChoice,
          inlineTitle: forComposite,
          controller: valueController as ValueEitherController<String>,
          properties: properties,
        ),
      );
    }
  }

  @override
  Widget getTileTitleWidget(Log log, LoggableController<Object> controller) {
    return getDisplayLogValueWidget(log.value, properties: controller.loggable.loggableProperties);
  }

  @override
  Future<Log<Object>?> newLog(BuildContext context, LoggableController<Object> controller) async {
    ChoiceProperties properties = controller.loggable.loggableProperties as ChoiceProperties;

    final uiHelper = locator.get<MainFactory>().getUiHelper(properties.optionType);

    String? result;

    if (properties.shouldUseSlider) {
      result = await showChoiceSliderDialog(context, properties);
    } else {
      result = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
              title: Text(context.l10n.selectAnOption),
              children: properties.options.map(
                (choiceOption) {
                  final logValue = properties.options
                      .firstWhereOrNull((option) => option.id == choiceOption.id)
                      ?.value;

                  return SimpleDialogOption(
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: logValue == null
                          ? Text(context.l10n.loggableNotFound)
                          : uiHelper.getDisplayLogValueWidget(logValue),
                    ),
                    onPressed: () => Navigator.pop(context, choiceOption.id),
                  );
                },
              ).toList());
        },
      );
    }
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
    if (dateLog != null && dateLog.logs.isNotEmpty) {
      final id = (dateLog.logs.last as Log<String>).value;
      final properties = (loggableController.loggable.loggableProperties) as ChoiceProperties;
      final uiHelper = locator.get<MainFactory>().getUiHelper(properties.optionType);
      final logValue = properties.options.firstWhereOrNull((option) => option.id == id)?.value;
      if (logValue == null) {
        return Builder(
          builder: (context) {
            return Text(
              context.l10n.optionNotFoundErrorText,
              style: const TextStyle(
                color: Colors.red,
              ),
            );
          },
        );
      } else {
        return uiHelper.getDisplayLogValueWidget(logValue, size: LogDisplayWidgetSize.large);
      }
    } else {
      return const Text("No data");
    }
  }

  Widget _getCardDetailsLog(DateLog? dateLog, LoggableController controller, bool isCardSelected) {
    final properties = (controller.loggable.loggableProperties) as ChoiceProperties;
    final uiHelper = locator.get<MainFactory>().getUiHelper(properties.optionType);
    Widget mapper(context, log) {
      final id = (log as Log<String>).value;
      final logValue = properties.options.firstWhereOrNull((option) => option.id == id)?.value;
      if (logValue == null) {
        return const Text(
          "OPTION NOT FOUND",
          style: TextStyle(
            color: Colors.red,
          ),
        );
      } else {
        return uiHelper.getDisplayLogValueWidget(logValue, size: LogDisplayWidgetSize.small);
      }
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
  LoggableType get type => LoggableType.choice;

  @override
  Widget getDisplayLogValueWidget(dynamic logValue,
      {LogDisplayWidgetSize size = LoggableUiHelper.defaultLogDisplaySize,
      MappableObject? properties}) {
    if (properties == null) {
      return Text("Choice Id: $logValue");
    } else {
      final choiceProperties = properties as ChoiceProperties;
      final uiHelper = locator.get<MainFactory>().getUiHelper(choiceProperties.optionType);
      final optionValue =
          choiceProperties.options.firstWhereOrNull((option) => option.id == logValue);
      if (optionValue == null) {
        return const Text(
          "OPTION NOT FOUND",
          style: TextStyle(
            color: Colors.red,
          ),
        );
      } else {
        return uiHelper.getDisplayLogValueWidget(optionValue.value, size: size);
      }
    }
  }

  @override
  Widget getLogFilterForm(LogValueFilterController controller, MappableObject properties) {
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
  Widget? getDateLogFilterForm(DateLogValueFilterController controller, MappableObject properties) {
    return null;
  }
}
