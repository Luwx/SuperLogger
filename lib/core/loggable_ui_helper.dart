import 'package:flutter/widgets.dart';
import 'package:fpdart/fpdart.dart' show Option;
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/filters.dart';
import 'package:super_logger/core/models/log.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/core/presentation/screens/loggable_details/loggable_details_screen.dart';
import 'package:super_logger/core/presentation/screens/home/widgets/card_date_list.dart';
import 'package:super_logger/utils/value_controller.dart';

typedef OnLogDelete = void Function(Log, Loggable);

enum LogDisplayWidgetSize { small, medium, large }

typedef LogValueFilterController = ValueEitherController<Option<ValueFilter>>;
typedef DateLogValueFilterController = ValueEitherController<Option<DateLogFilter>>;

extension SizeHelper on LogDisplayWidgetSize {
  bool get isLarge => this == LogDisplayWidgetSize.large;
  bool get isMedium => this == LogDisplayWidgetSize.medium;
  bool get isSmall => this == LogDisplayWidgetSize.small;

  T when<T>({required T isSmall, required T isMedium, required T isLarge}) {
    switch (this) {
      case LogDisplayWidgetSize.small:
        return isSmall;
      case LogDisplayWidgetSize.medium:
        return isMedium;
      case LogDisplayWidgetSize.large:
        return isLarge;
    }
  }
}

abstract class LoggableUiHelper {
  LoggableType get type;

  /// defaults to medium
  static const defaultLogDisplaySize = LogDisplayWidgetSize.medium;

  Widget getGeneralConfigForm({
    MappableObject? originalProperties,
    required ValueEitherValidOrErrController<MappableObject> propertiesController,
  });

  Widget? getMainCardConfigForm({
    MappableObject? originalConfig,
    required ValueEitherValidOrErrController<MappableObject> configController,
  });

  Widget? getAggregationConfigForm({
    MappableObject? originalConfig,
    required ValueEitherValidOrErrController<MappableObject> configController,
  });

  Widget getLogFilterForm(LogValueFilterController controller, MappableObject properties);

  Widget? getDateLogFilterForm(DateLogValueFilterController controller, MappableObject properties);

  Widget? getLogSortForm(
      ValueEitherValidOrErrController<CompareLogs> controller, MappableObject properties);

  Widget? getDateLogSortForm(
      ValueEitherValidOrErrController<CompareDateLogs> controller, MappableObject properties);

  Widget getTileTitleWidget(Log log, LoggableController controller);

  Widget getDisplayLogValueWidget(dynamic logValue,
      {LogDisplayWidgetSize size = defaultLogDisplaySize, MappableObject? properties});

  // null value log means that the requester wants a value editing
  // widget with a default value, when there is no log
  /// @valueController is NOT set up at this moment
  /// @logValue can be NULL
  Widget getEditEntryValueWidget(
      MappableObject properties, ValueEitherController valueController, Object? logValue,
      {bool forComposite = false, bool forDialog = false});

  Widget getMainCard(
      {Key? key,
      required Loggable loggable,
      required DateTime date,
      required CardState state,
      required VoidCallback onTap,
      required VoidCallback onLongPress,
      required void Function(Loggable) onNoLogs,
      required OnLogDelete onLogDeleted});

  Future<Log<Object>?> newLog(BuildContext context, LoggableController controller);
}

abstract class BaseLoggableUiHelper implements LoggableUiHelper {

  @override
  Widget? getMainCardConfigForm({
    MappableObject? originalConfig,
    required ValueEitherValidOrErrController<MappableObject> configController,
  }) =>
      null;

  @override
  Widget? getAggregationConfigForm({
    MappableObject? originalConfig,
    required ValueEitherValidOrErrController<MappableObject> configController,
  }) =>
      null;

  @override
  Widget? getDateLogFilterForm(
          DateLogValueFilterController controller, MappableObject properties) =>
      null;

  @override
  Widget? getLogSortForm(
          ValueEitherValidOrErrController<CompareLogs> controller, MappableObject properties) =>
      null;

  @override
  Widget? getDateLogSortForm(
          ValueEitherValidOrErrController<CompareDateLogs> controller, MappableObject properties) =>
      null;
}
