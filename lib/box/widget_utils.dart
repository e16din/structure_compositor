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

void showMenuDialog(BuildContext context, String title, Map<String, dynamic> itemsMap,
void Function(dynamic) onItemSelected) {
  dynamic selectedItem;
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            title: Text(title),
            content: makeMenuWidget(
                itemsMap, context, (selected) => {selectedItem = selected}));
      }).then((item) {
    onItemSelected(selectedItem);
  });
}

class ElementPainter extends CustomPainter {
  List<LayoutElement> elements = [];

  ElementPainter(this.elements);

  @override
  void paint(Canvas canvas, Size size) async {
    var paint = Paint()..style = PaintingStyle.stroke;
    for (var element in elements) {
      paint.strokeWidth = element.isInEdit ? 2 : 5;
      paint.color = element.isInEdit ? Colors.black : element.color;
      canvas.drawRect(element.functionalArea, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ActionsPainter extends CustomPainter {
  LayoutBundle layout;
  CodeAction? activeAction;

  ActionsPainter(this.layout, this.activeAction);

  @override
  void paint(Canvas canvas, Size size) async {
    var paint = Paint()..style = PaintingStyle.stroke;

    if (activeAction != null) {
      paint.strokeWidth = 2;
      paint.color =layout.getElementByAction(activeAction!).elementColor;
      canvas.drawRect(activeAction!.layoutArea, paint);
    }

    for (var action in layout.actions) {
      paint.strokeWidth = 5;
      paint.color = layout.getElementByAction(action).elementColor;
      canvas.drawRect(action.layoutArea, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

final List<MaterialColor> _rainbowColors = <MaterialColor>[
  Colors.red,
  Colors.orange,
  Colors.yellow,
  Colors.green,
  Colors.lightBlue,
  Colors.blue,
  Colors.deepPurple
];

Color getNextColor(int? index) {
  var nextColorPosition = index ??= 0 % _rainbowColors.length;
  if (nextColorPosition == _rainbowColors.length) {
    nextColorPosition = 0;
  }
  return _rainbowColors[nextColorPosition].shade400;
}
