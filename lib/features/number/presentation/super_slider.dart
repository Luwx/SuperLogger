import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';

enum _GridType { start, middle, end, remaining }

class HorizontalSlider extends StatefulWidget {
  final int initialValue;
  final int minValue;
  final int maxValue;
  final int step;

  /// The total width of the ruler
  final int widgetWidth;

  /// The height of the ruler
  final int widgetHeight;

  late final int gridCount;

  final int subGridCountPerGrid;

  late final int gridWidth;

  final int subGridWidth;

  late final int listViewItemCount;

  late final double paddingItemWidth;

  final void Function(int) onSelectedChanged;

  late final String Function(int)? scaleTransformer;

  final Color scaleColor;

  final Color indicatorColor;

  final Color scaleTextColor;

  late final int remainingValues;

  HorizontalSlider({
    Key? key,
    this.initialValue = 500,
    this.minValue = 100,
    this.maxValue = 900,
    this.step = 1,
    this.widgetWidth = 200,
    this.widgetHeight = 60,
    this.subGridCountPerGrid = 10,
    this.subGridWidth = 8,
    required this.onSelectedChanged,
    this.scaleTransformer,
    this.scaleColor = const Color(0xFFE9E9E9),
    this.indicatorColor = const Color(0xFF3995FF),
    this.scaleTextColor = const Color(0xFF8E99A0),
  }) : super(key: key) {
    assert(initialValue >= minValue && initialValue <= maxValue);

    // if (subGridCountPerGrid % 2 != 0) {
    //   throw Exception("subGridCountPerGrid");
    // }
    if ((maxValue - minValue) % step != 0) {
      throw Exception("(maxValue - minValue)");
    }
    int totalSubGridCount = (maxValue - minValue) ~/ step;
    //print("maxValue: " + maxValue.toString() + ", minValue: " + minValue.toString() + ", step:" + step.toString() + " and:" + ((maxValue - minValue) ~/ step).toString());
    if (totalSubGridCount > 1 && totalSubGridCount % subGridCountPerGrid != 0) {
      //throw Exception("(maxValue - minValue)~/step
      remainingValues = totalSubGridCount % subGridCountPerGrid;
      //print('has remaining: ' + remainingValues.toString());
    } else {
      remainingValues = 0;
    }

    gridCount = totalSubGridCount ~/ subGridCountPerGrid +
        ((remainingValues > 0 || totalSubGridCount == 1) ? 1 : 0);

    gridWidth = subGridWidth * subGridCountPerGrid;

    listViewItemCount = gridCount + 2;

    paddingItemWidth = widgetWidth / 2;

    scaleTransformer ??= (value) {
      return value.toString();
    };
  }

  @override
  _HorizontalSliderState createState() => _HorizontalSliderState();
}

class _HorizontalSliderState extends State<HorizontalSlider> {
  late ScrollController _scrollController;

  Future<void>? anim;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController(
      initialScrollOffset:
          (widget.initialValue - widget.minValue) / widget.step * widget.subGridWidth,
    );
  }

  @override
  void didUpdateWidget(HorizontalSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    //print('{_scrollController.offset}: ${_scrollController.offset}');
    // _scrollController.dispose();
    // _scrollController = ScrollController(
    //   initialScrollOffset:
    //       (widget.initialValue - widget.minValue) / widget.step * widget.subGridWidth,
    // );
    select(widget.initialValue, longAnimation: true);
    //print('{_scrollController.offset}: ${_scrollController.offset}');
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) {
        double fadeSizePercent = 20 / rect.width;
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          stops: [
            0,
            fadeSizePercent,
            1 - fadeSizePercent,
            1,
          ],
          colors: const [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstIn,
      child: SizedBox(
        width: widget.widgetWidth.toDouble(),
        height: widget.widgetHeight.toDouble(),
        child: Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            NotificationListener(
              onNotification: _onNotification,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                //padding: EdgeInsets.all(0),
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: widget.listViewItemCount,
                itemBuilder: (BuildContext context, int index) {
                  // Padding to the side, this centers the ruler
                  if (index == 0 || index == widget.listViewItemCount - 1) {
                    return SizedBox(
                      //color: Colors.amber,
                      width: widget.paddingItemWidth,
                      height: 0,
                    );
                  }

                  // Ruler contents
                  else {
                    // we'll determine the type of the grid
                    _GridType type;

                    // The two padding and a single ruler section (3 elements)
                    if (widget.listViewItemCount == 3) {
                      type = _GridType.end;
                    }

                    // The first section
                    else if (index == 1) {
                      type = _GridType.start;
                    }

                    // The remaining is the actual final section
                    else if (index == widget.listViewItemCount - 2) {
                      type = widget.remainingValues > 0 ? _GridType.remaining : _GridType.end;
                    } else if (index == widget.listViewItemCount - 3) {
                      type = widget.remainingValues > 0 ? _GridType.end : _GridType.middle;
                    }

                    //Common element in the middle
                    else {
                      type = _GridType.middle;
                    }

                    //   print("type" + type.toString() + ", " + (widget.minValue +
                    //       (index) *
                    //           widget.subGridCountPerGrid *
                    //           widget.step).toString());
                    // print("index: " + index.toString() + ", widget.subGridCountPerGrid: " + widget.subGridCountPerGrid.toString() + ", widget.step: " + widget.step.toString());
                    return NumberPickerItem(
                      subGridCount: type == _GridType.remaining
                          ? widget.remainingValues
                          : widget.subGridCountPerGrid,
                      subGridWidth: widget.subGridWidth,
                      itemHeight: widget.widgetHeight,
                      valueStr: widget.scaleTransformer!(
                          widget.minValue + (index - 1) * widget.subGridCountPerGrid * widget.step),
                      nextValue: widget.scaleTransformer!(
                          widget.minValue + index * widget.subGridCountPerGrid * widget.step),
                      type: type,
                      scaleColor: widget.scaleColor,
                      scaleTextColor: widget.scaleTextColor,
                    );
                  }
                },
              ),
            ),

            // indicator
            Container(
              width: 2,
              height: widget.widgetHeight / 2,
              decoration: BoxDecoration(
                  color: widget.indicatorColor,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2))),
            ),
          ],
        ),
      ),
    );
  }

  bool _onNotification(Notification notification) {
    if (notification is ScrollNotification) {
      //The nearest tick value to the middle of the widget
      int centerValue = (notification.metrics.pixels / widget.subGridWidth).round() * widget.step +
          widget.minValue;

      if (anim == null) {
        widget.onSelectedChanged(centerValue);
      }

      if (_scrollingStopped(notification, _scrollController)) {
        select(centerValue);
      }
    }

    return true;
  }

  bool _scrollingStopped(
    Notification notification,
    ScrollController scrollController,
  ) {
    return notification is UserScrollNotification &&
        notification.direction == ScrollDirection.idle &&
        scrollController.position.activity
            is! HoldScrollActivity; // see https://github.com/flutter/flutter/issues/14452
  }

  Future<void> select(int valueToSelect, {bool longAnimation = false}) async {
    if (!_scrollController.hasClients) return;
    //print("anim select");
    if (anim == null) {
      //print("anim start");
      anim = Future.value();
      anim = _scrollController.animateTo(
        (valueToSelect - widget.minValue) / widget.step * widget.subGridWidth,
        duration: Duration(milliseconds: longAnimation ? 600 : 200),
        curve: longAnimation ? Curves.easeInOutQuart : Curves.decelerate,
      );
      anim!.then((value) {
        anim = null;
        //print("anim end");
      });

    } else {
      await anim;
      if (_scrollController.hasClients) {
        anim = _scrollController.animateTo(
          (valueToSelect - widget.minValue) / widget.step * widget.subGridWidth,
          duration: Duration(milliseconds: longAnimation ? 300 : 200),
          curve: longAnimation ? Curves.easeInOutCubic : Curves.decelerate,
        );
        anim!.then((value) => anim = null);
      } else {
        anim = null;
      }
    }
  }
}

//------------------------------------------------------------------------------

class NumberPickerItem extends StatelessWidget {
  final int subGridCount;
  final int subGridWidth;
  final int itemHeight;
  final String valueStr;
  final String nextValue;

  final _GridType type;

  final Color scaleColor;
  final Color scaleTextColor;

  const NumberPickerItem({
    Key? key,
    required this.subGridCount,
    required this.subGridWidth,
    required this.itemHeight,
    required this.valueStr,
    required this.nextValue,
    required this.type,
    required this.scaleColor,
    required this.scaleTextColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double itemWidth = (subGridWidth * subGridCount).toDouble();
    double itemHeight = this.itemHeight.toDouble();

    return CustomPaint(
      size: Size(itemWidth, itemHeight),
      painter: MyPainter(subGridWidth, valueStr, nextValue, type, scaleColor, scaleTextColor),
    );
  }
}

class MyPainter extends CustomPainter {
  final int subGridWidth;

  final String valueStr;
  final String nextValue;

  final _GridType type;

  final Color scaleColor;

  final Color scaleTextColor;

  late Paint _linePaint;

  final double _lineWidth = 2;

  MyPainter(this.subGridWidth, this.valueStr, this.nextValue, this.type, this.scaleColor,
      this.scaleTextColor) {
    _linePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = _lineWidth
      ..strokeCap = StrokeCap.round
      ..color = scaleColor;
  }

  @override
  void paint(Canvas canvas, Size size) {
    drawLine(canvas, size);
    drawText(canvas, size);
    if (type == _GridType.end) drawText(canvas, size, isNextValue: true);
  }

  void drawLine(Canvas canvas, Size size) {
    double startX, endX;

    startX = 0;
    endX = size.width;

    //Draw a horizontal line
    canvas.drawLine(
        Offset(startX, 0 + _lineWidth / 2), Offset(endX, 0 + _lineWidth / 2), _linePaint);

    //Draw a vertical line
    for (double x = startX; x <= endX; x += subGridWidth) {
      if (x == startX && type != _GridType.remaining) {
        // Long scale
        canvas.drawLine(Offset(x, 0), Offset(x, size.height * 4 / 8), _linePaint);
      } else if (x + subGridWidth > endX && type == _GridType.end) {
        // Last Long scale
        canvas.drawLine(Offset(x, 0), Offset(x, size.height * 4 / 8), _linePaint);
      } else {
        // Short scale
        canvas.drawLine(Offset(x, 0), Offset(x, size.height / 4), _linePaint);
      }
    }
  }

  void drawText(Canvas canvas, Size size, {bool isNextValue = false}) {
    ui.Paragraph p = _buildText(isNextValue ? nextValue : valueStr, size.width + 20);
    double halfWidth = p.minIntrinsicWidth / 2;
    //double halfHeight = p.height / 2;
    canvas.drawParagraph(
        p, Offset((isNextValue ? size.width : 0) - halfWidth, size.height - p.height));
  }

  ui.Paragraph _buildText(String content, double maxWidth) {
    ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle());
    paragraphBuilder.pushStyle(
      ui.TextStyle(
        fontSize: 14,
        color: scaleTextColor,
        //fontFamily: "Montserrat",
      ),
    );
    paragraphBuilder.addText(content);

    ui.Paragraph paragraph = paragraphBuilder.build();
    paragraph.layout(ui.ParagraphConstraints(width: maxWidth));

    return paragraph;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class SuperSlider extends StatefulWidget {
  final double current;
  final double minValue;
  final double maxValue;
  final int step;

  final bool allowDecimal;

  final void Function(double) onSelectedChanged;

  const SuperSlider({
    Key? key,
    required this.current,
    required this.minValue,
    required this.maxValue,
    required this.step,
    this.allowDecimal = false,
    required this.onSelectedChanged,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SuperSliderState();
  }
}

class SuperSliderState extends State<SuperSlider> {
  //late int _selectedValue;

  double width = 500.0;
  final GlobalKey _globalKey = GlobalKey();

  // late final int _initialValue;
  // late final int _minValue;
  // late final int _maxValue;
  // late final int _gridWidth;

  final int _decimalPlaces = 1;

  int totalItemCount(double minValue, double maxValue) {
    if (widget.allowDecimal) {
      return ((maxValue - minValue) * pow(10, _decimalPlaces)).toInt();
    } else {
      return (maxValue - minValue).toInt();
    }
  }

  // make all values >= 0, shifts everything to the right
  double _convertToNaturalRange(double value) => value + widget.minValue.abs();

  // negative and positive values (original)
  double _convertToOriginalRange(double value) => value - widget.minValue.abs();

  // ex: 1.1 => 11
  double _convertFractionalToInt(double value) => value * pow(10, _decimalPlaces);

  // ex: 11 => 1.1
  double _convertIntToFractional(int value) => value.toDouble() / pow(10, _decimalPlaces);

  // handle initial value and max & min
  int _handleValue(double value) {
    double newValue = value;
    if (widget.minValue.isNegative) newValue = _convertToNaturalRange(value);
    if (widget.allowDecimal) newValue = _convertFractionalToInt(newValue.toDouble());

    return newValue.toInt();
  }

  double _reformat(int value) {
    double val = value.toDouble();
    if (widget.allowDecimal) {
      val = _convertIntToFractional(value); //val = val/pow(10, _decimalPlaces);}
    }
    if (widget.minValue.isNegative) val = _convertToOriginalRange(val);

    return val;
  }

  int _handleSubGridCount() {
    int distance = totalItemCount(widget.minValue, widget.maxValue);

    if (distance < 20) {
      return 2;
    } else if (distance < 30) {
      return 5;
    } else {
      return 10;
    }
  }

  int _handleSubGridWidth() {
    int distance = totalItemCount(widget.minValue, widget.maxValue);

    if (distance < 16) {
      return 22;
    } else if (distance < 30) {
      return 14;
    } else if (distance < 150) {
      return 8;
    } else {
      return 5;
    }
  }

  @override
  void initState() {
    super.initState();
    //_selectedValue = widget.initialValue;

    SchedulerBinding.instance!.addPostFrameCallback((timeStamp) {
      width = _globalKey.currentContext!.size!.width;
      //print('the new width is $width');
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    int numberPickerHeight = 60;
    return HorizontalSlider(
      key: _globalKey,
      initialValue: _handleValue(widget.current.toDouble()),
      minValue: _handleValue(widget.minValue),
      maxValue: _handleValue(widget.maxValue),
      step: 1,
      widgetWidth: width.toInt(),
      widgetHeight: numberPickerHeight,
      subGridCountPerGrid: _handleSubGridCount(),
      subGridWidth: _handleSubGridWidth(),
      scaleColor: Color.lerp(
          Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.background, 0.5)!,
      indicatorColor: Theme.of(context).colorScheme.primary,
      onSelectedChanged: (value) {
        widget.onSelectedChanged(_reformat(value).clamp(widget.minValue, widget.maxValue));
        // setState(() {
        //   _selectedValue = value;
        // });
      },
      scaleTransformer: (value) => formatIntegerStr(_reformat(value)),
    );
  }
}

/// 1.0 -> "1"
///
/// 1.2 -> "1.2"
String formatIntegerStr(num number) {
  int intNumber = number.truncate();
  if (intNumber == number) {
    return intNumber.toString();
  } else {
    return number.toString();
  }
}
