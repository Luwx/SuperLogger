import 'package:collection/collection.dart';

import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';

class NumberHistory {
  final int previous;
  final int current;
  NumberHistory({
    required this.previous,
    required this.current,
  });
  bool get isIncreasing => current > previous;
}

class CounterLoggableController extends LoggableController<int> {
  CounterLoggableController(MainRepository repository, Loggable loggable)
      : super(loggable: loggable, repository: repository);

  @override
  void dispose() {
    //
    super.dispose();
  }

  Map<String, NumberHistory> totalCounts = {};
  NumberHistory updateTotalCounts(DateLog<int> dateLog) {
    final previous = totalCounts[dateLog.date];
    totalCounts[dateLog.date] = NumberHistory(
      previous: previous?.current ?? 0,
      current: dateLog.logs.map((log) => log.value).sum,
    );
    return totalCounts[dateLog.date]!;
  }
}

class CounterUseCases {
  CounterUseCases._();
  // static MappableObject recalculateTotal(DateLog<int> datelog) {
  //   int total = 0;
  //   for (final log in datelog.logs) {
  //     total += log.value;
  //   }
  //   (datelog.properties as CounterDateLogProperties).totalCount = total;
  //   return datelog.properties;
  // }

  static int totalCountAtIndex(DateLog<int> dateLog, int index) {
    int total = 0;
    for (int i = 0; i <= index; i++) {
      total += dateLog.logs[i].value;
    }
    return total;
  }
}
