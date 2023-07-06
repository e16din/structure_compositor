import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class AppDataFruits {
  @HiveField(0)
  List<Project> projects = [];

  @HiveField(1)
  Project? selectedProject;

  AppDataFruits();
}

class Project {
  String name = "";

  List<ScreenBundle> screenBundles = [];

  ScreenBundle? selectedScreenBundle;

  Project({required this.name});
}

@HiveType(typeId: 2)
class ScreenBundle {
  @HiveField(0)
  String name;

  @HiveField(1)
  String? layoutPath;

  Uint8List? layoutBytes;

  @HiveField(2)
  List<ScreenElement> elements = <ScreenElement>[];

  var isLauncher = false;

  ScreenBundle(this.name);
}

// enum FunctionType { LookAt, ClickOn, SelectFrom, TypeIn }
enum ViewType {
  unknown,
  label,
  field,
  button,
  image,
  selector,
  container,
  list,
  listItem,
}

class ScreenElement {
  late Rect functionalArea;

  late Color color;

  ViewType viewType = ViewType.unknown;

  String name = "";

  String value = "";

  String description = "";

  List<ListenerCodeBlock> listeners = [];

  bool inEdit = false;

  ScreenElement(this.functionalArea, this.color, this.inEdit);

  bool hasDataSource() {
    return viewType == ViewType.list; // todo: add data sources feature
  }
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
