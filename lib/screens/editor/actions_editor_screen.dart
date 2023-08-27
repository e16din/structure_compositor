// import 'dart:convert';
// import 'dart:ffi';

// import 'dart:ffi';
// import 'dart:math';
// import 'dart:typed_data';

import 'package:code_text_field/code_text_field.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:highlight/languages/xml.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:structure_compositor/screens/editor/areas_editor_widget.dart';
import 'package:structure_compositor/screens/editor/files_editor_widget.dart';

// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:developer' as developer;
// import 'package:file_picker/file_picker.dart';
import '../../box/app_utils.dart';
import '../../box/data_classes.dart';
import '../../box/widget_utils.dart';
import 'fruits.dart';

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
      case CodeActionType.showGrid:
        return CodeAction(
            actionId: "emptyId",
            type: CodeActionType.showGrid,
            name: "showGrid",
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
      CodeActionType.showGrid,
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

  final _actionsEditorTypeSelectorState = [
    true, // Action 0
    false, // Task 1
    false, // Pseudo 2
  ];

  final _platformEditorTypeSelectorState = [
    false, // Settings 0
    false, // Logic 1
    false, // Layout 2
    false, // Data 3
  ];

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
        case CodeActionType.showGrid:
          result.add(ViewType.grid);
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

    areasEditorFruit.onSelectedLayoutChanged = (layout) {
      setState(() {
        if (layout != null) {
          _updateAllFiles(layout);
        }
      });
    };
  }

  @override
  void dispose() {
    EasyDebounce.cancelAll();

    var layout = getLayoutBundle();
    if (layout != null) {
      for (var file in layout.layoutFiles) {
        file.codeController.dispose();
      }
      for (var file in layout.logicFiles) {
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
    switch (actionsEditorFruit.selectedActionsEditMode) {
      case ActionsEditModeType.none:
        // do nothing
        break;
      case ActionsEditModeType.actions:
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
              return _buildEditorActionListItem(element, action);
            },
          ),
        );
        break;
      case ActionsEditModeType.task:
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
                        child: TextFormField(
                            key: Key("${layout.name}.task"),
                            initialValue: "task.txt")),
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
      case ActionsEditModeType.pseudo:
        if (layout != null) {
          content = Container(width: 640);
        }
        break;
    }

    if (platformFilesEditorFruit.selectedPlatformEditMode !=
        PlatformEditModeType.none) {
      content = PlatformFilesEditorWidget();
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
                isSelected: _actionsEditorTypeSelectorState,
                onPressed: (int index) {
                  _onActionsEditorTabChanged(index);
                },
                children: _buildActionsEditorTabs()),
          ),
          Container(
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 16, top: 4, bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.only(right: 16),
                  child: FilledButton(
                      onPressed: () {
                        Map<String, SystemType> itemsMap = {};
                        for (var system in SystemType.values) {
                          itemsMap[system.title] = system;
                        }
                        showMenuDialog(context, "Select System", itemsMap,
                            (selected) {
                          setState(() {
                            appFruits.selectedProject!.systemType = selected;
                          });
                        });
                      },
                      child: Text(appFruits.selectedProject!.systemType.title)),
                ),
                ToggleButtons(
                    direction: Axis.horizontal,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    selectedBorderColor: Colors.green[700],
                    selectedColor: Colors.white,
                    fillColor: Colors.green[200],
                    color: Colors.green[400],
                    constraints: const BoxConstraints(
                      minHeight: 28.0,
                      minWidth: 80.0,
                    ),
                    isSelected: _platformEditorTypeSelectorState,
                    onPressed: (int index) {
                      _onPlatformEditorTabChanged(index);
                    },
                    children: _buildPlatformEditorTabs()),
                IconButton(
                    onPressed: () {
                      _downloadAllProjectFiles();
                    },
                    color: Colors.green,
                    icon: const Icon(Icons.get_app))
              ],
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  List<Widget> _buildActionsEditorTabs() {
    return [
      Text("Actions"),
      Text("Task"),
      Text("Pseudo"),
    ];
  }

  List<Widget> _buildPlatformEditorTabs() {
    return [
      Text("Settings"),
      Text("Logic"),
      Text("Layout"),
      Text("Data"),
    ];
  }

  void _onActionsEditorTabChanged(int index) {
    platformFilesEditorFruit.selectedPlatformEditMode =
        PlatformEditModeType.none;
    for (int i = 0; i < _platformEditorTypeSelectorState.length; i++) {
      _platformEditorTypeSelectorState[i] = false;
    }

    setState(() {
      for (int i = 0; i < _actionsEditorTypeSelectorState.length; i++) {
        _actionsEditorTypeSelectorState[i] = i == index;
      }
      actionsEditorFruit.selectedActionsEditMode = ActionsEditModeType.values[
          _actionsEditorTypeSelectorState.indexWhere((element) => element) + 1];
      debugPrint("selected: ${actionsEditorFruit.selectedActionsEditMode}");
    });
  }

  void _onPlatformEditorTabChanged(int index) {
    actionsEditorFruit.selectedActionsEditMode = ActionsEditModeType.none;
    for (int i = 0; i < _actionsEditorTypeSelectorState.length; i++) {
      _actionsEditorTypeSelectorState[i] = false;
    }

    setState(() {
      for (int i = 0; i < _platformEditorTypeSelectorState.length; i++) {
        _platformEditorTypeSelectorState[i] = i == index;
      }
      platformFilesEditorFruit.selectedPlatformEditMode = PlatformEditModeType
              .values[
          _platformEditorTypeSelectorState.indexWhere((element) => element) +
              1];
      debugPrint(
          "selected: ${platformFilesEditorFruit.selectedPlatformEditMode}");
    });
  }

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
    platformFilesEditorFruit.layoutGenerator.updateFiles(rootNode);
    platformFilesEditorFruit.logicGenerator.updateFiles(rootNode);
    platformFilesEditorFruit.settingsGenerator.updateFiles(rootNode);
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

  _elementIdWidget(CodeElement element) {
    final Widget result;
    if (getLayoutBundle()!.activeElement == element) {
      result = TextFormField(
        key: Key(element.elementId.toString()),
        initialValue: element.elementId,
        onChanged: (text) {
          EasyDebounce.debounce('ElementId', const Duration(milliseconds: 500),
              () {
            _onElementIdChanged(text);
          });
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
            key: Key(innerAction.actionId.toString()),
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

  Widget _buildEditorActionListItem(CodeElement element, CodeAction action) {
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
                color: Colors.green.withOpacity(0.42),
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 12, bottom: 8),
                child: TextFormField(
                  key: Key("${action.actionId.toString()}.Description"),
                  textCapitalization: TextCapitalization.sentences,
                  decoration:
                      const InputDecoration(labelText: "// Description"),
                  onChanged: (text) {
                    EasyDebounce.debounce(
                        'Description', const Duration(milliseconds: 500), () {
                      action.description = text;
                    });
                  },
                )),
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

  void _updateLogicFiles(ElementNode rootNode) {
    var layout = getLayoutBundle()!;
    layout.logicFiles.clear(); // todo:
  }

  void _downloadAllProjectFiles() {
    // todo:
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
