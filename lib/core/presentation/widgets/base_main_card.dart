import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:super_logger/core/loggable_controller.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/datelog.dart';
import 'package:super_logger/core/presentation/screens/loggable_details/loggable_details_screen.dart';
import 'package:super_logger/core/presentation/screens/create_loggable/create_loggable_screen.dart';
import 'package:super_logger/core/presentation/screens/home/widgets/card_date_list.dart';
import 'package:super_logger/core/presentation/widgets/value_shimmer.dart';
import 'dart:math' as math;

import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';

typedef CardValueWidget = Widget Function(DateLog, LoggableController, bool isCardSelected);

class BaseMainCard extends StatefulWidget {
  const BaseMainCard({
    Key? key,
    required this.loggable,
    required this.date,
    required this.state,
    required this.onTap,
    required this.onLongPress,
    required this.onNoLogs,
    required this.onLogDeleted,
    required this.cardValue,
    required this.cardLogDetails,
    this.primaryButton,
    this.secondaryButton,
    this.color,
  }) : super(key: key);

  final Loggable loggable;
  final CardState state;
  final DateTime date;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final void Function(Loggable) onNoLogs;
  final OnLogDelete onLogDeleted;

  final Widget Function(DateLog?, LoggableController controller, bool isCardSelected)
      cardLogDetails;
  final CardValueWidget cardValue;

  // usually used for adding actions
  final Widget? Function(LoggableController controller)? primaryButton;

  // usually used for deleting logs
  final Widget? Function(LoggableController controller, OnLogDelete onLogDelete)? secondaryButton;

  final Color? color;

  @override
  State<BaseMainCard> createState() => _BaseMainCardState();
}

class _BaseMainCardState extends State<BaseMainCard> {
  final bool showTime = false;
  late LoggableController loggableController;
  late LoggableUiHelper loggableHelper;

  bool get isCardSelected => widget.state == CardState.selected;
  bool get isCardToggled => widget.state == CardState.toggled;

  bool _wasPinned = false;

  bool _showHour = true;

  String timeAgoString = "";

  final ValueNotifier<int?> _latestLogTime = ValueNotifier(null);

  Widget hourWidget() {
    // final timeWidget = TimeBuilder.eachSecond(
    //   builder: (context, time, w, t) {
    //     if (w % 8 == 0) {
    //       _showHour = !_showHour;
    //       final timeDiff = DateTime.now()
    //           .difference(DateTime.fromMillisecondsSinceEpoch(_latestLogTime.value! * 1000));
    //       timeAgoString = timeDiff.inHours > 0
    //           ? context.l10n.xHoursAgo(timeDiff.inHours)
    //           : timeDiff.inMinutes > 0
    //               ? context.l10n.xMinutesAgo(timeDiff.inMinutes)
    //               : context.l10n.xSecondsAgo(timeDiff.inSeconds);
    //     }
    //     return PageTransitionSwitcher(
    //       duration: kThemeAnimationDuration,
    //       reverse: _showHour,
    //       child: Padding(
    //         key: ValueKey(_showHour),
    //         padding: const EdgeInsets.only(left: 11),
    //         child: _showHour
    //             ? Text(
    //                 //'•   ' +
    //                 DateTime.fromMillisecondsSinceEpoch(_latestLogTime.value! * 1000)
    //                     .formattedTimeHM,
    //                 style: TextStyle(
    //                   fontSize: 12,
    //                   color: context.colors.onBackground.withOpacity(0.5),
    //                 ),
    //               )
    //             : Text(
    //                 timeAgoString,
    //                 style: TextStyle(
    //                   fontSize: 12,
    //                   color: context.colors.onBackground.withOpacity(0.5),
    //                 ),
    //               ),
    //       ),
    //       transitionBuilder: (child, animation, secondaryAnimation) {
    //         return SharedAxisTransition(
    //           fillColor: Colors.transparent,
    //           animation: animation,
    //           secondaryAnimation: secondaryAnimation,
    //           child: child,
    //           transitionType: SharedAxisTransitionType.vertical,
    //         );
    //       },
    //     );
    //   },
    // );

    return AnimatedSize(
      curve: Curves.easeOutCubic,
      //alignment: Alignment.centerLeft,
      duration: kThemeAnimationDuration * 2,
      child: ValueListenableBuilder<int?>(
        valueListenable: _latestLogTime,
        builder: (context, value, child) {
          final bool showTime = widget.state != CardState.selected && _latestLogTime.value != null;
          return TweenAnimationBuilder<double>(
            duration: showTime ? kThemeAnimationDuration * 3 : kThemeAnimationDuration * 4,
            tween: showTime ? Tween(begin: 1, end: 0) : Tween(begin: 0, end: 1),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              // fully hidden
              if (value == 1) return const SizedBox.shrink();

              return Transform.translate(
                offset: Offset(-5 * value, 0),
                child: Opacity(
                  opacity: (1 - value).clamp(0, 1),
                  child: child,
                ),
              );
            },
            child: _latestLogTime.value == null
                ? const SizedBox.shrink()
                : Padding(
                    key: ValueKey(_showHour),
                    padding: const EdgeInsets.only(
                      bottom: 1, // fix little disalignment in widgetSpan
                    ),
                    child: Text(
                      '  •  ' +
                          DateTime.fromMillisecondsSinceEpoch(_latestLogTime.value! * 1000)
                              .formattedTimeHM,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.onBackground.withOpacity(0.5),
                      ),
                    )),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loggableController = locator.get<MainFactory>().makeLoggableController(widget.loggable);
    loggableHelper = locator.get<MainFactory>().getUiHelper(widget.loggable.type);
    loggableController.setupDateLogStream(widget.date);
  }

  @override
  void dispose() {
    loggableController.dispose();
    super.dispose();
  }

  Future<void> _refreshCard() async {
    await loggableController.refreshLoggable();
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant BaseMainCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // the current loggable could be outdated
    if (oldWidget.loggable != widget.loggable) {
      _refreshCard();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? primaryButton = widget.primaryButton?.call(loggableController);
    Widget? secondaryButton = widget.secondaryButton?.call(loggableController, widget.onLogDeleted);
    // int mainFlex = 1;
    // if (primaryButton != null) {
    //   mainFlex = secondaryButton != null ? 6 : 8;
    // }
    // if (secondaryButton != null) {
    //   mainFlex = primaryButton != null ? 6 : 8;
    // }

    bool isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    final bool isPinned = loggableController.loggable.loggableSettings.pinned;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: kThemeAnimationDuration,
          //height: 80.0,
          margin: EdgeInsets.fromLTRB(20, isCardSelected ? 5 : 10, 20, isCardSelected ? 5 : 10),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            border: loggableController.loggable.isNew
                ? Border.all(color: context.colors.primary.withOpacity(0.4), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? isCardSelected
                        ? Colors.black12
                        : Colors.transparent
                    : isCardSelected
                        ? context.colors.primary.darken(20).withOpacity(0.26)
                        : context.colors.primary.darken(20).withOpacity(0.12),
                spreadRadius: isCardSelected ? -6 : -3,
                blurRadius: isCardSelected ? 32 : 16,
                offset: Offset(0, isCardSelected ? 6 : 3),
              ),
              // const BoxShadow(
              //   color: Colors.black12,
              //   spreadRadius: -3,
              //   blurRadius: 16,
              //   offset: Offset(0, 3),
              // ),
              /*BoxShadow(
                              color: Color(0x10000000),
                              //spreadRadius: -3,
                              blurRadius: 2,
                              offset: Offset(0, 0),
                            ),*/
            ],
          ),
          child: Material(
            color: widget.color ?? context.colors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            //clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Positioned.fill(
                //   child: Center(
                //     child: Icon(
                //       Icons.check_rounded,
                //       size: 96,
                //       color: Colors.green.withOpacity(0.3),
                //     ),
                //   ),
                // ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  splashColor: context.colors.secondary.withAlpha(10),
                  onTap: widget.onTap,
                  onLongPress: widget.onLongPress,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      //crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            if (loggableController.loggable.loggableSettings.symbol.isNotEmpty)
                              Container(
                                height: 64,
                                width: 64,
                                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                decoration: BoxDecoration(
                                    color: context.colors.primary.withOpacity(0.06),
                                    shape: BoxShape.circle
                                    //borderRadius: BorderRadius.circular(12),
                                    ),
                                padding: const EdgeInsets.all(8),
                                child: FittedBox(
                                  child: Text(
                                    loggableController.loggable.loggableSettings.symbol,
                                    style: TextStyle(color: Theme.of(context).primaryColor),
                                  ),
                                ),
                              ),
                            Expanded(
                              //flex: mainFlex,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: <Widget>[
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(bottom: 2),
                                            child: RichText(
                                              text: TextSpan(
                                                children: <InlineSpan>[
                                                  if (loggableController.loggable.isNew)
                                                    WidgetSpan(
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color: context.colors.primary,
                                                          borderRadius: BorderRadius.circular(22),
                                                        ),
                                                        padding: const EdgeInsets.symmetric(
                                                            vertical: 4, horizontal: 6),
                                                        margin: const EdgeInsets.only(right: 8),
                                                        child: Text(
                                                          context.l10n.newLoggableBadge,
                                                          style: TextStyle(
                                                              color: Theme.of(context)
                                                                  .colorScheme
                                                                  .onPrimary,
                                                              fontSize: 11),
                                                        ),
                                                      ),
                                                    ),
                                                  TextSpan(
                                                    text: loggableController.loggable.title,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .subtitle1!
                                                        .copyWith(
                                                          fontWeight: isCardSelected
                                                              ? FontWeight.bold
                                                              : FontWeight.w500,
                                                          color: Color.lerp(
                                                                  Theme.of(context)
                                                                      .colorScheme
                                                                      .onBackground,
                                                                  Theme.of(context)
                                                                      .colorScheme
                                                                      .primary,
                                                                  0.4)!
                                                              .withOpacity(
                                                                  isCardSelected ? 0.7 : 0.6),
                                                        ),
                                                  ),
                                                  WidgetSpan(
                                                    child: hourWidget(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        //hourWidget(),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    // ======================  CARD VALUE  ======================
                                    StreamBuilder<DateLog?>(
                                        stream: loggableController.currentDateLog,
                                        builder: (context, snapshot) {
                                          if (snapshot.hasError) {
                                            return Text(
                                              context.l10n.error,
                                              style: const TextStyle(
                                                color: Colors.red,
                                              ),
                                            );
                                          }

                                          // call parent to remove this card IF it is no longer relevant
                                          if (snapshot.connectionState != ConnectionState.waiting &&
                                              snapshot.data == null) {
                                            // its empty, but we need to also check if it still relevant
                                            // by beeing pinned or something else
                                            // print(
                                            //     '{loggableController.loggable.creationDate}: ${loggableController.loggable.creationDate}');
                                            if (!loggableController.loggable.isNew &&
                                                !loggableController
                                                    .loggable.loggableSettings.pinned) {
                                              WidgetsBinding.instance!
                                                  .addPostFrameCallback((_) async {
                                                widget.onNoLogs(loggableController.loggable);
                                              });
                                            } else {
                                              WidgetsBinding.instance!
                                                  .addPostFrameCallback((_) async {
                                                _latestLogTime.value = null;
                                              });
                                            }
                                          }

                                          if (snapshot.data != null &&
                                              snapshot.data!.logs.isNotEmpty) {
                                            WidgetsBinding.instance!
                                                .addPostFrameCallback((_) async {
                                              _latestLogTime.value = snapshot.data!.logs.last
                                                      .timestamp.millisecondsSinceEpoch ~/
                                                  1000;
                                            });
                                          }

                                          return AnimatedCrossFade(
                                            firstChild: ValueShimmer(
                                              height: loggableController.loggable.type ==
                                                      LoggableType.composite
                                                  ? 64
                                                  : 32,
                                            ),
                                            secondChild: snapshot.data == null ||
                                                    snapshot.data!.logs.isEmpty
                                                ? Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(vertical: 6.0),
                                                    child: Text(
                                                      widget.date.isToday
                                                          ? context.l10n.noEventsToday
                                                          : context.l10n.noEvents,
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.7),
                                                        fontSize: 18,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  )
                                                : widget.cardValue(
                                                    snapshot.data!,
                                                    loggableController,
                                                    widget.state == CardState.selected),
                                            crossFadeState:
                                                snapshot.connectionState == ConnectionState.waiting
                                                    ? CrossFadeState.showFirst
                                                    : CrossFadeState.showSecond,
                                            duration: const Duration(milliseconds: 600),
                                            firstCurve: Curves.easeOut,
                                            secondCurve: Curves.easeInQuart,
                                            sizeCurve: Curves.easeOutQuad,
                                          );
                                          //return const MainCardValueShimmer();
                                        }),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (secondaryButton != null) secondaryButton,
                            // Expanded(
                            //   flex: 2,
                            //   child: secondaryButton,
                            // ),
                            if (primaryButton != null) primaryButton
                            // Expanded(
                            //   flex: 2,
                            //   child: primaryButton,
                            // ),
                          ],
                        ),
                        AnimatedCrossFade(
                          key: const ValueKey("main"),
                          firstChild: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StreamBuilder<DateLog?>(
                                  stream: loggableController.currentDateLog,
                                  builder: (context, snapshot) {
                                    return widget.cardLogDetails(snapshot.data, loggableController,
                                        widget.state == CardState.selected);
                                  }),
                              const SizedBox(
                                height: 4,
                              ),
                              OutlinedButton(
                                style: TextButton.styleFrom(
                                    backgroundColor: context.colors.primary.withAlpha(10)),
                                onPressed: () {
                                  final dateQueryParam =
                                      widget.date.isToday ? '' : '?date=${widget.date.asISO8601}';
                                  context.go(
                                      '/loggableDetails/${loggableController.loggable.id}$dateQueryParam');
                                },
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Center(child: Text(context.l10n.more)),
                                ),
                              ),
                            ],
                          ),
                          secondChild: const SizedBox(
                            width: double.maxFinite,
                          ),
                          crossFadeState:
                              isCardSelected ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          duration: const Duration(milliseconds: 300),
                          sizeCurve: Curves.easeOutQuad,
                        ),
                        AnimatedCrossFade(
                          firstChild: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              //children: [longPressWidget],
                              children: [
                                const SizedBox(
                                  height: 4,
                                ),
                                OutlinedButton(
                                  style: TextButton.styleFrom(
                                      backgroundColor: context.colors.primary.withAlpha(10)),
                                  onPressed: loggableController.isBusy
                                      ? null
                                      : () {
                                          if (isPinned) {
                                            _wasPinned = true;
                                          }
                                          loggableController.togglePin();
                                        },
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Center(
                                      child: Text(isPinned
                                          ? context.l10n.unpinLoggable
                                          : context.l10n.pinLoggable),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                OutlinedButton(
                                  style: TextButton.styleFrom(
                                      backgroundColor: context.colors.primary.withAlpha(10)),
                                  onPressed: () async {
                                    // context
                                    //     .go('/home/loggableDetails/${loggableController.loggable.id}');
                                    final ActionDone? action = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CreateLoggableScreen(
                                          loggableType: loggableController.loggable.type,
                                          loggable: loggableController.loggable,
                                        ),
                                      ),
                                    );

                                    //
                                    if (action != null) {
                                      if (action == ActionDone.update) {
                                        _refreshCard();
                                      }
                                    }
                                  },
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Center(child: Text(context.l10n.configureLoggable)),
                                  ),
                                )
                              ],
                            ),
                          ),
                          secondChild: const SizedBox(
                            width: double.maxFinite,
                          ),
                          crossFadeState:
                              isCardToggled ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          duration: const Duration(milliseconds: 300),
                          sizeCurve: Curves.easeOutQuad,
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if ((!isPinned && !_wasPinned) == false)
          AnimatedPositioned(
            duration: kThemeAnimationDuration,
            top: isCardSelected ? -1 : 4,
            left: 10,
            child: GestureDetector(
              onTap: widget
                  .onLongPress, // this action should be more clear.. it will set the card toggled
              child: TweenAnimationBuilder<double>(
                duration: isPinned ? kThemeAnimationDuration * 1.5 : kThemeAnimationDuration,
                tween: isPinned ? Tween(begin: 0, end: 1) : Tween(begin: 1, end: 0),
                curve: isPinned ? Curves.easeOutBack : Curves.easeInBack,
                builder: (context, value, child) {
                  if (value == 0) {
                    return const SizedBox.shrink();
                  } else {
                    return Transform.translate(
                      offset: Offset(-10 + value * 10, -5 + value * 5),
                      child: Transform.scale(
                        scale: value,
                        child: Transform.rotate(
                          angle: -math.pi / 2 + math.pi / 2 * value,
                          origin: const Offset(6, 6),
                          child: Opacity(
                            opacity: value.clamp(0, 1),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.date.isToday
                        ? context.colors.secondary.lighten(12)
                        : context.colors.secondary.lighten(12).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: widget.date.isToday
                        ? [
                            BoxShadow(
                              color: context.colors.primary.darken(10).withOpacity(0.4),
                              //spreadRadius: isCardSelected ? -6 : -3,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Transform.rotate(
                    angle: -math.pi / 4,
                    child: Icon(
                      Icons.push_pin,
                      size: 20,
                      color: context.colors.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          )
      ],
    );
  }
}

class MainCardButton extends StatelessWidget {
  const MainCardButton({
    Key? key,
    required this.loggableController,
    required this.onTap,
    required this.color,
    this.icon = Icons.add_rounded,
    this.shadowColor,
  }) : super(key: key);

  final LoggableController loggableController;
  final VoidCallback onTap;
  final Color color;
  final Color? shadowColor;
  final IconData icon;

  // @override
  // Widget build(BuildContext context) {
  //   return AnimatedBuilder(
  //       animation: loggableController,
  //       builder: (context, child) {
  //         return AnimatedContainer(
  //           duration: kThemeAnimationDuration * 2,
  //           margin: loggableController.isBusy
  //               ? const EdgeInsets.all(6)
  //               : const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
  //           curve: Curves.easeOutBack,
  //           decoration: BoxDecoration(
  //               color: loggableController.isBusy ? Colors.grey : color,
  //               borderRadius: const BorderRadius.all(Radius.circular(10)),
  //               boxShadow: shadowColor != null
  //                   ? [
  //                       BoxShadow(
  //                         color: loggableController.isBusy ? Colors.black26 : shadowColor!,
  //                         spreadRadius: loggableController.isBusy ? 0 : -2,
  //                         blurRadius: loggableController.isBusy ? 4 : 12,
  //                         offset: Offset(0, loggableController.isBusy ? 2 : 6),
  //                       ),
  //                     ]
  //                   : null),
  //           //alignment: Alignment.center,
  //           child: Material(
  //             clipBehavior: Clip.antiAlias,
  //             color: Colors.transparent,
  //             borderRadius: BorderRadius.circular(10),
  //             child: InkWell(
  //               //enableFeedback: true,
  //               borderRadius: BorderRadius.circular(10),
  //               splashColor: Colors.white.withOpacity(0.2),
  //               splashFactory:
  //                   loggableController.isBusy ? NoSplash.splashFactory : InkRipple.splashFactory,
  //               onTap: loggableController.isBusy ? () {} : onTap,
  //               child: LayoutBuilder(builder: (context, constrains) {
  //                 return Padding(
  //                   padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
  //                   //padding: const EdgeInsets.all(4),
  //                   child: Icon(icon, color: Colors.white),
  //                 );
  //               }),
  //             ),
  //           ),
  //         );
  //       });
  // }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: loggableController,
        builder: (context, child) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4),
            child: Ink(
              // decoration: ShapeDecoration(
              //   color: color,
              //   shape: const CircleBorder(),
              //   shadows: [
              //     BoxShadow(
              //       color: color.withOpacity(0.32),
              //       blurRadius: 4,
              //       offset: const Offset(0, 2),
              //     ),
              //   ],
              // ),
              child: IconButton(
                color: loggableController.isBusy ? null : color,
                //color: Colors.white,
                icon: Icon(icon),
                onPressed: loggableController.isBusy
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        onTap();
                      },
              ),
            ),
          );
        });
  }
}

class MainItemCardShimmer extends StatelessWidget {
  const MainItemCardShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double containerHeight = 15;

    const BoxDecoration boxDecoration = BoxDecoration(
      color: Colors.grey,
      borderRadius: BorderRadius.all(Radius.circular(4)),
    );

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F4F6),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Shimmer.fromColors(
        highlightColor: Colors.grey[100]!,
        baseColor: Colors.grey[300]!,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: containerHeight * 1.4,
                    width: 180,
                    decoration: boxDecoration,
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: containerHeight,
                    width: 80,
                    decoration: boxDecoration,
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: containerHeight,
                    width: 80,
                    decoration: boxDecoration,
                  )
                ],
              ),
            ),
            Container(
              height: 54,
              width: 54,
              decoration:
                  BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(16)),
            )
          ],
        ),
      ),
    );
  }
}
