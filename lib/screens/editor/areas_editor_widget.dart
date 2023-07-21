
import 'package:flutter/material.dart';

import '../../box/app_utils.dart';
import '../../box/widget_utils.dart';

class AreasEditorWidget extends StatefulWidget {
  const AreasEditorWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return AreasEditorState();
  }
}

class AreasEditorFruit {
  Rect? lastRect;
  Color? lastColor;
  String? lastElementId;

  var onNewArea = (){};
}

var areasEditorFruit = AreasEditorFruit();

class AreasEditorState extends State<AreasEditorWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var selectedLayout = appFruits.selectedProject!.selectedLayout;
    if (selectedLayout?.layoutBytes != null) {
      return Container(
        width: SCREEN_IMAGE_WIDTH,
        padding: const EdgeInsets.only(top: 42, bottom: 42),
        child: Stack(fit: StackFit.expand, children: [
          Image.memory(selectedLayout!.layoutBytes!, fit: BoxFit.contain),
          Listener(
              onPointerDown: _onPointerDown,
              onPointerUp: _onPointerUp,
              onPointerMove: _onPointerMove,
              child: MouseRegion(
                  cursor: SystemMouseCursors.precise,
                  child: CustomPaint(
                    painter: ActionsPainter(getLayoutBundle()!,
                        areasEditorFruit.lastRect, areasEditorFruit.lastColor),
                  )))
        ]),
      );
    } else {
      return Container(width: SCREEN_IMAGE_WIDTH, color: Colors.white);
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      areasEditorFruit.lastRect =
          Rect.fromPoints(event.localPosition, event.localPosition);
      areasEditorFruit.lastColor =
          getNextColor(getLayoutBundle()?.getAllElements().length);
      areasEditorFruit.lastElementId = _nextElementId();
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    setState(() {
      // var element = getLayoutBundle()!.getActiveElement();
      areasEditorFruit.lastRect = Rect.fromPoints(
          areasEditorFruit.lastRect!.topLeft, event.localPosition);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    var area = areasEditorFruit.lastRect!;
    if (area.left.floor() == area.right.floor() &&
        area.top.floor() == area.bottom.floor()) {
      setState(() {
        areasEditorFruit.lastRect = null;
        areasEditorFruit.lastColor = null;
        areasEditorFruit.lastElementId = null;
      });
    } else {
      areasEditorFruit.onNewArea.call();
    }
  }

  String _nextElementId() =>
      'element${getLayoutBundle()!.getAllElements().length + 1}';
}
