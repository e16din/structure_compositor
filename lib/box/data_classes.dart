import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:structure_compositor/box/app_utils.dart';

class AppDataFruits {
  List<Project> projects = [];

  Project? selectedProject;

  AppDataFruits();
}

class Project {
  String name = "";

  List<LayoutBundle> layouts = [];

  LayoutBundle? selectedLayout;

  Project({required this.name});
}

class LayoutBundle {
  String name;

  String? layoutPath;

  Uint8List? layoutBytes;

  List<LayoutElement> elementsMain = [];

  List<CodeAction> actions = [];
  List<CodeElement> elements = [];

  Map<LayoutElement, List<LayoutElement>> listLinkListItemsMap =
      {}; // todo: move it

  LayoutBundle(this.name);

  CodeElement getElementByAction(CodeAction action) =>
      elements.firstWhere((element) => element.elementId == action.elementId);

  void sortActionsByElement() {
    actions.sort((a, b) => a.elementId.compareTo(b.elementId));
  }
}

class ScreenBundle extends LayoutBundle {
  var isLauncher = false;

  ScreenBundle(super.name);
}

// ============

enum ActionCodeType {
  // Containers
  doOnInit,
  doOnClick,
  doOnDataChanged,
  // View
  nothing,
  showText,
  showImage,
  showList,
  updateDataSource,
  // Navigation
  moveToNextScreen,
  moveToBackScreen,
  // Comment
  todo,
  note,
}

enum EditorType { actionsEditor, codeEditor, layoutEditor }

class CodeElement {
  String elementId;
  Color elementColor;

  CodeElement(this.elementId, this.elementColor);
}

class CodeAction {
  late String elementId;
  late String actionId;

  String? dataSourceId;
  String? comment;

  ActionCodeType type;
  String name;
  Color actionColor = Colors.deepPurpleAccent;
  bool isContainer = false;
  bool withComment = false;
  bool withDataSource = false;

  List<CodeAction> actions = [];

  Rect layoutArea;

  CodeAction(
      {required this.type,
      required this.name,
      required this.isContainer,
      required this.layoutArea});
}

// ===============

enum ViewType {
  button("Button"),
  label("Label"),
  field("Field"),
  image("Image"),
  selector("Selector"),
  list("List"),
  combine("Stack Container");

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
    return viewType == ViewType.list; // todo: add data sources feature
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
