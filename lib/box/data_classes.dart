import 'dart:typed_data';

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

  List<LayoutElement> elements = <LayoutElement>[];

  Map<LayoutElement, List<LayoutElement>> listLinkListItemsMap = {}; // todo: move it


  LayoutBundle(this.name);
}

class ScreenBundle extends LayoutBundle {

  var isLauncher = false;

  ScreenBundle(super.name);

}

enum ViewType {
  unknown,
  label,
  field,
  button,
  image,
  selector,
  column, // vertical
  row, // horizontal
  stack, // frame
  list
}

class LayoutElement {
  late Rect functionalArea;

  late Color color;

  ViewType viewType = ViewType.unknown;

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

enum ActionCodeType {
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
  List<ActionCodeBlock> actions = [];

  ListenerCodeBlock(this.listenerType){
    name = "${listenerType.name}() { }";
    color = Colors.purple;
  }

  @override
  ListenerCodeBlock copyBlock() {
    return ListenerCodeBlock(listenerType);
  }
}

class ActionCodeBlock extends CodeBlock {
  ActionCodeType actionType;
  List<ListenerCodeBlock> listeners =
      []; // NOTE: for actions with result (async actions, callbacks)

  ActionCodeBlock(this.actionType){
    name = "${actionType.name}()";
    color = Colors.green;
  }

  @override
  ActionCodeBlock copyBlock() {
    return ActionCodeBlock(actionType);
  }
}

class OpenNextScreenBlock extends ActionCodeBlock {
  ScreenBundle? nextScreenBundle;

  OpenNextScreenBlock(): super(ActionCodeType.openNextScreen);

  OpenNextScreenBlock copyStubWith(ScreenBundle nextScreenBundle) {
    return OpenNextScreenBlock()
      ..nextScreenBundle = nextScreenBundle;
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

  LifecycleEventBlock(): super(ListenerCodeType.onLifecycleEvent) {
    color = Colors.purple.withOpacity(0.7);
  }

  LifecycleEventBlock copyStubWith(String selectedEvent) {
    return LifecycleEventBlock()
      ..selectedEvent = selectedEvent;
  }
}
