import 'package:flutter/material.dart';

class CustomAddWidgetGrid extends StatelessWidget {
  final List<Widget> children;
  //final positiveOnly;

  const CustomAddWidgetGrid({Key? key, required this.children})
      : super(key: key);

//   @override
//   _CustomAddWidgetState createState() => _CustomAddWidgetState();
// }
//
// class _CustomAddWidgetState extends State<CustomAddWidget> {

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
        children: <Widget>[
      Flexible(child: Container(),),
      _generateGrid(),
      Flexible(child: Container(),),
      ]
    );
  }

  Widget _generateGrid() {

    assert(children.length <= 6);

    double spacing = 14;

    List<Widget> row1Widgets = [];
    if (children.length <= 3) {
      bool first = true;
      for (Widget child in children) {
        if(first){ first = false;}
        else {row1Widgets.add(SizedBox(width: spacing));}
        row1Widgets.add(Expanded(child: child));
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: row1Widgets,
      );
    }
    else {
      List<Widget> row2Widgets = [];
      if (children.length == 4) {
        row1Widgets.add(Expanded(child: children[0]));
        row1Widgets.add(SizedBox(width: spacing));
        row1Widgets.add(Expanded(child: children[1]));
        row2Widgets.add(Expanded(child: children[2]));
        row2Widgets.add(SizedBox(width: spacing));
        row2Widgets.add(Expanded(child: children[3]));
      }
      else {
        for (int i = 0; i < 3; i++) {
          if (i != 0) row1Widgets.add(SizedBox(width: spacing));
          row1Widgets.add(Expanded(child: children[i]));
        }
        for (int i = 3; i < children.length; i++) {
          if (i != 3) row2Widgets.add(SizedBox(width: spacing));
          row2Widgets.add(Expanded(child: children[i]));
        }
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: row1Widgets,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: row2Widgets,
          )
        ],
      );
    }
  }

  // Widget _customValueButton(int value) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 8),
  //     child: TextButton(
  //       /*style: ButtonStyle(
  //         backgroundColor: MaterialStateProperty.all(
  //             value > 0 ? Colors.green[50] : Colors.red[50]),
  //         shape: MaterialStateProperty.all<RoundedRectangleBorder>(
  //           RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(18.0),
  //             //side: BorderSide(color: Colors.green),
  //           ),
  //         ),
  //       ),*/
  //       style: TextButton.styleFrom(
  //         primary: value > 0 ? Colors.green : Colors.red,
  //         backgroundColor: value > 0 ? Colors.green[50] : Colors.red[50],
  //         minimumSize: Size(72, 34),
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(18.0),
  //           //side: BorderSide(color: Colors.green),
  //         ),
  //       ),
  //       child: Text(value.toString()),
  //       onPressed: (){
  //       },
  //     ),
  //   );
  // }
}
