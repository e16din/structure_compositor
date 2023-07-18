// import 'dart:convert';
// import 'dart:ffi';

// import 'dart:ffi';
// import 'dart:math';
// import 'dart:typed_data';

import 'package:code_text_field/code_text_field.dart';
import 'package:get/get.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/kotlin.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
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

class _ActionsEditorPageState extends State<ActionsEditorPage> {
  EditorType _selectedEditor = EditorType.actionsEditor;

  final _editorTypeSelectorState = [
    true,
    false,
    false
  ]; // Action 0 | Code 1 | Layout 2

  final List<CodeAction> _actionsCodeBlocks = [
    CodeAction(
        type: CodeActionType.doOnInit, name: "doOnInit", isContainer: true)
      ..actionColor = Colors.deepPurpleAccent.withOpacity(0.7),
    CodeAction(
        type: CodeActionType.doOnClick, name: "doOnClick", isContainer: true)
      ..actionColor = Colors.deepPurpleAccent.withOpacity(0.7),
    CodeAction(
        type: CodeActionType.doOnTextChanged,
        name: "doOnTextChanged",
        isContainer: true)
      ..actionColor = Colors.deepPurpleAccent.withOpacity(0.7),
    CodeAction(
        type: CodeActionType.nothing, name: "nothing", isContainer: false),
    CodeAction(
        type: CodeActionType.showText, name: "showText", isContainer: false),
    CodeAction(
        type: CodeActionType.showImage, name: "showImage", isContainer: false),
    CodeAction(
        type: CodeActionType.showList, name: "showList", isContainer: false)
      ..withDataSource = true,
    CodeAction(
        type: CodeActionType.updateDataSource,
        name: "updateDataSource",
        isContainer: false)
      ..withDataSource = true,
    CodeAction(
        type: CodeActionType.moveToNextScreen,
        name: "moveToNextScreen",
        isContainer: false)
      ..actionColor = Colors.green,
    CodeAction(
        type: CodeActionType.moveToBackScreen,
        name: "moveToBackScreen",
        isContainer: false)
      ..actionColor = Colors.green,
    CodeAction(type: CodeActionType.todo, name: "TODO()", isContainer: false)
      ..actionColor = Colors.redAccent
      ..withComment = true,
    CodeAction(type: CodeActionType.note, name: "// NOTE:", isContainer: false)
      ..actionColor = Colors.redAccent
      ..withComment = true,
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
      default:
        //do nothing
        break;
    }

    for (var innerAction in action.actions) {
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

    super.dispose();
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
          _onAddLayoutPressed();
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
                    painter: ActionsPainter(getLayoutBundle()!),
                  )))
        ]),
      );
    } else {
      return Container(width: SCREEN_IMAGE_WIDTH, color: Colors.white);
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      var lastRect = Rect.fromPoints(event.localPosition, event.localPosition);
      var nextElementId = _nextElementId();
      var action = CodeAction(
          type: CodeActionType.doOnInit,
          name: "unknownAction {}",
          isContainer: true)
        ..elementId = nextElementId
        ..actionId = _nextActionId()
        ..isActive = true;

      getLayoutBundle()!.actions.add(action);
      getLayoutBundle()!.setActiveAction(action);

      var nextColor = getNextColor(getLayoutBundle()?.elements.length);
      var element = CodeElement(nextElementId, nextColor)
        ..area = lastRect
        ..layoutFileName = getLayoutBundle()!.layoutFiles.first.fileName;
      getLayoutBundle()!.elements.add(element);
    });
  }

  String _nextElementId() => 'element${getLayoutBundle()!.elements.length + 1}';

  String _nextActionId() => 'action${getLayoutBundle()!.actions.length + 1}';

  void _onPointerMove(PointerMoveEvent event) {
    setState(() {
      debugPrint("Here! 3");
      var element = getLayoutBundle()!.getActiveElement();
      element.area = Rect.fromPoints(element.area.topLeft, event.localPosition);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    debugPrint("Here! 4");
    var element = getLayoutBundle()!.getActiveElement();
    var area = element.area;
    if (area.left.floor() == area.right.floor() &&
        area.top.floor() == area.bottom.floor()) {
      setState(() {
        getLayoutBundle()!.actions.removeLast();
        getLayoutBundle()!.elements.removeLast();
        getLayoutBundle()!.resetActiveAction();
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
    var layout = getLayoutBundle();

    Widget content = Container(width: 640);
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
            itemCount: (layout != null ? layout.actions.length : 0),
            itemBuilder: (BuildContext context, int index) {
              var action = layout?.actions[index];
              if (action != null) {
                return _buildEditorActionWidget(action);
              } else {
                return Container();
              }
            },
          ),
        );
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
                  _updateMainXmlCode();

                  setState(() {
                    for (int i = 0; i < _editorTypeSelectorState.length; i++) {
                      _editorTypeSelectorState[i] = i == index;
                    }
                    if (_editorTypeSelectorState[0]) {
                      _selectedEditor = EditorType.actionsEditor;
                    } else if (_editorTypeSelectorState[1]) {
                      _selectedEditor = EditorType.codeEditor;
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
          return CodeTheme(
            data: const CodeThemeData(styles: monokaiSublimeTheme),
            child: CodeField(
              controller: files[index].codeController,
              textStyle: const TextStyle(fontFamily: 'SourceCode'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionsListWidget() {
    return SingleChildScrollView(
      child: Container(
          padding: const EdgeInsets.only(bottom: 280),
          color: Colors.orangeAccent,
          width: 180,
          child: Column(children: _buildDraggableActionsList())),
    );
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
    var activeAction = getLayoutBundle()!.getActiveAction();
    if (activeAction.isContainer == true) {
      setState(() {
        var newAction = CodeAction(
            type: action.type,
            name: action.name,
            isContainer: action.isContainer)
          ..actionId = activeAction.actionId
          ..elementId = activeAction.elementId
          ..withComment = action.withComment
          ..withDataSource = action.withDataSource;

        activeAction.actions.add(newAction);
      });
    }
  }

  Future<void> _onAddLayoutPressed() async {
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

      appFruits.selectedProject!.layouts.addAll(resultScreens);
      var layout = resultScreens.first;
      appFruits.selectedProject!.selectedLayout = layout;

      if (layout.codeFiles.isEmpty == true) {
        var file = CodeFile(CodeLanguage.kotlin, "main.kt",
            CodeController(language: kotlin, text: "main.kt"));
        layout.codeFiles.add(file);
      }

      // var xmlLayoutText = await _generateXmlLayout(getLayoutBundle()!);
      if (layout.layoutFiles.isEmpty == true) {
        var file = CodeFile(CodeLanguage.xml, "main.xml",
            CodeController(language: xml, text: "main.xml"));
        layout.layoutFiles.add(file);
      }

      var nextColor = getNextColor(getLayoutBundle()?.elements.length);
      String nextElementId = _nextElementId();
      var element = CodeElement(nextElementId, nextColor)
        ..area = Rect.largest
        ..layoutFileName = getLayoutBundle()!.layoutFiles.first.fileName;
      getLayoutBundle()!.elements.add(element);

      setState(() {});
    }
  }

  void _onActionTypeSelected(
      CodeAction action, CodeAction innerAction, bool isNewElement) {
    setState(() {
      var activeAction = getLayoutBundle()!.getActiveAction();
      activeAction //todo: make copy of object
        ..name = action.name
        ..type = action.type
        ..isContainer = action.isContainer;

      if (innerAction.withDataSource) {
        //todo: make copy of object
        innerAction
          ..dataSourceId = 'dataSource${getLayoutBundle()!.actions.length + 1}'
          ..elementId = activeAction.elementId;
      }
      activeAction.actions.add(innerAction);

      debugPrint("Here! 2");
      var element = getLayoutBundle()!.getElementByAction(activeAction);
      var viewTypes = _getViewTypesByAction(activeAction);
      element.viewTypes = viewTypes;
      if (viewTypes.isNotEmpty) {
        element.selectedViewType = viewTypes.first;
      }

      for (var e in getLayoutBundle()!.elements) {
        if (e.area.contains(element.area.topLeft) &&
            e.area.contains(element.area.bottomRight)) {
          e.content.add(element.elementId);
          break;
        }
      }

      getLayoutBundle()!.sortActionsByElement();

      var layout = getLayoutBundle()!;

      for (var element in layout.elements) {
        if (element.selectedViewType == ViewType.list) {
          var fileName = "${element.elementId}.xml";

          var contentElements = element.content
              .map((elementId) => layout.elements
                  .firstWhere((element) => element.elementId == elementId))
              .toList();
          for (var element in contentElements) {
            element.layoutFileName = fileName;
          }

          var text =
              _generateXmlViewsByElements(fileName, contentElements, true);
          if (layout.layoutFiles
                  .firstWhereOrNull((f) => f.fileName == fileName) ==
              null) {
            var file = CodeFile(CodeLanguage.xml, fileName,
                CodeController(language: xml, text: text));
            layout.layoutFiles.add(file);
          } else {
            var file =
                layout.layoutFiles.firstWhere((f) => f.fileName == fileName);
            file.codeController.text = text;
          }
        }
      }

      if (_editorTypeSelectorState[2]) {
        _updateMainXmlCode();
      }
    });
  }

  void _updateMainXmlCode() async {
    var layout = getLayoutBundle()!;
    layout.sortElements();

    var mainLayoutFile = layout.layoutFiles.first;
    String xmlLayoutText = _generateXmlViewsByElements(
        mainLayoutFile.fileName, layout.elements, true);
    mainLayoutFile.codeController.text = xmlLayoutText;
  }

  _elementIdWidget(CodeAction action) {
    final Widget result;
    if (getLayoutBundle()!.getActiveAction() == action) {
      result = TextFormField(
        initialValue: action.elementId,
        onChanged: (text) {
          _onElementIdChanged(text);
        },
      );
    } else {
      result = Text(action.elementId);
    }

    return result;
  }

  _onElementIdChanged(String newElementId) {
    setState(() {
      var commonElementId = getLayoutBundle()!.getActiveAction().elementId;
      for (var a in getLayoutBundle()!.actions) {
        if (a.elementId.compareTo(commonElementId) == 0) {
          a.elementId = newElementId;
        }
      }

      for (var element in getLayoutBundle()!.elements) {
        if (element.elementId == commonElementId) {
          element.elementId = newElementId;
        }
      }
    });
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

  Widget _buildEditorActionWidget(CodeAction action) {
    List<Widget> innerActionWidgets = [];
    for (var innerAction in action.actions) {
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
                            action.actions.remove(innerAction);
                          });
                        },
                        icon: const Icon(Icons.remove_circle)),
                  )
                ],
              ),
              _buildAdditionActionWidgets(action, innerAction, innerActionName)
            ],
          ));
      innerActionWidgets.add(innerActionWidget);
    }

    debugPrint("Here! 1");
    var element = getLayoutBundle()!.getElementByAction(action);
    Map<String, ViewType> viewTypesMap = {};
    for (var viewType in element.viewTypes) {
      viewTypesMap[viewType.viewName] = viewType;
    }
    return InkWell(
      onHover: (focused) {
        if (focused) {
          setState(() {
            getLayoutBundle()!.setActiveAction(action);
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
                    SizedBox(width: ID_WIDTH, child: _elementIdWidget(action)),
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
                            var activeAction = CodeAction(
                                type: action.type,
                                name: action.name,
                                isContainer: action.isContainer)
                              ..actionId = action.actionId
                              ..elementId = action.elementId
                              ..withComment = action.withComment
                              ..withDataSource = action.withDataSource;
                            getLayoutBundle()!.setActiveAction(activeAction);
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
                            setState(() {
                              getLayoutBundle()?.actions.remove(action);
                              getLayoutBundle()?.removeElement(element);
                              getLayoutBundle()?.resetActiveAction();
                            });
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

  String _generateXmlViewsByElements(
      String fileName, List<CodeElement> elements, bool isRoot) {
    String result = "";
    if (isRoot) {
      result = """<?xml version="1.0" encoding="utf-8"?>
      """;
    }
    for (var e in elements) {
      if (e.layoutFileName != fileName) {
        continue;
      }

      if (e.isContainer() && e.selectedViewType != ViewType.list) {
        var containerViewId =
            "@+id/${e.elementId}${e.selectedViewType.viewName.removeAllWhitespace}";
        result += """
        <LinearLayout
              android:id="$containerViewId"
              android:layout_width="match_parent"
              android:layout_height="wrap_content"
              android:orientation="vertical"
              >
        """;
        var contentElements = e.content
            .map((elementId) => getLayoutBundle()!
                .elements
                .firstWhere((element) => element.elementId == elementId))
            .toList();
        result += _generateXmlViewsByElements(fileName, contentElements, false);
        result += """

        </LinearLayout>
        """;
      } else {
        var elementId = e.elementId;
        debugPrint("elementId: $elementId");
        var viewId = _getViewId(e);

        switch (e.selectedViewType) {
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
          case ViewType.selector:
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
          case ViewType.listItem:
            // TODO: Generate item.xml
            break;
        }
      }
    }
    return result;
  }

  String _getViewId(CodeElement e) =>
      "@+id/${e.elementId}${e.selectedViewType.viewName.removeAllWhitespace}";
}
