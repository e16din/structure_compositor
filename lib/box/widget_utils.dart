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

void showMenuDialog(BuildContext context, String title,
    Map<String, dynamic> itemsMap, void Function(dynamic) onItemSelected) {
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
    final paint = Paint()..style = PaintingStyle.stroke;
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
  Rect? lastRect;
  Color? lastColor;

  ActionsPainter(this.layout, this.lastRect, this.lastColor);

  @override
  void paint(Canvas canvas, Size size) async {
    final paint = Paint()..style = PaintingStyle.stroke;

    if (lastRect != null) {
      paint.strokeWidth = 5;
      paint.color = lastColor!;
      canvas.drawRect(lastRect!, paint);
    }
    for (var element in layout.getAllElements()) {
      if (layout.activeElement == element) {
        paint.strokeWidth = 5;
        paint.color = element.elementColor;
      } else {
        paint.strokeWidth = 3;
        paint.color = element.elementColor.withOpacity(0.82);
      }
      canvas.drawRect(element.area, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

final List<Color> rainbowColors = <Color>[
  // rainbow
  Colors.red,
  Colors.orange,
  Colors.yellow,
  Colors.green,
  Colors.cyan,
  Colors.blue,
  Colors.purple,
  // other
  Colors.grey,
  Colors.indigo,
  Colors.pink,
  Colors.brown,
  Colors.black,
  Colors.white,
];

Color getNextColor(int? index) {
  try {
    var nextColorPosition = index ??= 0 % rainbowColors.length;
    if (nextColorPosition == rainbowColors.length) {
      nextColorPosition = 0;
    }
    return rainbowColors[nextColorPosition].withOpacity(0.82);
  } on Exception {
    return rainbowColors.last.withOpacity(0.82);
  }
}
