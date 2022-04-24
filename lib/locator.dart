import 'package:get_it/get_it.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/core/repository/main_repository/drift/drift_repository.dart';
//import 'package:super_logger/features/audio/audio_factory.dart';
import 'package:super_logger/features/choice/choice_factory.dart';
import 'package:super_logger/features/color/color_factory.dart';
import 'package:super_logger/features/composite/composite_factory.dart';
import 'package:super_logger/core/main_controller.dart';
import 'package:super_logger/features/counter/counter_factory.dart';
import 'package:super_logger/features/duration/duration_factory.dart';
import 'package:super_logger/features/image/image_factory.dart';
import 'package:super_logger/features/internet_image/internet_image_factory.dart';
import 'package:super_logger/features/number/number_factory.dart';
import 'package:super_logger/features/text/text_factory.dart';
import 'core/repository/main_repository/main_repository.dart';

final locator = GetIt.instance;

void init() {
  locator.registerLazySingleton<MainRepository>(() => DriftRepository());

  locator
      .registerLazySingleton<MainController>(() => MainController(locator.get<MainRepository>()));

      

  locator.registerLazySingleton<MainFactory>(
    () => MainFactory(
      [
        CounterFactory(),
        NumberFactory(),
        CompositeFactory(),
        ChoiceFactory(),
        ColorFactory(),
        DurationFactory(),
        TextFactory(),
        ImageFactory(),
        InternetImageFactory(),
        //AudioFactory(),
        //LocationFactory()
      ],
    ),
  );
}
