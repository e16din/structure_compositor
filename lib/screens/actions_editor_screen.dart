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
  EditorType _selectedEditor = EditorType.actionsEditor;

  final _editorTypeSelectorState = [true, false, false];

  final List<CodeAction> _actionsCodeBlocks = [
    CodeAction(
        type: ActionCodeType.doOnInit,
        name: "doOnInit",
        isContainer: true,
        layoutArea: _defaultArea)
      ..actionColor = Colors.deepPurpleAccent.withOpacity(0.7),
    CodeAction(
        type: ActionCodeType.doOnClick,
        name: "doOnClick",
        isContainer: true,
        layoutArea: _defaultArea)
      ..actionColor = Colors.deepPurpleAccent.withOpacity(0.7),
    CodeAction(
        type: ActionCodeType.doOnDataChanged,
        name: "doOnDataChanged",
        isContainer: true,
        layoutArea: _defaultArea)
      ..actionColor = Colors.deepPurpleAccent.withOpacity(0.7),
    CodeAction(
        type: ActionCodeType.nothing,
        name: "nothing",
        isContainer: false,
        layoutArea: _defaultArea),
    CodeAction(
        type: ActionCodeType.showText,
        name: "showText",
        isContainer: false,
        layoutArea: _defaultArea),
    CodeAction(
        type: ActionCodeType.showImage,
        name: "showImage",
        isContainer: false,
        layoutArea: _defaultArea),
    CodeAction(
        type: ActionCodeType.showList,
        name: "showList",
        isContainer: false,
        layoutArea: _defaultArea)
      ..withDataSource = true,
    CodeAction(
        type: ActionCodeType.updateDataSource,
        name: "updateDataSource",
        isContainer: false,
        layoutArea: _defaultArea)
      ..withDataSource = true,
    CodeAction(
        type: ActionCodeType.moveToNextScreen,
        name: "moveToNextScreen",
        isContainer: false,
        layoutArea: _defaultArea)
      ..actionColor = Colors.green,
    CodeAction(
        type: ActionCodeType.moveToBackScreen,
        name: "moveToBackScreen",
        isContainer: false,
        layoutArea: _defaultArea)
      ..actionColor = Colors.green,
    CodeAction(
        type: ActionCodeType.todo,
        name: "TODO()",
        isContainer: false,
        layoutArea: _defaultArea)
      ..actionColor = Colors.redAccent
      ..withComment = true,
    CodeAction(
        type: ActionCodeType.note,
        name: "// NOTE:",
        isContainer: false,
        layoutArea: _defaultArea)
      ..actionColor = Colors.redAccent
      ..withComment = true,
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
                    painter: ActionsPainter(getLayoutBundle()!, _activeAction),
                  )))
        ]),
      );
    } else {
      return Container(width: SCREEN_IMAGE_WIDTH, color: Colors.white);
    }
  }

  CodeAction? _activeAction;

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      var lastRect = Rect.fromPoints(event.localPosition, event.localPosition);
      _activeAction = CodeAction(
          type: ActionCodeType.doOnInit,
          name: "unknownAction {}",
          isContainer: true,
          layoutArea: lastRect)
        ..elementId = _nextElementId()
        ..actionId = _nextActionId();
    });
  }

  String _nextElementId() => 'element${getLayoutBundle()!.actions.length + 1}';

  String _nextActionId() => 'element${getLayoutBundle()!.actions.length + 1}';

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

    _selectActions(true);
  }

  void _selectActions(bool isNewElement) {
    Map<String, CodeAction> containerActionsMap = {};
    var containerActions =
        _actionsCodeBlocks.where((element) => element.isContainer);
    for (var action in containerActions) {
      containerActionsMap["${action.name} { }"] = action;
    }
    var otherActions =
        _actionsCodeBlocks.where((element) => !element.isContainer);
    Map<String, CodeAction> otherActionsMap = {};
    for (var action in otherActions) {
      otherActionsMap["${action.name}()"] = action;
    }
    showMenuDialog(context, "Select action container:", containerActionsMap,
        (selectedContainer) {
      showMenuDialog(
          context,
          "Select action:",
          otherActionsMap,
          (selected) =>
              _onActionTypeSelected(selectedContainer, selected, isNewElement));
    });
  }

  final double ID_WIDTH = 156;

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
            itemCount: (getLayoutBundle() != null
                ? getLayoutBundle()?.actions.length
                : 0)!,
            itemBuilder: (BuildContext context, int index) {
              var action = getLayoutBundle()?.actions[index];
              if (action != null) {
                List<Widget> viewActions = [];
                for (var innerAction in action.actions) {
                  String innerActionName;
                  if (innerAction.withComment) {
                    innerActionName = innerAction.name;
                  } else {
                    innerActionName = "${innerAction.name}()";
                  }

                  var innerActionWidget = Container(
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.only(
                          left: 16 + 64, top: 12, bottom: 4),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                innerActionName,
                                style: const TextStyle(fontSize: 18),
                              ),
                              Container(
                                alignment: Alignment.topRight,
                                // padding: const EdgeInsets.all(16),
                                child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        action.actions.remove(innerAction);
                                      });
                                    },
                                    icon: const Icon(Icons.remove_circle)),
                              )
                            ],
                          ),
                          _buildAdditionActionWidgets(
                              action, innerAction, innerActionName)
                        ],
                      ));
                  viewActions.add(innerActionWidget);
                }

                debugPrint("debug: init elementId:  ${action.actionId}");

                return InkWell(
                  onHover: (focused) {
                    if (focused) {
                      setState(() {
                        _activeAction = action;
                      });
                    }
                  },

                  hoverColor: Colors.white,
                  // hoverColor,
                  // highlightColor,
                  focusColor: Colors.white,
                  highlightColor: Colors.white,
                  child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: getLayoutBundle()!
                                .getElementByAction(action)
                                .elementColor,
                            width: 4)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                            alignment: Alignment.topLeft,
                            padding: const EdgeInsets.only(
                                left: 16, top: 12, bottom: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                    width: ID_WIDTH,
                                    child: _elementIdWidget(action)),
                                Container(
                                  alignment: Alignment.topRight,
                                  padding: const EdgeInsets.all(16),
                                  child: IconButton(
                                      onPressed: () {
                                        _activeAction = CodeAction(
                                            type: action.type,
                                            name: action.name,
                                            isContainer: action.isContainer,
                                            layoutArea: action.layoutArea)
                                          ..actionId = action.actionId
                                          ..elementId = action.elementId
                                          ..withComment = action.withComment
                                          ..withDataSource =
                                              action.withDataSource;

                                        _selectActions(false);
                                      },
                                      icon: const Icon(Icons.add_box_rounded)),
                                ),
                                Container(
                                    alignment: Alignment.topLeft,
                                    padding: const EdgeInsets.only(
                                        left: 16, top: 12, bottom: 4),
                                    child: Text(
                                      ".${action.name} {",
                                      style: const TextStyle(fontSize: 18),
                                    )),
                                Container(
                                  alignment: Alignment.topRight,
                                  padding: const EdgeInsets.all(16),
                                  child: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          getLayoutBundle()
                                              ?.actions
                                              .remove(action);
                                          _activeAction = null;
                                        });
                                      },
                                      icon: const Icon(Icons.remove_circle)),
                                )
                              ],
                            )),
                        Column(
                          children: viewActions,
                        ),
                        Container(
                            alignment: Alignment.topLeft,
                            padding: const EdgeInsets.only(
                                left: 16, top: 12, bottom: 4),
                            child: const Text(
                              "}",
                              style: TextStyle(fontSize: 18),
                            )),
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
                  Text("Code"),
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

  Container _buildDraggableActionWidget(CodeAction codeBlock) {
    var name = codeBlock.name;
    if (codeBlock.isContainer) {
      name += " { }";
    } else if (codeBlock.withComment) {
      name += "";
    } else {
      name += "()";
    }
    return Container(
      padding: const EdgeInsets.only(left: 18, right: 8, top: 16),
      alignment: Alignment.topLeft,
      child: Draggable(
        feedback: FilledButton(
            style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(codeBlock.actionColor)),
            onPressed: () {},
            child: Text(name,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center)),
        onDragEnd: (details) {
          _onActionButtonMovingEnd(details, codeBlock);
        },
        child: FilledButton(
            style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(codeBlock.actionColor)),
            onPressed: () {},
            child: Text(name,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center)),
      ),
    );
  }

  void _onActionButtonMovingEnd(details, CodeAction action) {
    if (_activeAction?.isContainer == true) {
      setState(() {
        var newAction = CodeAction(
            type: action.type,
            name: action.name,
            isContainer: action.isContainer,
            layoutArea: action.layoutArea)
          ..actionId = _activeAction!.actionId
          ..elementId = _activeAction!.elementId
          ..withComment = action.withComment
          ..withDataSource = action.withDataSource;

        _activeAction!.actions.add(newAction);
      });
    }
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

  void _onActionTypeSelected(CodeAction selectedContainer,
      CodeAction selectedContent, bool isNewElement) {
    setState(() {
      var newAction = _activeAction!
        ..name = selectedContainer.name
        ..type = selectedContainer.type
        ..isContainer = selectedContainer.isContainer;

      if (selectedContent.withDataSource) {
        selectedContent
          ..dataSourceId = 'dataSource${getLayoutBundle()!.actions.length + 1}'
          ..actionId = newAction.actionId
          ..elementId = newAction.elementId;
      }
      newAction.actions.add(selectedContent);

      if (isNewElement) {
        var element = CodeElement(newAction.elementId,
            getNextColor(getLayoutBundle()?.elements.length));
        getLayoutBundle()!.elements.add(element);
      }
      getLayoutBundle()!.actions.add(newAction);
      getLayoutBundle()!.sortActionsByElement();
    });
  }

  _elementIdWidget(CodeAction action) {
    final Widget result;
    if (_activeAction == action) {
      result = TextFormField(
        initialValue: action.elementId,
        onChanged: (text) {
          _onActionIdChanged(text);
        },
      );
    } else {
      result = Text(action.elementId);
    }

    return result;
  }

  _onActionIdChanged(String text) {
    final newId = _activeAction!.elementId;
    for (var a in getLayoutBundle()!.actions) {
      if (a.elementId.compareTo(newId) == 0) {
        a.elementId = text;
      }
    }

    setState(() {});
  }

  Widget _buildAdditionActionWidgets(
      CodeAction action, CodeAction innerAction, String innerActionName) {
    List<Widget> widgets = [];

    if (innerAction.withComment) {
      widgets.add(SizedBox(
          width: double.infinity,
          child: TextFormField(
            decoration:
                InputDecoration(labelText: "Enter $innerActionName comment"),
          )));
    }

    if (innerAction.withDataSource) {
      widgets.add(Container(
        child: FilledButton(
            onPressed: () {}, child: Text("${action.elementId}DataSource")),
      ));
    }

    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets);
  }
}
