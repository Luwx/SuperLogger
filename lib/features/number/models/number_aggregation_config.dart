import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:super_logger/core/models/loggable.dart';

part 'number_aggregation_config.freezed.dart';
part 'number_aggregation_config.g.dart';

@freezed
class NumberAggregationConfig with _$NumberAggregationConfig implements AggregationConfig {
  const NumberAggregationConfig._();

  const factory NumberAggregationConfig({
    required bool showTotal,
    required bool showMin,
    required bool showMax,
    required bool showAvg,
    required bool showAvgPerDay,
  }) = _NumberAggregationConfig;

  factory NumberAggregationConfig.fromJson(Map<String, dynamic> json) =>
      _$NumberAggregationConfigFromJson(json);

  @override
  bool get hasAggregations => showTotal || showMin || showMax || showAvg || showAvgPerDay;
}
