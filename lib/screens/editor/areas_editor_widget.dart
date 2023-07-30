import 'package:flutter/material.dart';
import 'package:structure_compositor/box/data_classes.dart';

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

  var onNewArea = () {};
  var onSelectLayout = () {};

  void resetData() {
    lastRect = null;
    lastColor = null;
    lastElementId = null;
  }
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
      return Row(
        children: [
          Container(
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
                      ))),

              Container(alignment: Alignment.topRight, child: _buildLayoutsListWidget())
            ]),
          ),

        ],
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
          getNextColor(getLayoutBundle()?.elements.length);
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

  String _nextElementId() => 'element${getLayoutBundle()!.elements.length + 1}';

  Widget _buildLayoutsListWidget() {
    return Container(
      width: 96,
      decoration: BoxDecoration(border: Border.all(color: Colors.indigoAccent, width: 1), color: Colors.indigoAccent.withOpacity(0.21)),
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 21),
      child: ListView.separated(
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 16,
          endIndent: 24,
        ),
        scrollDirection: Axis.vertical,
        itemCount: appFruits.selectedProject!.layouts.length,
        itemBuilder: (BuildContext context, int index) {
          var layout = appFruits.selectedProject!.layouts[index];

          var borderColor = appFruits.selectedProject?.selectedLayout == layout ? Colors.indigoAccent : Colors.transparent;
          return InkWell(
            child: Container(
                decoration: BoxDecoration(border: Border.all(color: borderColor, width: 4)),
                width: 50,
                child: Image.memory(layout.layoutBytes!, fit: BoxFit.contain)),
            onTap: (){
              setState(() {
                appFruits.selectedProject?.selectedLayout = layout;
                areasEditorFruit.onSelectLayout.call();
              });
            },
          );
        },
      ),
    );
  }
}
