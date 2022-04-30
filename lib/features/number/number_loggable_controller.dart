import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';

class ValueLoggableController extends LoggableController<double> {
  ValueLoggableController(MainRepository repository, Loggable loggable)
      : super(loggable: loggable, repository: repository);

  double previousTotalCount = 0;
  double currentTotalCount = 0;
}

class NumberUseCases {
  NumberUseCases._();
  // static MappableObject recalculateTotal(DateLog<int> datelog) {
  //   int total = 0;
  //   for (final log in datelog.logs) {
  //     total += log.value;
  //   }
  //   (datelog.properties as CounterDateLogProperties).totalCount = total;
  //   return datelog.properties;
  // }

  static double totalCountAtIndex(DateLog<double> dateLog, int index) {
    double total = 0;
    for (int i = 0; i <= index; i++) {
      total += dateLog.logs[i].value;
    }
    return total;
  }
}
