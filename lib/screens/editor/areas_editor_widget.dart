import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';
import 'package:structure_compositor/box/data_classes.dart';

import '../../box/app_utils.dart';
import '../../box/widget_utils.dart';
import 'fruits.dart';

class AreasEditorWidget extends StatefulWidget {
  const AreasEditorWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return AreasEditorState();
  }
}

class AreasEditorState extends State<AreasEditorWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var layout = appFruits.selectedProject!.selectedLayout;
    if (layout?.layoutBytes != null) {
      return Container(
        width: SCREEN_IMAGE_WIDTH,
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.only(left: 64),
                  width: 240,
                  child: TextFormField(
                    autofocus: true,
                    key: Key("${layout?.name.toString()}"),
                    initialValue: layout?.name,
                    decoration: const InputDecoration(labelText: "Layout Name"),
                    onChanged: (text) {
                      EasyDebounce.debounce(
                          'Layout Name', const Duration(milliseconds: 500), () {
                        layout?.name = text;
                        areasEditorFruit.onSelectedLayoutChanged.call(layout);
                      });
                    },
                  ),
                ),
                Container(
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(top: 17, right: 8),
                  child: Row(
                    children: [
                      const Text("isLauncher"),
                      Checkbox(
                          value: (layout as ScreenBundle).isLauncher,
                          onChanged: layout.isLauncher
                              ? null
                              : (checked) {
                                  for (var layout
                                      in appFruits.selectedProject!.layouts) {
                                    (layout as ScreenBundle).isLauncher = false;
                                  }
                                  layout.isLauncher = checked!;

                                  areasEditorFruit.onSelectedLayoutChanged.call(
                                      appFruits
                                          .selectedProject?.selectedLayout);
                                }),
                    ],
                  ),
                ),
                Container(
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(top: 12, right: 96),
                  child: IconButton(
                      onPressed: () {
                        appFruits.selectedProject?.layouts.remove(layout);
                        appFruits.selectedProject?.selectedLayout =
                            appFruits.selectedProject!.layouts.firstOrNull;

                        if (layout.isLauncher) {
                          (appFruits.selectedProject?.selectedLayout
                                  as ScreenBundle)
                              .isLauncher = true;
                        }

                        areasEditorFruit.onSelectedLayoutChanged
                            .call(appFruits.selectedProject?.selectedLayout);
                      },
                      icon: const Icon(Icons.delete_forever)),
                )
              ],
            ),
            Container(
              padding: const EdgeInsets.only(top: 64, bottom: 24),
              child: Stack(fit: StackFit.expand, children: [
                Image.memory(layout!.layoutBytes!, fit: BoxFit.contain),
                Listener(
                    onPointerDown: _onPointerDown,
                    onPointerUp: _onPointerUp,
                    onPointerMove: _onPointerMove,
                    child: MouseRegion(
                        cursor: SystemMouseCursors.precise,
                        child: CustomPaint(
                          painter: ActionsPainter(
                              getLayoutBundle()!,
                              areasEditorFruit.lastRect,
                              areasEditorFruit.lastColor),
                        )))
              ]),
            ),
            Container(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                alignment: Alignment.topRight,
                child: _buildLayoutsListWidget())
          ],
        ),
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
      decoration: BoxDecoration(
          border: Border.all(color: Colors.indigoAccent, width: 1),
          color: Colors.indigoAccent.withOpacity(0.21)),
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

          var borderColor = appFruits.selectedProject?.selectedLayout == layout
              ? Colors.indigoAccent
              : Colors.transparent;
          return Container(
              decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 4)),
              width: 50,
              child: Stack(
                children: [
                  InkWell(
                    child:
                        Image.memory(layout.layoutBytes!, fit: BoxFit.contain),
                    onTap: () {
                      appFruits.selectedProject?.selectedLayout = layout;
                      areasEditorFruit.onSelectedLayoutChanged.call(layout);
                    },
                  ),
                ],
              ));
        },
      ),
    );
  }
}
