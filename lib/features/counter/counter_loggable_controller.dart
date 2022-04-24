import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/repository/main_repository/main_repository.dart';

class CounterLoggableController extends LoggableController<int> {
  CounterLoggableController(MainRepository repository, Loggable loggable)
      : super(loggable: loggable, repository: repository);

  @override
  void dispose() {
    //
    super.dispose();
  }

  int previousTotalCount = 0;
  int currentTotalCount = 0;
  @override
  void onSetupDateLogStream() {
    currentDateLog.listen((dateLog) {
      if (dateLog != null) {
        int old = currentTotalCount;
        currentTotalCount =
            (dateLog.logs.map((log) => log.value).reduce((value, element) => value + element));
        if (currentTotalCount != old) {
          previousTotalCount = old;
        }
      }
    });
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
