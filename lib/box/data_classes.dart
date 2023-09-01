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

  CodeReceptor? activeReceptor;
  CodeElement? activeElement;

  Map<LayoutElement, List<LayoutElement>> listLinkListItemsMap = {};

  LayoutBundle(this.name);

  List<CodeAction> _getAllActionsFrom(List<CodeReceptor> receptors) {
    List<CodeAction> result = [];
    for (var r in receptors) {
      result.addAll(r.actions);
    }
    return result;
  }

  void resetActiveElement() {
    activeElement = elements.firstOrNull;
  }

  void resetActiveAction() {
    activeReceptor = elements.firstOrNull?.receptors.firstOrNull;
  }

  List<CodeReceptor> getAllReceptors() {
    List<CodeReceptor> result = [];
    for (var element in elements) {
      result.addAll(element.receptors);
    }
    return result;
  }
}

class ScreenBundle extends LayoutBundle {
  var isLauncher = false;

  ScreenBundle(super.name);
}

// ============

enum ReceptorType {
  doOnDataChanged,
  doOnClick,
  doOnSwitch,
  doOnTextChanged
}

enum ActionType {
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
  android("Android"), ios("iOS"), flutter("Flutter"), addNew("Add New");

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

    for (var n in contentNodes) {
      _addNodesToListWhere(nodes, n, condition);
    }
    return nodes;
  }

  void _addNodesToListWhere(List<ElementNode> nodesResult, ElementNode node,
      bool Function(ElementNode node) condition) {
    if (condition.call(node)) {
      nodesResult.add(node);
    }

    for (var n in node.contentNodes) {
      _addNodesToListWhere(nodesResult, n, condition);
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

  String id;
  Color color;

  int widgetId;

  List<ViewType> viewTypes = [];
  ViewType selectedViewType = ViewType.otherView;

  late AreaBundle area;

  List<CodeReceptor> receptors = [];

  CodeElement(this.widgetId, this.id, this.color);

  bool contains(CodeElement elementContent) {
    return area.rect.contains(elementContent.area.rect.topLeft) &&
        area.rect.contains(elementContent.area.rect.bottomRight);
  }
}

class CodeReceptor {
  String id;

  String description = "";

  ReceptorType type;

  String name;
  Color color = Colors.deepPurpleAccent;

  List<CodeAction> actions = [];

  bool isActive = false;

  CodeReceptor({required this.id,
        required this.type,
        required this.name});
}
class CodeAction {
  String id;

  String? dataSourceId;

  ActionType type;

  String name;

  bool withComment = false;
  bool withDataSource = false;

  NextScreenValue? nextScreenValue;

  CodeAction(
      {required this.id,
      required this.type,
      required this.name});
}
class ActionValue {
  ActionType type;
  ActionValue(this.type);
}

class NextScreenValue extends ActionValue {
  ScreenBundle nextScreenBundle;

  NextScreenValue(this.nextScreenBundle) : super(ActionType.moveToNextScreen);
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
