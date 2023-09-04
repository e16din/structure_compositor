// import 'dart:convert';
// import 'dart:ffi';

// import 'dart:ffi';
// import 'dart:math';
// import 'dart:typed_data';

import 'dart:io';

import 'package:code_text_field/code_text_field.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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
// ERA: Element, Receptor, Action
// Code Example: element.receptor { action() }
class EraEditorScreen extends StatelessWidget {
  const EraEditorScreen({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Structure Compositor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const EraEditorPage(title: 'Structure Compositor: Code Editor'),
    );
  }
}

class EraEditorPage extends StatefulWidget {
  const EraEditorPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<EraEditorPage> createState() => _EraEditorPageState();
}

String nextActionId() =>
    'action${getLayoutBundle()!.getAllReceptors().length + 1}';

class CodeActionFabric {
  static CodeReceptor createReceptor(ReceptorType type) {
    switch (type) {
      // Containers:
      case ReceptorType.doOnDataChanged:
        return CodeReceptor(
            id: nextActionId(), type: type, name: "doOnDataChanged");
      case ReceptorType.doOnClick:
        return CodeReceptor(id: nextActionId(), type: type, name: "doOnClick");
      case ReceptorType.doOnTextChanged:
        return CodeReceptor(
            id: nextActionId(), type: type, name: "doOnTextChanged");
      case ReceptorType.doOnSwitch:
        return CodeReceptor(id: nextActionId(), type: type, name: "doOnSwitch");
    }
  }

  static CodeAction createAction(ActionType type) {
    switch (type) {
      case ActionType.showText:
        return CodeAction(
            id: nextActionId(), type: ActionType.showText, name: "showText");
      case ActionType.showImage:
        return CodeAction(
            id: nextActionId(), type: ActionType.showImage, name: "showImage");
      case ActionType.showList:
        return CodeAction(
            id: nextActionId(), type: ActionType.showList, name: "showList")
          ..withDataSource = true;
      case ActionType.showGrid:
        return CodeAction(
            id: nextActionId(), type: ActionType.showGrid, name: "showGrid")
          ..withDataSource = true;
      case ActionType.updateDataSource:
        return CodeAction(
            id: nextActionId(),
            type: ActionType.updateDataSource,
            name: "updateDataSource")
          ..withDataSource = true;
      case ActionType.moveToNextScreen:
        return CodeAction(
            id: nextActionId(),
            type: ActionType.moveToNextScreen,
            name: "moveToNextScreen");
      case ActionType.moveToBackScreen:
        return CodeAction(
            id: nextActionId(),
            type: ActionType.moveToBackScreen,
            name: "moveToBackScreen");
      case ActionType.todo:
        return CodeAction(
            id: nextActionId(), type: ActionType.todo, name: "TODO()")
          ..withComment = true;
      case ActionType.nothing:
        return CodeAction(
            id: nextActionId(), type: ActionType.nothing, name: "nothing");
      case ActionType.note:
        return CodeAction(
            id: nextActionId(), type: ActionType.note, name: "// NOTE:")
          ..withComment = true;
    }
  }

  static List<ReceptorType> getReceptorTypes() {
    List<ReceptorType> result = [
      ReceptorType.doOnDataChanged,
      ReceptorType.doOnClick,
      ReceptorType.doOnSwitch,
      ReceptorType.doOnTextChanged,
    ];
    return result;
  }

  static List<ActionType> getActionTypes() {
    List<ActionType> result = [
      ActionType.showImage,
      ActionType.showList,
      ActionType.showGrid,
      ActionType.showText,
      ActionType.updateDataSource,
      ActionType.moveToNextScreen,
      ActionType.moveToBackScreen,
      ActionType.note,
      ActionType.nothing,
      ActionType.todo,
    ];
    return result;
  }
}

class _EraEditorPageState extends State<EraEditorPage> {
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

  List<ViewType> _getViewTypesByReceptor(CodeReceptor receptor) {
    List<ViewType> result = [];
    switch (receptor.type) {
      case ReceptorType.doOnClick:
        result.add(ViewType.button);
        break;
      case ReceptorType.doOnTextChanged:
        result.add(ViewType.field);
        break;
      case ReceptorType.doOnSwitch:
        result.add(ViewType.switcher);
        break;
      default:
        //do nothing
        break;
    }

    for (var innerAction in receptor.actions) {
      switch (innerAction.type) {
        case ActionType.showText:
          result.add(ViewType.text);
          break;
        case ActionType.showImage:
          result.add(ViewType.image);
          break;
        case ActionType.showList:
          result.add(ViewType.list);
          break;
        case ActionType.showGrid:
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

    areasEditorFruit.onNewArea = (area) {
      var newElement = CodeElement(
          getLayoutBundle()!.elements.length, area.elementId, area.color)
        ..area = area
        ..id = area.elementId;

      _selectActions(newElement);
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

  void _selectActions(CodeElement element) {
    Map<String, ReceptorType> receptorsMap = {};

    for (var receptorType in CodeActionFabric.getReceptorTypes()) {
      receptorsMap["${receptorType.name} { }"] = receptorType;
    }

    showMenuDialog(context, "Select action container:", receptorsMap,
        (selectedContainerType) {
      Map<String, ActionType> actionsMap = {};
      for (var actionType in CodeActionFabric.getActionTypes()) {
        actionsMap["${actionType.name}()"] = actionType;
      }
      showMenuDialog(context, "Select action:", actionsMap, (selectedType) {
        CodeAction innerAction = CodeActionFabric.createAction(selectedType);
        innerAction.id = nextActionId();
        return _onActionTypeSelected(
            element,
            CodeActionFabric.createReceptor(selectedContainerType),
            innerAction);
      });
    });
  }

  final double ID_WIDTH = 156;

  Widget _buildActionsEditorWidget() {
    var layout = getLayoutBundle();

    Widget content = Container(width: 640);
    var allReceptors = layout?.getAllReceptors();
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
            itemCount: (layout != null ? allReceptors!.length : 0),
            itemBuilder: (BuildContext context, int index) {
              var receptor = allReceptors?[index];
              var element = layout!.elements.firstWhereOrNull((element) {
                return element.receptors.contains(receptor);
              })!;
              return _buildEditorReceptorListItem(element, receptor!);
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
                        // todo: add rules directory, get rules from files, remove SystemType
                        // todo: move generator code templates to files
                        Map<String, SystemType> itemsMap = {};
                        for (var system in SystemType.values) {
                          itemsMap[system.title] = system;
                        }
                        showMenuDialog(
                            context, "Select Generation Rules", itemsMap,
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
        var rootColor = Colors.white;
        var rootId = "rootContainer";
        var rootElement = CodeElement(layout.elements.length, rootId, rootColor)
          ..viewTypes = [ViewType.otherView]
          ..selectedViewType = ViewType.otherView
          ..area = AreaBundle(Rect.largest, rootColor, rootId);

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

  void _onActionTypeSelected(CodeElement element /* may be reusable */,
      CodeReceptor newReceptor, CodeAction newAction) {
    setState(() {
      newReceptor.isActive = true;

      var layout = getLayoutBundle()!;
      layout.activeReceptor = newReceptor;

      if (newAction.withDataSource) {
        //todo: make copy of object
        newAction
          ..dataSourceId = 'dataSource${layout.getAllReceptors().length + 1}'
          ..id = nextActionId();
      }
      newReceptor.actions.add(newAction);

      layout.activeElement = element;
      layout.activeElement?.receptors.add(newReceptor);
      if (!layout.elements.contains(element)) {
        layout.elements.add(element);
      }

      var viewTypes = _getViewTypesByReceptor(newReceptor);
      element.viewTypes = viewTypes;
      if (viewTypes.isNotEmpty) {
        element.selectedViewType = viewTypes.first;
      }

      _updateAllFiles(getLayoutBundle()!);

      areasEditorFruit.resetData();
    });
  }

  _elementIdWidget(CodeElement element, CodeReceptor receptor) {
    final Widget result;
    if (getLayoutBundle()!.activeReceptor == receptor) {
      result = TextFormField(
        key: Key("${element.widgetId}.${receptor.id}"),
        initialValue: element.id,
        onChanged: (text) {
          EasyDebounce.debounce('ElementId', const Duration(milliseconds: 500),
              () {
            setState(() {
              element.id = text;
              _updateAllFiles(getLayoutBundle()!);
            });
          });
        },
      );
    } else {
      result = Text(element.id);
    }

    return result;
  }

  Widget _buildAdditionActionWidgets(CodeElement element, CodeReceptor receptor,
      CodeAction action, String actionName) {
    List<Widget> widgets = [];

    if (action.withDataSource) {
      widgets.add(Container(
        child: FilledButton(
            onPressed: () {}, child: Text("${element.id}DataSource")),
      ));
    }

    if (action.type == ActionType.moveToNextScreen) {
      var screenName = nextScreensMap[action.id]?.name;
      screenName ??= "Select Screen";

      Map<String, LayoutBundle> itemsMap = {};
      for (var screen in appFruits.selectedProject!.layouts) {
        itemsMap[screen.name] = screen;
      }

      widgets.add(Container(
        child: FilledButton(
            onPressed: () {
              showMenuDialog(context, "Select Screen:", itemsMap, (selected) {
                setState(() {
                  debugPrint("selected: ${action.id}");
                  nextScreensMap[action.id] = selected;
                  action.nextScreenValue = NextScreenValue(selected);
                  _updateAllFiles(getLayoutBundle()!);
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

  Widget _buildEditorReceptorListItem(
      CodeElement element, CodeReceptor receptor) {
    List<Widget> innerActionWidgets = [];
    for (var innerAction in receptor.actions) {
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
                            receptor.actions.remove(innerAction);
                            nextScreensMap.remove(innerAction.id);
                          });
                        },
                        icon: const Icon(Icons.remove_circle)),
                  )
                ],
              ),
              _buildAdditionActionWidgets(
                  element, receptor, innerAction, innerActionName)
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
          setState(() {
            getLayoutBundle()!.activeElement = element;
            getLayoutBundle()!.activeReceptor = receptor;
          });
        }
      },

      hoverColor: Colors.white,
      // hoverColor,
      // highlightColor,
      focusColor: Colors.white,
      highlightColor: Colors.white,
      child: Container(
        decoration:
            BoxDecoration(border: Border.all(color: element.color, width: 4)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                color: Colors.green.withOpacity(0.42),
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 12, bottom: 8),
                child: receptor != getLayoutBundle()!.activeReceptor
                    ? Container(
                        padding: const EdgeInsets.only(top: 16, bottom: 16),
                        alignment: Alignment.topLeft,
                        child: Text("// Description: ${receptor.description}"))
                    : TextFormField(
                        key: Key("${receptor.id.toString()}.Description"),
                        initialValue: receptor.description,
                        textCapitalization: TextCapitalization.sentences,
                        decoration:
                            const InputDecoration(labelText: "// Description"),
                        onChanged: (text) {
                          EasyDebounce.debounce(
                              'Description', const Duration(milliseconds: 500),
                              () {
                            setState(() {
                              receptor.description = text;
                              _updateAllFiles(getLayoutBundle()!);
                            });
                          });
                        },
                      )),
            Container(
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
                child: Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                        width: ID_WIDTH,
                        child: _elementIdWidget(element, receptor)),
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
                            _selectActions(element);
                          },
                          icon: const Icon(Icons.add_box_rounded)),
                    ),
                    Container(
                        alignment: Alignment.topLeft,
                        padding:
                            const EdgeInsets.only(left: 4, top: 12, bottom: 4),
                        child: Text(
                          ".${receptor.name} {",
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
      for (var action in element.receptors) {
        nextScreensMap.remove(action.id);
      }

      layout?.resetActiveElement();
      layout?.resetActiveAction();

      _updateAllFiles(getLayoutBundle()!);
    });
  }

  void _downloadAllProjectFiles() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    debugPrint("selectedDirectory: $selectedDirectory");

    if (selectedDirectory != null) {
      appFruits.selectedProject?.layouts.forEach((element) {
        element.settingsFiles.forEach((file) async {
          var path = "$selectedDirectory/src/main";
          await Directory(path).create(recursive: true);
          await File("$path/${file.fileName}")
              .writeAsString(file.codeController.text);
        });

        element.layoutFiles.forEach((file) async {
          var path = "$selectedDirectory/src/main/res/layout";
          await Directory(path).create(recursive: true);
          await File("$path/${file.fileName}")
              .writeAsString(file.codeController.text);
        });

        element.logicFiles.forEach((file) async {
          var package = file.package.replaceAll(".", "/");
          var path = "$selectedDirectory/src/main/java/$package/screens";
          await Directory(path).create(recursive: true);
          await File("$path/${file.fileName}")
              .writeAsString(file.codeController.text);
        });

        element.dataFiles.forEach((file) async {
          var package = file.package.replaceAll(".", "/");
          var path = "$selectedDirectory/src/main/java/$package/data";
          await Directory(path).create(recursive: true);
          await File("$path/${file.fileName}")
              .writeAsString(file.codeController.text);
        });
      });
    }
  }
}

class ElementsTreeBuilder {
  const ElementsTreeBuilder();

  static ElementNode buildTree(List<CodeElement> elements) {
    elements.sort((a, b) => (b.area.rect.width * b.area.rect.height)
        .compareTo(a.area.rect.width * a.area.rect.height));
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
