import 'dart:typed_data';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:structure_compositor/box/data_classes.dart';

import '../../box/app_utils.dart';
import '../../box/widget_utils.dart';
import 'fruits.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/rendering.dart';

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
    var screen = appFruits.selectedProject!.selectedScreen;
    var layout = screen?.selectedLayout;
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
                          value: screen?.isLauncher,
                          onChanged: screen!.isLauncher ? null : (checked) {
                                  for (var s in appFruits.selectedProject!.screens) {
                                    s.isLauncher = false;
                                  }
                                  screen.isLauncher = checked!;

                                  areasEditorFruit.onSelectedLayoutChanged.call(
                                      appFruits
                                          .selectedProject?.selectedScreen?.selectedLayout);
                                }),
                    ],
                  ),
                ),
                Container(
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(top: 12, right: 96),
                  child: IconButton(
                      onPressed: () {
                        appFruits.selectedProject?.selectedScreen?.layouts.remove(layout);
                        if(appFruits.selectedProject?.selectedScreen?.layouts.isEmpty == true){
                          appFruits.selectedProject?.screens.remove(screen);
                        }
                        var newSelectedScreen = appFruits.selectedProject!.screens.firstOrNull;
                        appFruits.selectedProject?.selectedScreen = newSelectedScreen;

                        if (screen!.isLauncher && newSelectedScreen != null) {
                          newSelectedScreen.isLauncher = true;
                        }

                        areasEditorFruit.onSelectedLayoutChanged
                            .call(appFruits.selectedProject?.selectedScreen?.selectedLayout);
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
                              getLayoutBundle()!, areasEditorFruit.lastArea),
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
      areasEditorFruit.lastArea = AreaBundle(
          Rect.fromPoints(event.localPosition, event.localPosition),
          getNextColor(getLayoutBundle()?.elements.length));
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    setState(() {
      // var element = getLayoutBundle()!.getActiveElement();
      areasEditorFruit.lastArea?.rect = Rect.fromPoints(
          areasEditorFruit.lastArea!.rect.topLeft, event.localPosition);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    var rect = areasEditorFruit.lastArea!.rect;
    if (rect.left.floor() == rect.right.floor() &&
        rect.top.floor() == rect.bottom.floor()) {
      setState(() {
        areasEditorFruit.resetData();
      });
    } else {
      areasEditorFruit.onNewArea.call(areasEditorFruit.lastArea!);
    }
  }

  Widget _buildLayoutsListWidget() {
    var layouts = appFruits.selectedProject!.screens.mapMany((screen)=>screen.layouts).toList();
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
        itemCount: layouts.length,
        itemBuilder: (BuildContext context, int index) {
          var layout = layouts[index];

          var borderColor = appFruits.selectedProject?.selectedScreen?.selectedLayout == layout
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
                      if(appFruits.selectedProject?.selectedScreen?.layouts.contains(layout)==true) {
                        appFruits.selectedProject?.selectedScreen
                            ?.selectedLayout = layout;
                      }else {
                        var newSelectedScreen = appFruits.selectedProject!.screens.firstWhere((screen) => screen.layouts.contains(layout));
                        appFruits.selectedProject?.selectedScreen = newSelectedScreen;
                        newSelectedScreen.selectedLayout = layout;
                      }
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
