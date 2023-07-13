// import 'dart:convert';
// import 'dart:ffi';

// import 'dart:ffi';
// import 'dart:math';
// import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:developer' as developer;
// import 'package:file_picker/file_picker.dart';
import '../box/app_utils.dart';
import '../box/data_classes.dart';
import '../box/widget_utils.dart';

class ActionsEditorScreen extends StatelessWidget {
  const ActionsEditorScreen({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Structure Compositor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ActionsEditorPage(title: 'Structure Compositor: Code Editor'),
    );
  }
}

class ActionsEditorPage extends StatefulWidget {
  const ActionsEditorPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<ActionsEditorPage> createState() => _ActionsEditorPageState();
}

final Rect _defaultArea =
    Rect.fromCenter(center: const Offset(100, 100), width: 100, height: 100);

class _ActionsEditorPageState extends State<ActionsEditorPage> {
  final List<ActionCodeBlock> _actionsCodeBlocks = [
    ActionCodeBlock(
        type: ActionCodeType.doOnInit,
        name: "doOnInit",
        isContainer: true,
        layoutArea: _defaultArea)
      ..color = Colors.deepPurpleAccent.withOpacity(0.7),
    ActionCodeBlock(
        type: ActionCodeType.doOnClick,
        name: "doOnClick",
        isContainer: true,
        layoutArea: _defaultArea)
      ..color = Colors.deepPurpleAccent.withOpacity(0.7),
    ActionCodeBlock(
        type: ActionCodeType.doOnDataChanged,
        name: "doOnDataChanged",
        isContainer: true,
        layoutArea: _defaultArea)
      ..color = Colors.deepPurpleAccent.withOpacity(0.7),
    ActionCodeBlock(
        type: ActionCodeType.showText,
        name: "showText",
        isContainer: false,
        layoutArea: _defaultArea),
    ActionCodeBlock(
        type: ActionCodeType.showImage,
        name: "showImage",
        isContainer: false,
        layoutArea: _defaultArea),
    ActionCodeBlock(
        type: ActionCodeType.showImage,
        name: "updateData",
        isContainer: false,
        layoutArea: _defaultArea),
    ActionCodeBlock(
        type: ActionCodeType.moveToNextScreen,
        name: "moveToNextScreen",
        isContainer: false,
        layoutArea: _defaultArea)
      ..color = Colors.green,
    ActionCodeBlock(
        type: ActionCodeType.moveToBackScreen,
        name: "moveToNextScreen",
        isContainer: false,
        layoutArea: _defaultArea)
      ..color = Colors.green,
    ActionCodeBlock(
        type: ActionCodeType.todo,
        name: "TODO",
        isContainer: false,
        layoutArea: _defaultArea)
      ..color = Colors.redAccent,
  ];

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
        onPressed: () {
          _onAddScreenPressed();
        },
        tooltip: 'Select layout',
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
          Image.memory(selectedLayout!.layoutBytes!, fit: BoxFit.contain),
          Listener(
              onPointerDown: _onPointerDown,
              onPointerUp: _onPointerUp,
              onPointerMove: _onPointerMove,
              child: MouseRegion(
                  cursor: SystemMouseCursors.precise,
                  child: CustomPaint(
                    painter: ActionsPainter(
                        getLayoutBundle()!.actions, _activeAction),
                  )))
        ]),
      );
    } else {
      return Container(width: SCREEN_IMAGE_WIDTH, color: Colors.white);
    }
  }

  ActionCodeBlock? _activeAction;

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      var lastRect = Rect.fromPoints(event.localPosition, event.localPosition);
      _activeAction = ActionCodeBlock(
          type: ActionCodeType.doOnInit,
          name: "unknownAction {}",
          isContainer: true,
          layoutArea: lastRect)
        ..color = getNextColor(getLayoutBundle()?.actions.length)
        ..id = 'element${getLayoutBundle()!.actions.length + 1}';
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    setState(() {
      _activeAction!.layoutArea = Rect.fromPoints(
          _activeAction!.layoutArea.topLeft, event.localPosition);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    var area = _activeAction!.layoutArea;
    if (area.left.floor() == area.right.floor() &&
        area.top.floor() == area.bottom.floor()) {
      setState(() {
        _activeAction = null;
      });
    }

    var action = _activeAction!;
    showDialog(
        context: context,
        builder: (context) {
          Map<String, ActionCodeBlock> actionsMap = {};
          for (var action in _actionsCodeBlocks.where((element) => element.isContainer)) {
            actionsMap["${action.name} { }"] = action;
          }

          return AlertDialog(
              title: const Text("Select action:"),
              content: makeMenuWidget(actionsMap, context, (selected) {
                _onActionTypeSelected(selected, action);
              }));
        }).then((item) {
      setState(() {
        _activeAction = null;
      });
    });
  }

  EditorType _selectedEditor = EditorType.actionsEditor;

  final List<bool> _editorTypeSelectorState = [true, false];

  Widget _buildActionsEditorWidget() {
    Widget content;
    switch (_selectedEditor) {
      case EditorType.actionsEditor:
        content = Container(
          width: 640,
          padding: const EdgeInsets.only(bottom: 110),
          child: ListView.separated(
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              indent: 16,
              endIndent: 24,
            ),
            scrollDirection: Axis.vertical,
            itemCount: (appFruits.selectedProject?.selectedLayout != null
                ? appFruits.selectedProject?.selectedLayout?.actions.length
                : 0)!,
            itemBuilder: (BuildContext context, int index) {
              var action =
                  appFruits.selectedProject?.selectedLayout?.actions[index];
              if (action != null) {
                return InkWell(
                  child: Container(
                    color: action.color,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                            alignment: Alignment.topLeft,
                            padding:
                                EdgeInsets.only(left: 16, top: 12, bottom: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                    width: 156,
                                    child: TextFormField(
                                        initialValue: action.id)),
                                Container(
                                    alignment: Alignment.topLeft,
                                    padding:
                                    EdgeInsets.only(left: 16, top: 12, bottom: 4),
                                    child: Text(".${action.name} {", style: TextStyle(fontSize: 21),)),
                              ],
                            )),
                        Container(
                            alignment: Alignment.topLeft,
                            padding:
                                EdgeInsets.only(left: 16, top: 12, bottom: 4),
                            child: Text("")),
                        Container(
                            alignment: Alignment.topLeft,
                            padding:
                                EdgeInsets.only(left: 16, top: 12, bottom: 4),
                            child: Text("}")),
                      ],
                    ),
                  ),
                  onTap: () {
                    // appFruits.selectedProject!.selectedLayout = screenBundle;
                    // onSetStateListener.call();
                  },
                );
              } else {
                return Container();
              }
            },
          ),
        );
        break;
      case EditorType.layoutEditor:
        content = Container(width: 640);
        break;
    }

    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 16, top: 4, bottom: 2),
            child: ToggleButtons(
                direction: Axis.horizontal,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                selectedBorderColor: Colors.red[700],
                selectedColor: Colors.white,
                fillColor: Colors.red[200],
                color: Colors.red[400],
                constraints: const BoxConstraints(
                  minHeight: 28.0,
                  minWidth: 80.0,
                ),
                isSelected: _editorTypeSelectorState,
                onPressed: (int index) {
                  setState(() {
                    for (int i = 0; i < _editorTypeSelectorState.length; i++) {
                      _editorTypeSelectorState[i] = i == index;
                    }
                    if (_editorTypeSelectorState.first) {
                      _selectedEditor = EditorType.actionsEditor;
                    } else {
                      _selectedEditor = EditorType.layoutEditor;
                    }
                  });
                },
                children: const [
                  Text("Actions"),
                  Text("Layout"),
                ]),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildActionsListWidget() {
    return Container(
        color: Colors.orangeAccent,
        width: 180,
        child: Column(children: _buildDraggableActionsList()));
  }

  List<Widget> _buildDraggableActionsList() {
    List<Widget> widgets = [];
    for (var codeBlock in _actionsCodeBlocks) {
      widgets.add(_buildDraggableActionWidget(codeBlock));
    }

    return widgets;
  }

  Container _buildDraggableActionWidget(ActionCodeBlock codeBlock) {
    var name = codeBlock.name;
    if (codeBlock.isContainer) {
      name += " { }";
    } else {
      name += "()";
    }
    return Container(
      padding: const EdgeInsets.only(left: 18, right: 8, top: 16),
      alignment: Alignment.topLeft,
      child: Draggable(
        feedback: FilledButton(
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(codeBlock.color)),
            onPressed: () {},
            child: Text(name,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center)),
        onDragEnd: (details) {
          _onActionButtonMovingEnd(details, codeBlock);
        },
        child: FilledButton(
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(codeBlock.color)),
            onPressed: () {},
            child: Text(name,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center)),
      ),
    );
  }

  void _onActionButtonMovingEnd(details, ActionCodeBlock codeBlock) {
    // if (hoveredCodeBlock == null) {
    //   if (codeBlock is LifecycleEventBlock) {
    //     var itemsMap = <String, String>{};
    //     for (var event in codeBlock.events) {
    //       itemsMap.putIfAbsent(event, () => event);
    //     }
    //     showDialog(
    //         context: context,
    //         builder: (context) {
    //           return AlertDialog(
    //             title: const Text("Select lifecycle event:"),
    //             content: makeMenuWidget(itemsMap, context, (selected) {
    //               setState(() {
    //                 element?.listeners.add(codeBlock.copyStubWith(selected));
    //               });
    //             }),
    //           );
    //         });
    //   } else {
    //     setState(() {
    //       element?.listeners.add(codeBlock.copyBlock() as ListenerCodeBlock);
    //     });
    //   }
    // } else {
    //   var screenBundles = appFruits.selectedProject!.layouts;
    //   setState(() {
    //     if (codeBlock is ActionCodeBlock) {
    //       if (codeBlock.actionType == ActionCodeType.openNextScreen &&
    //           screenBundles.isNotEmpty) {
    //         var hoveredCodeBlockHolder = hoveredCodeBlock!;
    //         selectLayout(
    //             codeBlock as OpenNextScreenBlock, hoveredCodeBlockHolder,
    //                 (selected) {
    //               var copyStubWith = codeBlock.copyStubWith(selected);
    //               hoveredCodeBlockHolder.actions.add(copyStubWith);
    //             });
    //       } else if (codeBlock.actionType == ActionCodeType.backToPrevious &&
    //           screenBundles.isNotEmpty) {
    //         hoveredCodeBlock?.actions.add(codeBlock.copyBlock());
    //       } else {
    //         hoveredCodeBlock?.actions.add(codeBlock.copyBlock());
    //       }
    //     }
    //   });
    // }
  }

  Future<void> _onAddScreenPressed() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: true);

    if (result != null) {
      List<ScreenBundle> resultScreens = [];
      for (var f in result.files) {
        var layoutBytes = f.bytes;

        int index =
            appFruits.selectedProject!.layouts.length + resultScreens.length;
        ScreenBundle screenBundle = ScreenBundle("New Screen ${index + 1}")
          ..isLauncher = index == 0;

        if (layoutBytes != null) {
          screenBundle.layoutBytes = layoutBytes;
        } else if (f.path != null) {
          screenBundle.layoutBytes = await readFileByte(f.path!);
        }

        resultScreens.add(screenBundle);
      }
      setState(() {
        appFruits.selectedProject!.layouts.addAll(resultScreens);
        appFruits.selectedProject!.selectedLayout = resultScreens.first;
      });
    }
  }

  void _onActionTypeSelected(ActionCodeBlock selected, ActionCodeBlock action) {
    setState(() {
      var newAction = _activeAction!
        ..name = selected.name
        ..type = selected.type
        ..isContainer = selected.isContainer;
      getLayoutBundle()!.actions.add(newAction);
    });
  }
}
