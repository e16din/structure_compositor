import 'dart:typed_data';

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:structure_compositor/screens/editor/fruits.dart';

class AppDataFruits {
  List<Project> projects = [];

  Project? selectedProject;

  AppDataFruits();
}

class Project {
  String name = "";

  SystemType systemType = SystemType.android;

  List<LayoutBundle> layouts = [];

  LayoutBundle? selectedLayout;

  Project({required this.name});
}

class LayoutBundle {
  String name;

  String? layoutPath;

  Uint8List? layoutBytes;

  List<LayoutElement> elementsMain = [];

  List<CodeElement> elements = [];
  List<CodeFile> taskFiles = [];
  List<CodeFile> pseudoFiles = [];

  List<CodeFile> layoutFiles = [];
  List<CodeFile> logicFiles = [];
  List<CodeFile> settingsFiles = [];
  List<CodeFile> dataFiles = [];

  CodeAction? activeAction;
  CodeElement? activeElement;

  Map<LayoutElement, List<LayoutElement>> listLinkListItemsMap = {};

  LayoutBundle(this.name);

  List<CodeAction> _getAllActionsFrom(List<CodeAction> actions) {
    List<CodeAction> result = [];
    result.addAll(actions);
    for (var a in actions) {
      result.addAll(_getAllActionsFrom(a.innerActions));
    }
    return result;
  }

  CodeElement? getElementByAction(CodeAction action) {
    List<CodeElement> allElements = elements;

    return allElements.firstWhereOrNull((element) {
      var actions = _getAllActionsFrom(element.actions);
      return actions.contains(action);
    });
  }

  void resetActiveElement() {
    activeElement = elements.firstOrNull;
  }

  void resetActiveAction() {
    activeAction = elements.firstOrNull?.actions.firstOrNull;
  }

  List<CodeAction> getAllActions() {
    List<CodeAction> result = [];
    for (var element in elements) {
      result.addAll(element.actions);
    }
    return result;
  }
}

class ScreenBundle extends LayoutBundle {
  var isLauncher = false;

  ScreenBundle(super.name);
}

// ============

enum CodeActionType {
  // Containers
  doOnInit,
  doOnClick,
  doOnSwitch,
  doOnTextChanged,
  // View
  nothing,
  showText,
  showImage,
  showList,
  showGrid,
  updateDataSource,
  // Navigation
  moveToNextScreen,
  moveToBackScreen,
  // Comment
  todo,
  note,
}

enum SystemType {
  android("Android"), ios("iOS"), flutter("Flutter");

  const SystemType(this.title);

  final String title;
}

enum ActionsEditModeType {
  none,
  actions, // NOTE: actions editor
  task, // NOTE: human language
  pseudo, // NOTE: pseudo code
}

enum PlatformEditModeType {
  none,
  settings, // NOTE: Manifest, ..
  logic, // NOTE: Activity, Adapter, ..
  layout, // NOTE: xml, Compose, ..
  data // NOTE: DataSource, ..
}

enum CodeLanguage { unknown, markdown, xml, kotlin }

class CodeFile {
  String fileName;
  CodeLanguage language;

  CodeController codeController;
  ElementNode? elementNode;

  CodeFile(this.language, this.fileName, this.codeController, this.elementNode);
}

class ElementNode {
  CodeElement element;

  ElementNode? containerNode;
  List<ElementNode> contentNodes = [];

  ElementNode(this.element);

  bool isContainer() {
    return contentNodes.isNotEmpty;
  }

  void addContent(ElementNode content) {
    content.containerNode = this;
    contentNodes.add(content);
  }

  List<ElementNode> getNodesWhere(bool Function(ElementNode node) condition) {
    List<ElementNode> nodes = [];
    if (condition.call(this)) {
      nodes.add(this);
    }

    for (var n in contentNodes) {
      _addNodesToListWhere(nodes, n, condition);
    }
    return nodes;
  }

  void _addNodesToListWhere(List<ElementNode> result, ElementNode node,
      bool Function(ElementNode node) condition) {
    for (var n in node.contentNodes) {
      if (condition.call(n)) {
        result.add(n);
      }
      _addNodesToListWhere(result, n, condition);
    }
  }

  void sortElementsByY() {
    contentNodes.sort((a, b) {
      return a.element.area.rect.topLeft.dy.compareTo(b.element.area.rect.topLeft.dy);
    });
    for (var n in contentNodes) {
      _sortElementsByY(n);
    }
  }

  void _sortElementsByY(ElementNode n) {
    n.contentNodes.sort((a, b) {
      return a.element.area.rect.topLeft.dy.compareTo(b.element.area.rect.topLeft.dy);
    });
  }
}

class CodeElement {
  int widgetId;
  String elementId;
  Color elementColor;

  List<ViewType> viewTypes = [];
  ViewType selectedViewType = ViewType.otherView;

  late AreaBundle area;

  List<CodeAction> actions = [];

  CodeElement(this.widgetId, this.elementId, this.elementColor);

  bool contains(CodeElement elementContent) {
    return area.rect.contains(elementContent.area.rect.topLeft) &&
        area.rect.contains(elementContent.area.rect.bottomRight);
  }
}

class CodeAction {
  String actionId;

  String? dataSourceId;
  String description = "";

  CodeActionType type;

  String name;
  Color actionColor = Colors.deepPurpleAccent;
  bool isContainer = false;
  bool withComment = false;
  bool withDataSource = false;
  bool withNextScreen = false;

  List<CodeAction> innerActions = [];

  bool isActive = false;

  CodeAction(
      {required this.actionId,
      required this.type,
      required this.name,
      required this.isContainer});
}

// ===============

enum ViewType {
  button("Button"),
  text("Text"),
  field("Field"),
  image("Image"),
  switcher("Switcher"),
  list("List"),
  grid("Grid"),
  otherView("Other View"),
  ;

  final String viewName;

  const ViewType(this.viewName);
}

class LayoutElement {
  late Rect functionalArea;

  late Color color;

  ViewType viewType = ViewType.button;

  String name = "";

  String value = "";

  String description = "";

  List<ListenerCodeBlock> listeners = [];

  bool isInEdit = false;

  LayoutBundle? refToExtendedLayout;

  LayoutElement(this.functionalArea, this.color, this.isInEdit);

  bool hasDataSource() {
    return viewType == ViewType.list || viewType == ViewType.grid; // todo: add data sources feature
  }
}

class ContainerScreenElement extends LayoutElement {
  List<LayoutElement> content = [];

  ContainerScreenElement(super.functionalArea, super.color, super.isInEdit);
}

enum CodeType { action, listener }

enum ActionCodeTypeMain {
  sendRequest,
  updateWidget,
  openNextScreen,
  backToPrevious,
  changeData,
  callFunction,
  showAlertDialog,
  showSnackBar,
  comment
}

enum ListenerCodeType {
  onLifecycleEvent,
  onClick,
  onTextChanged,
  onItemSelected,
  onTimerTick,
  onResponse,
  onDataChanged
}

abstract class CodeBlock {
  String name = "empty";
  Color color = Colors.white;
  String description = "";

  CodeBlock copyBlock();
}

class ListenerCodeBlock extends CodeBlock {
  ListenerCodeType listenerType;
  List<ActionCodeBlockMain> actions = [];

  ListenerCodeBlock(this.listenerType) {
    name = "${listenerType.name}() { }";
    color = Colors.purple;
  }

  @override
  ListenerCodeBlock copyBlock() {
    return ListenerCodeBlock(listenerType);
  }
}

class ActionCodeBlockMain extends CodeBlock {
  ActionCodeTypeMain actionType;
  List<ListenerCodeBlock> listeners =
      []; // NOTE: for actions with result (async actions, callbacks)

  ActionCodeBlockMain(this.actionType) {
    name = "${actionType.name}()";
    color = Colors.green;
  }

  @override
  ActionCodeBlockMain copyBlock() {
    return ActionCodeBlockMain(actionType);
  }
}

class OpenNextScreenBlock extends ActionCodeBlockMain {
  ScreenBundle? nextScreenBundle;

  OpenNextScreenBlock() : super(ActionCodeTypeMain.openNextScreen);

  OpenNextScreenBlock copyStubWith(ScreenBundle nextScreenBundle) {
    return OpenNextScreenBlock()..nextScreenBundle = nextScreenBundle;
  }
}

class LifecycleEventBlock extends ListenerCodeBlock {
  var events = [
    "onCreate() { }",
    "onStart() { }",
    "onResume() { }",
    "onPause() { }",
    "onStop() { }",
  ];

  late String selectedEvent;

  LifecycleEventBlock() : super(ListenerCodeType.onLifecycleEvent) {
    color = Colors.purple.withOpacity(0.7);
  }

  LifecycleEventBlock copyStubWith(String selectedEvent) {
    return LifecycleEventBlock()..selectedEvent = selectedEvent;
  }
}
