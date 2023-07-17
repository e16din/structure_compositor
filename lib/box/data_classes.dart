import 'dart:typed_data';

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';

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
  List<CodeFile> layoutFiles = [];
  List<CodeFile> codeFiles = [];

  Map<LayoutElement, List<LayoutElement>> listLinkListItemsMap =
      {}; // todo: move it

  LayoutBundle(this.name);

  CodeElement getElementByAction(CodeAction action) {
    return elements
        .firstWhere((element) => element.elementId == action.elementId);
  }

  void sortElements() {
    elements.sort((a, b) {
      return a.area.topLeft.dy.compareTo(b.area.topLeft.dy);
    });
  }

  void sortActionsByElement() {
    actions.sort((a, b) => a.elementId.compareTo(b.elementId));
  }

  void removeElement(CodeElement element) {
    elements.remove(element);
    for (var e in elements) {
      e.content.remove(element.elementId);
    }
  }

  void setActiveAction(CodeAction action) {
    for (var a in actions) {
      a.isActive = action.actionId == a.actionId;
    }
  }

  CodeAction getActiveAction() {
    return actions.firstWhere((e) => e.isActive);
  }

  CodeElement getActiveElement() {
    var activeAction = getActiveAction();
    var activeElement =
        elements.firstWhere((e) => e.elementId == activeAction.elementId);
    return activeElement;
  }

  void resetActiveAction() {
    for (var element in actions) {
      element.isActive = false;
    }
    actions.first.isActive = true;
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
  doOnTextChanged,
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

enum CodeLanguage { unknown, xml, kotlin }

class CodeFile {
  String fileName;
  CodeLanguage language;

  CodeController codeController;

  CodeFile(this.language, this.fileName, this.codeController);
}

class CodeElement {
  String elementId;
  Color elementColor;

  List<ViewType> viewTypes = [];
  ViewType selectedViewType = ViewType.otherView;

  Rect area = _defaultArea;

  List<String> content = []; // list of elementId

  bool isContainer() => content.isNotEmpty;

  CodeElement(this.elementId, this.elementColor);
}

final Rect _defaultArea =
    Rect.fromCenter(center: const Offset(100, 100), width: 100, height: 100);

class CodeAction {
  late String elementId;
  late String actionId;

  String? dataSourceId;
  String? comment;

  CodeActionType type;

  String name;
  Color actionColor = Colors.deepPurpleAccent;
  bool isContainer = false;
  bool withComment = false;
  bool withDataSource = false;

  List<CodeAction> actions = [];

  bool isActive = false;

  CodeAction(
      {required this.type, required this.name, required this.isContainer});
}

// ===============

enum ViewType {
  button("Button"),
  text("Text"),
  field("Field"),
  image("Image"),
  selector("Selector"),
  list("List"),
  listItem("List Item"),
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
