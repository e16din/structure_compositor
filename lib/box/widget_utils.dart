import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'data_classes.dart';

const double SCREEN_IMAGE_WIDTH = 520;

//     showDialog(
//         context: context,
//         builder: (BuildContext context) => AlertDialog(
//               title: Text("${codeBlock.name}:"),
// // content: _makeMenuWidget(items, context, dialogTitle),
//             )).then((value) => {_resetElementsHoverState()});

Widget makeMenuWidget(Map<String, dynamic> itemsMap, BuildContext context,
    Function(dynamic) onItemSelected) {
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
        Get.back();
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
