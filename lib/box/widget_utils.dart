import 'package:flutter/material.dart';

import 'data_classes.dart';

//     showDialog(
//         context: context,
//         builder: (BuildContext context) => AlertDialog(
//               title: Text("${codeBlock.name}:"),
// // content: _makeMenuWidget(items, context, dialogTitle),
//             )).then((value) => {_resetElementsHoverState()});

Widget makeMenuWidget(Map<String, dynamic> itemsMap, BuildContext context,
    String dialogTitle, Function(dynamic) onItemSelected) {

  List<Widget> menuItems = [];
  for (var key in itemsMap.keys) {
    menuItems.add(InkWell(
      child: Container(
          width: 240,
          padding:
              const EdgeInsets.only(top: 8, bottom: 8, left: 15, right: 17),
          child: Text(key)),
      onTap: () {
        onItemSelected.call(itemsMap[key]);
        Navigator.pop(context, dialogTitle);
      },
    ));
  }
  return Container(
      alignment: Alignment.centerLeft,
      height: itemsMap.length * 36,
      child: Column(children: menuItems));
}


class ElementPainter extends CustomPainter {
  List<ScreenElement> elements = [];

  ElementPainter(this.elements);

  @override
  void paint(Canvas canvas, Size size) async {
    var paint = Paint()..style = PaintingStyle.stroke;
    for (var element in elements) {
      paint.strokeWidth = element.inEdit ? 2 : 5;
      paint.color = element.inEdit ? Colors.black : element.color;
      canvas.drawRect(element.functionalArea, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}