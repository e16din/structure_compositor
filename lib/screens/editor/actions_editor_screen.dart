// import 'dart:convert';
// import 'dart:ffi';

// import 'dart:ffi';
// import 'dart:math';
// import 'dart:typed_data';

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:highlight/languages/xml.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:structure_compositor/screens/editor/areas_editor_widget.dart';

// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:developer' as developer;
// import 'package:file_picker/file_picker.dart';
import '../../box/app_utils.dart';
import '../../box/data_classes.dart';
import '../../box/widget_utils.dart';

/// * Elements - actions editor elements & areas elements
/// * Files - code editor files
/// * Nodes - editor file nodes

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

class CodeActionFabric {
  static CodeAction create(CodeActionType type) {
    switch (type) {
      // Containers:
      case CodeActionType.doOnInit:
        return CodeAction(
            actionId: "emptyId",
            type: CodeActionType.doOnInit,
            name: "doOnInit",
            isContainer: true);
      case CodeActionType.doOnClick:
        return CodeAction(
            actionId: "emptyId",
            type: CodeActionType.doOnClick,
            name: "doOnClick",
            isContainer: true);
      case CodeActionType.doOnTextChanged:
        return CodeAction(
            actionId: "emptyId",
            type: CodeActionType.doOnTextChanged,
            name: "doOnTextChanged",
            isContainer: true);
      case CodeActionType.doOnSwitch:
        return CodeAction(
            actionId: "emptyId",
            type: CodeActionType.doOnSwitch,
            name: "doOnSwitch",
            isContainer: true);
      // Other:
      case CodeActionType.showText:
        return CodeAction(
            actionId: "emptyId",
            type: CodeActionType.showText,
            name: "showText",
            isContainer: false);
      case CodeActionType.showImage:
        return CodeAction(
            actionId: "emptyId",
            type: CodeActionType.showImage,
            name: "showImage",
            isContainer: false);
      case CodeActionType.showList:
        return CodeAction(
            actionId: "emptyId",
            type: CodeActionType.showList,
            name: "showList",
            isContainer: false)
          ..withDataSource = true;
      case CodeActionType.updateDataSource:
        return CodeAction(
            actionId: "emptyId",
            type: CodeActionType.updateDataSource,
            name: "updateDataSource",
            isContainer: false)
          ..withDataSource = true;
      case CodeActionType.moveToNextScreen:
        return CodeAction(
            actionId: "emptyId",
            type: CodeActionType.moveToNextScreen,
            name: "moveToNextScreen",
            isContainer: false)
          ..actionColor = Colors.green;
      case CodeActionType.moveToBackScreen:
        return CodeAction(
            actionId: "emptyId",
            type: CodeActionType.moveToBackScreen,
            name: "moveToBackScreen",
            isContainer: false)
          ..actionColor = Colors.green;
      case CodeActionType.todo:
        return CodeAction(
            actionId: "emptyId",
            type: CodeActionType.todo,
            name: "TODO()",
            isContainer: false)
          ..actionColor = Colors.redAccent
          ..withComment = true;
      case CodeActionType.nothing:
        return CodeAction(
            actionId: "emptyId",
            type: CodeActionType.nothing,
            name: "nothing",
            isContainer: false);
      case CodeActionType.note:
        return CodeAction(
            actionId: "emptyId",
            type: CodeActionType.note,
            name: "// NOTE:",
            isContainer: false)
          ..actionColor = Colors.redAccent
          ..withComment = true;
    }
  }

  static List<CodeAction> getCodeContainers() {
    return CodeActionFabric.getContainerTypes()
        .map((type) => CodeActionFabric.create(type))
        .toList();
  }

  static List<CodeAction> getCodeContent() {
    return CodeActionFabric.getNotContainersTypes()
        .map((type) => CodeActionFabric.create(type))
        .toList();
  }

  static List<CodeActionType> getContainerTypes() {
    List<CodeActionType> result = [
      CodeActionType.doOnInit,
      CodeActionType.doOnClick,
      CodeActionType.doOnSwitch,
      CodeActionType.doOnTextChanged,
    ];
    return result;
  }

  static List<CodeActionType> getNotContainersTypes() {
    List<CodeActionType> result = [
      CodeActionType.showImage,
      CodeActionType.showList,
      CodeActionType.showText,
      CodeActionType.updateDataSource,
      CodeActionType.moveToNextScreen,
      CodeActionType.moveToBackScreen,
      CodeActionType.note,
      CodeActionType.nothing,
      CodeActionType.todo,
    ];
    return result;
  }
}

class _ActionsEditorPageState extends State<ActionsEditorPage> {
  var taskController = CodeController(language: markdown, text: "");

  EditorType _selectedEditor = EditorType.actionsEditor;

  final _editorTypeSelectorState = [
    true,
    false,
    false,
    false
  ]; // Action 0 | Task 1 | Code 2 | Layout 3

  String MAIN_XML_FILE_NAME = "main.xml";

  List<ViewType> _getViewTypesByAction(CodeAction action) {
    List<ViewType> result = [];
    switch (action.type) {
      case CodeActionType.doOnClick:
        result.add(ViewType.button);
        break;
      case CodeActionType.doOnTextChanged:
        result.add(ViewType.field);
        break;
      case CodeActionType.doOnSwitch:
        result.add(ViewType.switcher);
        break;
      default:
        //do nothing
        break;
    }

    for (var innerAction in action.innerActions) {
      switch (innerAction.type) {
        case CodeActionType.showText:
          result.add(ViewType.text);
          break;
        case CodeActionType.showImage:
          result.add(ViewType.image);
          break;
        case CodeActionType.showList:
          result.add(ViewType.list);
          break;

        default:
          break;
      }
    }

    return result;
  }

  Project makeNewProject() {
    return Project(name: "New Project");
  }

  @override
  void initState() {
    super.initState();

    areasEditorFruit.onNewArea = () {
      _selectActions(true);
    };

    areasEditorFruit.onSelectLayout = (layout) {
      setState(() {
        if (layout != null) {
          _updateAllFiles(layout);
        }
      });
    };
  }

  @override
  void dispose() {
    var layout = getLayoutBundle();
    if (layout != null) {
      for (var file in layout.layoutFiles) {
        file.codeController.dispose();
      }
      for (var file in layout.codeFiles) {
        file.codeController.dispose();
      }
    }

    taskController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("build!");
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Row(
        children: [
          _buildActionsEditorWidget(),
          // _buildActionsListWidget(),
          AreasEditorWidget() // ATTENTION: do not add 'const'!
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _onAddLayoutPressed();
        },
        tooltip: 'Select layout',
        child: const Icon(Icons.add),
      ),
    );
  }

  String _nextActionId() =>
      'action${getLayoutBundle()!.getAllActions().length + 1}';

  void _selectActions(bool isNewElement) {
    Map<String, CodeAction> containerActionsMap = {};
    var containerActions = CodeActionFabric.getCodeContainers();

    for (var action in containerActions) {
      containerActionsMap["${action.name} { }"] = action;
    }
    var otherActions = CodeActionFabric.getCodeContent();

    Map<String, CodeAction> otherActionsMap = {};
    for (var action in otherActions) {
      otherActionsMap["${action.name}()"] = action;
    }
    showMenuDialog(context, "Select action container:", containerActionsMap,
        (selectedContainer) {
      showMenuDialog(context, "Select action:", otherActionsMap, (selected) {
        CodeAction innerAction = selected;
        innerAction.actionId = _nextActionId();
        return _onActionTypeSelected(
            selectedContainer, innerAction, isNewElement);
      });
    });
  }

  final double ID_WIDTH = 156;

  Widget _buildActionsEditorWidget() {
    var layout = getLayoutBundle();

    Widget content = Container(width: 640);
    var allActions = layout?.getAllActions();
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
            itemCount: (layout != null ? allActions!.length : 0),
            itemBuilder: (BuildContext context, int index) {
              var action = allActions?[index];
              var element = layout!.getElementByAction(action!)!;
              return _buildEditorActionWidget(element, action);
            },
          ),
        );
        break;
      case EditorType.taskEditor:
        if (layout != null) {
          content = Container(
            width: 640,
            child: Column(
              children: [
                Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                        width: 120,
                        child: TextFormField(initialValue: "task.txt")),
                    FilledButton(
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.blueAccent)),
                        onPressed: () {
                          String codeText = taskController.text;
                          Clipboard.setData(ClipboardData(text: codeText))
                              .then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Copied to your clipboard!')));
                          });
                        },
                        child: const Text("Copy It",
                            style: TextStyle(fontSize: 12),
                            textAlign: TextAlign.center)),
                  ],
                ),
                CodeTheme(
                  data: const CodeThemeData(styles: monokaiSublimeTheme),
                  child: CodeField(
                    controller: taskController,
                    textStyle: const TextStyle(fontFamily: 'SourceCode'),
                  ),
                ),
              ],
            ),
          );
        }
        break;
      case EditorType.codeEditor:
        if (layout != null) {
          content = _buildCodeFilesWidgets(layout.codeFiles);
        }
        break;
      case EditorType.layoutEditor:
        if (layout != null) {
          content = _buildCodeFilesWidgets(layout.layoutFiles);
        }
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
                  _onEditorTabChanged(index);
                },
                children: const [
                  Text("Actions"),
                  Text("Task"),
                  Text("Code"),
                  Text("Layout"),
                ]),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  void _onEditorTabChanged(int index) {
    if (getLayoutBundle() != null) {
      _updateAllFiles(getLayoutBundle()!);
    }

    setState(() {
      for (int i = 0; i < _editorTypeSelectorState.length; i++) {
        _editorTypeSelectorState[i] = i == index;
      }
      if (_editorTypeSelectorState[0]) {
        _selectedEditor = EditorType.actionsEditor;
      } else if (_editorTypeSelectorState[1]) {
        _selectedEditor = EditorType.taskEditor;
      } else if (_editorTypeSelectorState[2]) {
        _selectedEditor = EditorType.codeEditor;
      } else {
        _selectedEditor = EditorType.layoutEditor;
      }
    });
  }

  Container _buildCodeFilesWidgets(List<CodeFile> files) {
    return Container(
      width: 640,
      child: ListView.separated(
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 16,
          endIndent: 24,
        ),
        scrollDirection: Axis.vertical,
        itemCount: files.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            color: Colors.black45,
            child: Column(
              children: [
                Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                        width: 120,
                        child:
                            TextFormField(initialValue: files[index].fileName)),
                    FilledButton(
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.blueAccent)),
                        onPressed: () {
                          String codeText = files[index].codeController.text;
                          Clipboard.setData(ClipboardData(text: codeText))
                              .then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Copied to your clipboard!')));
                          });
                        },
                        child: const Text("Copy It",
                            style: TextStyle(fontSize: 12),
                            textAlign: TextAlign.center)),
                  ],
                ),
                CodeTheme(
                  data: const CodeThemeData(styles: monokaiSublimeTheme),
                  child: CodeField(
                    controller: files[index].codeController,
                    textStyle: const TextStyle(fontFamily: 'SourceCode'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget _buildActionsListWidget() {
  //   return SingleChildScrollView(
  //     child: Container(
  //         padding: const EdgeInsets.only(bottom: 280),
  //         color: Colors.orangeAccent,
  //         width: 180,
  //         child: Column(children: _buildDraggableActionsList())),
  //   );
  // }

  // List<Widget> _buildDraggableActionsList() {
  //   List<Widget> widgets = [];
  //   for (var codeBlock in _actionsCodeBlocks) {
  //     widgets.add(_buildDraggableActionWidget(codeBlock));
  //   }
  //
  //   return widgets;
  // }

  // Container _buildDraggableActionWidget(CodeAction codeBlock) {
  //   var name = codeBlock.name;
  //   if (codeBlock.isContainer) {
  //     name += " { }";
  //   } else if (codeBlock.withComment) {
  //     name += "";
  //   } else {
  //     name += "()";
  //   }
  //   return Container(
  //     padding: const EdgeInsets.only(left: 18, right: 8, top: 16),
  //     alignment: Alignment.topLeft,
  //     child: Draggable(
  //       feedback: FilledButton(
  //           style: ButtonStyle(
  //               backgroundColor:
  //                   MaterialStateProperty.all(codeBlock.actionColor)),
  //           onPressed: () {},
  //           child: Text(name,
  //               style: const TextStyle(fontSize: 12),
  //               textAlign: TextAlign.center)),
  //       onDragEnd: (details) {
  //         _onActionButtonMovingEnd(details, codeBlock);
  //       },
  //       child: FilledButton(
  //           style: ButtonStyle(
  //               backgroundColor:
  //                   MaterialStateProperty.all(codeBlock.actionColor)),
  //           onPressed: () {},
  //           child: Text(name,
  //               style: const TextStyle(fontSize: 12),
  //               textAlign: TextAlign.center)),
  //     ),
  //   );
  // }

  // void _onActionButtonMovingEnd(details, CodeAction action) {
  //   var activeAction = getLayoutBundle()!.activeAction;
  //   if (activeAction!.isContainer == true) {
  //     setState(() {
  //       var newAction = CodeAction(
  //           type: action.type,
  //           name: action.name,
  //           isContainer: action.isContainer)
  //         ..actionId = activeAction.actionId
  //         ..withComment = action.withComment
  //         ..withDataSource = action.withDataSource;
  //
  //       activeAction.innerActions.add(newAction);
  //     });
  //   }
  // }

  Future<void> _onAddLayoutPressed() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: true);

    if (result != null) {
      List<ScreenBundle> resultScreens = [];
      for (var f in result.files) {
        var layoutBytes = f.bytes;

        int index = appFruits.selectedProject!.layouts.length;
        ScreenBundle screenBundle = ScreenBundle("New Screen ${index + 1}")
          ..isLauncher = index == 0;

        debugPrint("Add screen: ${screenBundle.name}");

        if (layoutBytes != null) {
          screenBundle.layoutBytes = layoutBytes;
        } else if (f.path != null) {
          screenBundle.layoutBytes = await readFileByte(f.path!);
        }

        resultScreens.add(screenBundle);
        appFruits.selectedProject!.layouts.add(screenBundle);
      }

      appFruits.selectedProject!.selectedLayout = resultScreens.first;

      for (var layout in resultScreens) {
        var rootElement = CodeElement("rootContainer", Colors.white)
          ..viewTypes = [ViewType.otherView]
          ..selectedViewType = ViewType.otherView
          ..area = Rect.largest;

        layout.elements.add(rootElement);
        _updateAllFiles(layout);
      }

      setState(() {});
    }
  }

  void _updateAllFiles(LayoutBundle layout) {
    var rootNode = ElementsTreeBuilder.buildTree(layout.elements);
    _updateTaskFiles(rootNode);
    _updateXmlFiles(rootNode);
    _updateXmlCode();
  }

  void _updateTaskFiles(ElementNode rootNode) {
    var layout = getLayoutBundle()!;
    layout.taskFiles.clear();
    layout.taskFiles.add(CodeFile(CodeLanguage.markdown,
        "${layout.name}_task.txt", taskController, rootNode));
  }

  void _onActionTypeSelected(
      CodeAction action, CodeAction innerAction, bool isNewElement) {
    setState(() {
      var newAction = CodeAction(
          actionId: _nextActionId(),
          type: CodeActionType.doOnInit,
          name: "unknownAction {}",
          isContainer: true)
        ..isActive = true
        ..name = action.name
        ..type = action.type
        ..isContainer = action.isContainer;
      debugPrint("1!!!action.actionId: ${newAction.actionId}");

      var layout = getLayoutBundle()!;
      layout.activeAction = action;

      // var activeAction = getLayoutBundle()!.activeAction;

      if (innerAction.withDataSource) {
        //todo: make copy of object
        innerAction
          ..dataSourceId = 'dataSource${layout.getAllActions().length + 1}'
          ..actionId = _nextActionId();

        debugPrint("2!!!action.actionId: ${innerAction.actionId}");
      }
      newAction.innerActions.add(innerAction);

      var newElement = CodeElement(
          areasEditorFruit.lastElementId!, areasEditorFruit.lastColor!)
        ..area = areasEditorFruit.lastRect!
        ..elementId = areasEditorFruit.lastElementId!;

      layout.activeElement = newElement;
      layout.activeElement?.actions.add(newAction);
      layout.elements.add(newElement);

      var viewTypes = _getViewTypesByAction(newAction);
      newElement.viewTypes = viewTypes;
      if (viewTypes.isNotEmpty) {
        newElement.selectedViewType = viewTypes.first;
      }

      _updateAllFiles(getLayoutBundle()!);

      areasEditorFruit.resetData();
    });
  }

  void _updateXmlCode() {
    if (getLayoutBundle() == null) {
      return;
    }

    debugPrint("_updateXmlCode()");

    var layout = getLayoutBundle()!;
    List<CodeFile> files = layout.layoutFiles;

    for (var file in files) {
      String xmlLayoutText =
          _generateXmlViewsByElements(file.elementNode, true);
      file.codeController.text = xmlLayoutText;
    }
  }

  _elementIdWidget(CodeElement element) {
    final Widget result;
    if (getLayoutBundle()!.activeElement == element) {
      result = TextFormField(
        initialValue: element.elementId,
        onChanged: (text) {
          _onElementIdChanged(text);
        },
      );
    } else {
      result = Text(element.elementId);
    }

    return result;
  }

  _onElementIdChanged(String newElementId) {
    setState(() {
      var commonElementId = getLayoutBundle()!.activeElement?.elementId;

      for (var element in getLayoutBundle()!.elements) {
        if (element.elementId == commonElementId) {
          element.elementId = newElementId;
        }
      }
    });
  }

  Widget _buildAdditionActionWidgets(CodeElement element, CodeAction action,
      CodeAction innerAction, String innerActionName) {
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
            onPressed: () {}, child: Text("${element.elementId}DataSource")),
      ));
    }

    if (innerAction.type == CodeActionType.moveToNextScreen) {
      var screenName = nextScreensMap[innerAction.actionId]?.name;
      screenName ??= "Select Screen";

      Map<String, LayoutBundle> itemsMap = {};
      for (var element in appFruits.selectedProject!.layouts) {
        itemsMap[element.name] = element;
      }

      widgets.add(Container(
        child: FilledButton(
            onPressed: () {
              showMenuDialog(context, "Select Screen:", itemsMap, (selected) {
                setState(() {
                  debugPrint("selected: ${innerAction.actionId}");
                  nextScreensMap[innerAction.actionId] = selected;
                  debugPrint("nextScreensMap: ${nextScreensMap.toString()}");
                });
              });
            },
            child: Text(screenName)),
      ));
    }

    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets);
  }

  Map<String, LayoutBundle> nextScreensMap = {};

  Widget _buildEditorActionWidget(CodeElement element, CodeAction action) {
    List<Widget> innerActionWidgets = [];
    for (var innerAction in action.innerActions) {
      String innerActionName;
      if (innerAction.withComment) {
        innerActionName = innerAction.name;
      } else {
        innerActionName = "${innerAction.name}()";
      }

      var innerActionWidget = Container(
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.only(left: 16 + 64, top: 12, bottom: 4),
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
                            action.innerActions.remove(innerAction);
                            nextScreensMap.remove(innerAction.actionId);
                          });
                        },
                        icon: const Icon(Icons.remove_circle)),
                  )
                ],
              ),
              _buildAdditionActionWidgets(
                  element, action, innerAction, innerActionName)
            ],
          ));
      innerActionWidgets.add(innerActionWidget);
    }

    Map<String, ViewType> viewTypesMap = {};
    for (var viewType in element.viewTypes) {
      viewTypesMap[viewType.viewName] = viewType;
    }
    return InkWell(
      onHover: (focused) {
        if (focused) {
          // setState(() {
          //   getLayoutBundle()!.activeAction = action;
          // });
        }
      },

      hoverColor: Colors.white,
      // hoverColor,
      // highlightColor,
      focusColor: Colors.white,
      highlightColor: Colors.white,
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(color: element.elementColor, width: 4)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
                child: Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(width: ID_WIDTH, child: _elementIdWidget(element)),
                    Container(
                      child: OutlinedButton(
                          child: Text(element.selectedViewType.viewName),
                          onPressed: () {
                            showMenuDialog(
                                context, "Select View Type", viewTypesMap,
                                (selected) {
                              setState(() {
                                element.selectedViewType = selected;
                              });
                            });
                          }),
                    ),
                    Container(
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.all(8),
                      child: IconButton(
                          onPressed: () {
                            debugPrint(
                                "0!!!action.actionId: ${action.actionId}");
                            var activeAction = CodeAction(
                                actionId: action.actionId,
                                type: action.type,
                                name: action.name,
                                isContainer: action.isContainer)
                              ..withComment = action.withComment
                              ..withDataSource = action.withDataSource
                              ..isActive = true;
                            getLayoutBundle()!.activeAction = activeAction;
                            _selectActions(false);
                          },
                          icon: const Icon(Icons.add_box_rounded)),
                    ),
                    Container(
                        alignment: Alignment.topLeft,
                        padding:
                            const EdgeInsets.only(left: 4, top: 12, bottom: 4),
                        child: Text(
                          ".${action.name} {",
                          style: const TextStyle(fontSize: 18),
                        )),
                    Container(
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.all(16),
                      child: IconButton(
                          onPressed: () {
                            _onRemoveActionClick(element);
                          },
                          icon: const Icon(Icons.remove_circle)),
                    )
                  ],
                )),
            Column(
              children: innerActionWidgets,
            ),
            Container(
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
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
  }

  void _onRemoveActionClick(CodeElement element) {
    setState(() {
      var layout = getLayoutBundle();
      layout?.elements.remove(element);
      for (var action in element.actions) {
        nextScreensMap.remove(action.actionId);
      }

      layout?.resetActiveElement();
      layout?.resetActiveAction();

      _updateAllFiles(getLayoutBundle()!);
    });
  }

  String _generateXmlViewsByElements(ElementNode node, bool isRoot) {
    String result = """<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
\txmlns:app="http://schemas.android.com/apk/res-auto"
\txmlns:tools="http://schemas.android.com/tools"
\tandroid:layout_width="match_parent"
\tandroid:layout_height="match_parent"
\tandroid:orientation="vertical">
      """;

    debugPrint(
        "id: ${node.element.elementId} | Nodes count: ${node.contentNodes.length}");
    for (var n in node.contentNodes) {
      debugPrint("Node: ${n.element.elementId}");

      if (n.isContainer()) {
        var containerViewId =
            "@+id/${n.element.elementId}${n.element.selectedViewType.viewName.removeAllWhitespace}";
        result += """
        <LinearLayout
              android:id="$containerViewId"
              android:layout_width="match_parent"
              android:layout_height="wrap_content"
              android:orientation="vertical"
              >
        """;
        result += _generateXmlViewsByElements(n, false);
        result += """

        </LinearLayout>
        """;
      } else {
        var elementId = n.element.elementId;
        var viewId = _getViewId(n.element);
        switch (n.element.selectedViewType) {
          case ViewType.text:
            result += """

          <TextView
              android:id="$viewId"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              android:text="todo" />
    """;
            break;
          case ViewType.field:
            result += """

          <EditText
              android:id="$viewId"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              android:hint="todo" />
    """;
            break;
          case ViewType.button:
            result += """

          <Button
              android:id="$viewId"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              android:text="todo" />
    """;
            break;
          case ViewType.image:
            result += """

          <ImageView
              android:id="$viewId"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              app:compatSrc="todo" />
    """;
            break;
          case ViewType.switcher:
            result += """

          <Switch
              android:id="$viewId"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              android:checked="todo" />
    """;
            break;
          case ViewType.list:
            result += """

         <androidx.recyclerview.widget.RecyclerView
              android:id="$viewId"
              android:layout_width="match_parent"
              android:layout_height="match_parent"
              />
    """;
            break;
          case ViewType.otherView:
            result += """

         <View
              android:id="$viewId"
              android:layout_width="200dp"
              android:layout_height="200dp"
              />
    """;
            break;
        }
      }
    }

    result += "\n</LinearLayout>";
    return result;
  }

  String _getViewId(CodeElement e) =>
      "@+id/${e.elementId}${e.selectedViewType.viewName.removeAllWhitespace}";

  void _updateXmlFiles(ElementNode rootNode) {
    var layout = getLayoutBundle()!;
    layout.layoutFiles.clear();

    CodeFile rootFile = CodeFile(CodeLanguage.xml, MAIN_XML_FILE_NAME,
        CodeController(language: xml, text: ""), rootNode);
    layout.layoutFiles.add(rootFile);

    var itemNodes = rootNode.getNodesWhere((node) =>
        node.containerNode?.element.selectedViewType == ViewType.list);
    for (var node in itemNodes) {
      node.containerNode?.contentNodes.remove(node);
      CodeFile itemFile = CodeFile(
          CodeLanguage.xml,
          "item_${node.element.elementId}.xml",
          CodeController(language: xml, text: ""),
          node);
      layout.layoutFiles.add(itemFile);
    }
  }
}

class ElementsTreeBuilder {
  const ElementsTreeBuilder();

  static ElementNode buildTree(List<CodeElement> elements) {
    elements.sort((a, b) =>
        (b.area.width * b.area.height).compareTo(a.area.width * a.area.height));
    var root = ElementNode(elements.first);
    for (var i = 1; i < elements.length; i++) {
      _addContent(root, ElementNode(elements[i]));
    }

    root.sortElementsByY();
    return root;
  }

  static void _addContent(ElementNode container, ElementNode content) {
    for (var node in container.contentNodes) {
      if (node.element.contains(content.element)) {
        _addContent(node, content);
        return;
      }
    }
    container.addContent(content);
  }
}
