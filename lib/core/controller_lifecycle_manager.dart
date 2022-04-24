// import 'package:super_logger/core/loggable_controller.dart';
// import 'package:super_logger/core/models/loggable.dart';
// import 'package:super_logger/core/repository/firebase/firebase_repository.dart';
// import 'package:super_logger/features/counter/counter_loggable_controller.dart';

// class _ControllerRef {
//   LoggableController controller;
//   int refCount;
//   _ControllerRef({
//     required this.controller,
//     required this.refCount,
//   });
// }

// class ControllerLifeCycleManager {
//   Map<String, _ControllerRef> loggableControllers = {};

//   LoggableController getLoggableController(Loggable loggable) {
//     var controllerRef = loggableControllers[loggable.id];
//     if (controllerRef == null) {
//       controllerRef = _ControllerRef(
//           controller: CounterLoggableController(FireRepository(), loggable), refCount: 1);
//     } else {
//       if (controllerRef.refCount > 5) {
//         throw Exception("A little hungry for controllers?");
//       } else {
//         controllerRef.refCount++;
//       }
//     }
//     return controllerRef.controller;
//   }

//   void removeLoggableController(LoggableController controller) {
//     final controllerRef = loggableControllers[controller.loggable.id];
//     if (controllerRef == null) {
//       throw Exception("Controller $controller not found");
//     }
//     if (controllerRef.refCount <= 1) {
//       loggableControllers.removeWhere((key, value) => key == controller.loggable.id);
//     } else {
//       controllerRef.refCount--;
//     }
//   }
// }
