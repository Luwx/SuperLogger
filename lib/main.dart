import 'dart:async';

import 'package:animations/animations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
//import 'package:local_hero/local_hero.dart';

//import 'package:google_fonts/google_fonts.dart';

import 'package:super_logger/core/presentation/screens/loggable_details/loggable_details_screen.dart';
import 'package:super_logger/core/presentation/screens/home/home_screen.dart';
import 'package:super_logger/core/presentation/screens/loggable_list/loggable_list_screen.dart';
import 'package:super_logger/core/presentation/screens/timeline/timeline_screen.dart';
import 'package:super_logger/l10n/l10n.dart';

import 'package:flex_color_scheme/flex_color_scheme.dart';

import 'locator.dart' as locator;

void main() async {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Pass all uncaught errors from the framework to Crashlytics.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  //timeDilation = 10.0;

  locator.init();

  runZonedGuarded(
    () => runApp(ProviderScope(child: SuperLogger())),
    (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack),
  );
}

class SuperLogger extends StatelessWidget {
  SuperLogger({Key? key}) : super(key: key);
  final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        //builder: (context, state) => const HomeScreen(),
        pageBuilder: (context, state) => CustomTransitionPage(
          opaque: false,
          child: const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SharedAxisTransition(
              // fillColor: MediaQuery.of(context).platformBrightness == Brightness.light
              //     ? context.colors.primary
              //     : null,
              //fillColor: Theme.of(context).canvasColor.withOpacity(0.5),
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.scaled,
              child: child,
            );
          },
        ),
        routes: [
          GoRoute(
              path: 'loggableDetails/:id',
              pageBuilder: (context, state) {
                final loggableId = state.params['id']!;
                final date = state.queryParams['date'];
                return CustomTransitionPage(
                    opaque: false,
                    child: LoggableDetailsScreen(
                      loggableId: loggableId,
                      date: date,
                    ),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SharedAxisTransition(
                        //fillColor: Colors.transparent,
                        animation: animation,
                        secondaryAnimation: secondaryAnimation,
                        transitionType: SharedAxisTransitionType.scaled,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24 - 24 * animation.value),
                          child: child,
                        ),
                      );
                    });
              }),
          GoRoute(
            path: 'loggables',
            builder: (context, state) => const LoggablesScreen(),
          ),
          GoRoute(
            path: 'timeline',
            builder: (context, state) => const TimelineScreen(),
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    //timeDilation = 10;

    //const FlexScheme usedScheme = FlexScheme.mandyRed;

    const flsb = FlexSubThemesData(
      useTextTheme: true,
      fabUseShape: true,
      interactionEffects: true,
      bottomNavigationBarOpacity: 0,
      bottomNavigationBarElevation: 0,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      inputDecoratorUnfocusedHasBorder: true,
      blendOnColors: true,
      blendTextTheme: true,
      //popupMenuOpacity: 0.95,
    );

    final fl = FlexThemeData.light(
      //textTheme: GoogleFonts.montserratTextTheme(Theme.of(context).textTheme),
      //fontFamily: GoogleFonts.neue().fontFamily,
      scheme: FlexScheme.indigo,
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
      blendLevel: 5,
      appBarStyle: FlexAppBarStyle.primary,
      appBarOpacity: 1,
      appBarElevation: 0,
      transparentStatusBar: true,
      tabBarStyle: FlexTabBarStyle.forAppBar,
      tooltipsMatchBackground: true,
      swapColors: false,
      //lightIsWhite: false,
      useSubThemes: true,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      // To use playground font, add GoogleFonts package and uncomment:
      // fontFamily: GoogleFonts.notoSans().fontFamily,
      subThemesData: flsb,
    );

    return MaterialApp.router(
      title: 'Super Logger',
      supportedLocales: L10n.all,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
      theme: fl.copyWith(
        inputDecorationTheme: fl.inputDecorationTheme.copyWith(
          hintStyle: fl.inputDecorationTheme.hintStyle?.copyWith(
                color: fl.colorScheme.onPrimary.withOpacity(0.1),
              ) ??
              TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: fl.colorScheme.onBackground.withOpacity(0.4),
              ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(flsb.defaultRadius ?? 12)),
            borderSide: BorderSide(
              color: fl.colorScheme.onSurface.withOpacity(0.04),
            ),
          ),
        ),
      ),
      darkTheme: FlexThemeData.dark(
        scheme: FlexScheme.indigo,
        surfaceMode: FlexSurfaceMode.highSurfaceLowScaffold,
        blendLevel: 32,
        appBarStyle: FlexAppBarStyle.background,
        appBarOpacity: 1,
        appBarElevation: 0,
        transparentStatusBar: true,
        tabBarStyle: FlexTabBarStyle.forAppBar,
        tooltipsMatchBackground: true,
        swapColors: true,
        darkIsTrueBlack: false,
        useSubThemes: true,
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        // To use playground font, add GoogleFonts package and uncomment:
        //fontFamily: GoogleFonts.nunito().fontFamily,
        subThemesData: const FlexSubThemesData(
          useTextTheme: true,
          fabUseShape: true,
          interactionEffects: true,
          bottomNavigationBarOpacity: 0,
          bottomNavigationBarElevation: 0,
          inputDecoratorIsFilled: true,
          //inputDecoratorRadius: 28,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          inputDecoratorUnfocusedHasBorder: false,
          blendOnColors: true,
          blendTextTheme: true,
          //popupMenuOpacity: 0.95,
        ),
      ),

      themeMode: ThemeMode.system,

// --- Theme related

      // theme: FlexThemeData.light(
      //   scheme: FlexScheme.indigo,
      //   surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
      //   blendLevel: 5,
      //   appBarOpacity: 0.95,
      //   subThemesData: const FlexSubThemesData(
      //     blendOnLevel: 20,
      //     blendOnColors: false,
      //     inputDecoratorRadius: 28.0,
      //     inputDecoratorUnfocusedHasBorder: false,
      //   ),
      //   keyColors: const FlexKeyColors(
      //     useSecondary: true,
      //     useTertiary: true,
      //     keepSecondary: true,
      //     keepTertiary: true,
      //   ),
      //   visualDensity: FlexColorScheme.comfortablePlatformDensity,
      //   useMaterial3: true,
      //   // To use the playground font, add GoogleFonts package and uncomment
      //   // fontFamily: GoogleFonts.notoSans().fontFamily,
      // ),
      // darkTheme: FlexThemeData.dark(
      //   scheme: FlexScheme.indigo,
      //   surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffoldVariantDialog,
      //   blendLevel: 28,
      //   appBarStyle: FlexAppBarStyle.background,
      //   appBarOpacity: 0.90,
      //   subThemesData: const FlexSubThemesData(
      //     blendOnLevel: 15,
      //     inputDecoratorRadius: 28.0,
      //     inputDecoratorUnfocusedHasBorder: false,
      //   ),
      //   keyColors: const FlexKeyColors(
      //     useSecondary: true,
      //     useTertiary: true,
      //     keepSecondary: true,
      //     keepSecondaryContainer: true,
      //   ),
      //   visualDensity: FlexColorScheme.comfortablePlatformDensity,
      //   useMaterial3: true,
      //   // To use the playground font, add GoogleFonts package and uncomment
      //   fontFamily: GoogleFonts.notoSans().fontFamily,
      // ),

// ---

      routeInformationParser: _router.routeInformationParser,
      routerDelegate: _router.routerDelegate,
    );
  }
}

class SharedAxisTransitionPageWrapper extends Page {
  const SharedAxisTransitionPageWrapper({required this.screen, required this.transitionKey})
      : super(key: transitionKey);

  final Widget screen;
  final ValueKey transitionKey;

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
        settings: this,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            fillColor: Theme.of(context).cardColor,
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.scaled,
            child: child,
          );
        },
        pageBuilder: (context, animation, secondaryAnimation) {
          return screen;
        });
  }
}
