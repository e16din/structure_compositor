// import 'dart:convert';
// import 'dart:ffi';

// import 'dart:ffi';
// import 'dart:math';
// import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:developer' as developer;
// import 'package:file_picker/file_picker.dart';
import '../box/app_utils.dart';
import '../box/data_classes.dart';
import '../box/widget_utils.dart';

class ElementalEditorScreen extends StatelessWidget {
  const ElementalEditorScreen({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Structure Compositor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ElementalEditorPage(title: 'Structure Compositor: Code Editor'),
    );
  }
}

class ElementalEditorPage extends StatefulWidget {
  const ElementalEditorPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<ElementalEditorPage> createState() => _ElementalEditorPageState();
}

class _ElementalEditorPageState extends State<ElementalEditorPage> {

  Project makeNewProject() {
    return Project(name: "New Project");
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Row(
        children: [
          _buildActionsEditorWidget(),
          _buildActionsListWidget(),
          _buildFunctionalAreasWidget()
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){},
        tooltip: 'New project',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFunctionalAreasWidget() {
    var selectedLayout = appFruits.selectedProject!.selectedLayout;
    if (selectedLayout?.layoutBytes != null) {
      return Container(
        width: SCREEN_IMAGE_WIDTH,
        padding: const EdgeInsets.only(top: 42, bottom: 42),
        child: Stack(fit: StackFit.expand, children: [
          Image.memory(selectedLayout!.layoutBytes!,
              fit: BoxFit.contain),
          Listener(
              onPointerDown: _onPointerDown,
              onPointerUp: _onPointerUp,
              onPointerMove: _onPointerMove,
              child: MouseRegion(
                  cursor: SystemMouseCursors.precise,
                  child: CustomPaint(
                    painter:
                    ElementPainter(getLayoutBundle()!.elements),
                  )))
          // Column(
          //   children: [
          //     Container(
          //         alignment: Alignment.center,
          //         height: 42,
          //         child: Text(
          //           selectedScreenBundle!.name,
          //           style: const TextStyle(fontSize: 18),
          //         )),
          //   ],
          // ),
        ]),
      );
    } else {
      return Container(width: SCREEN_IMAGE_WIDTH, color: Colors.white);
    }
  }

  Rect? _lastRect;
  LayoutElement? _activeElement;

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _lastRect = Rect.fromPoints(event.localPosition, event.localPosition);
      _activeElement = LayoutElement(_lastRect!, getNextColor(getLayoutBundle()?.elements.length), true)
        ..name = 'element${getLayoutBundle()!.elements.length + 1}';

      getLayoutBundle()!.elements.add(_activeElement!);
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    setState(() {
      getLayoutBundle()!.elements.last.functionalArea =
          Rect.fromPoints(_lastRect!.topLeft, event.localPosition);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    var area = getLayoutBundle()!.elements.last.functionalArea;
    if (area.left.floor() == area.right.floor() &&
        area.top.floor() == area.bottom.floor()) {
      setState(() {
        getLayoutBundle()!.elements.removeLast();
      });
    }

    var element = _activeElement!;
    showDialog(
        context: context,
        builder: (context) {
          Map<String, ViewType> viewTypesMap = {};
          for (var viewType in ViewType.values) {
            viewTypesMap[viewType.viewName] = viewType;
          }

          return AlertDialog(
              title: const Text("Select view type:"),
              content: makeMenuWidget(viewTypesMap, context, (selected) {
                // _onViewTypeSelected(selected, element);
              }));
        }).then((item) {
      setState(() {
        _activeElement!.isInEdit = false;
      });
    });
  }

  Widget _buildActionsEditorWidget() {
    return ;
  }

  Widget _buildActionsListWidget() {
    return ;
  }
}
