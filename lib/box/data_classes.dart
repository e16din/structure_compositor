import 'dart:typed_data';
import 'dart:ui';

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
  Unknown,
  Label,
  Field,
  Button,
  Image,
  Selector,
  Container,
  List,
  ListItem,
}

class ScreenElement {
  late Rect functionalArea;

  late Color color;

  ViewType viewType = ViewType.Unknown;

  String name = "";

  String value = "";

  String description = "";

  List<CodeBlock> listeners = [];

  bool inEdit = false;

  ScreenElement(this.functionalArea, this.color, this.inEdit);

  bool hasDataSource() {
    return viewType == ViewType.List; // todo: add data sources feature
  }
}

enum CodeType { action, listener }

@HiveType(typeId: 3)
class CodeBlock {
  CodeType type;
  String name;
  Color color;

  List<CodeBlock> actions = [];
  String description = "";

  CodeBlock(this.name, this.type, this.color);

  CodeBlock copyStub() {
    return CodeBlock(name, type, color)
      ..actions = []
      ..description = "";
  }
}

class OpenNextScreenBlock extends CodeBlock {
  ScreenBundle? nextScreenBundle;

  OpenNextScreenBlock(super.name, super.type, super.color);

  OpenNextScreenBlock copyStubWith(ScreenBundle nextScreenBundle) {
    return OpenNextScreenBlock(name, type, color)
      ..nextScreenBundle = nextScreenBundle
      ..actions = []
      ..description = "";
  }
}

class BackToPreviousBlock extends CodeBlock {
  BackToPreviousBlock(super.name, super.type, super.color);

  BackToPreviousBlock copyBackToPreviousBlock() {
    return BackToPreviousBlock(name, type, color);
  }
}

class LifecycleEventBlock extends CodeBlock {
  var events = [
    "onCreate() { }",
    "onStart() { }",
    "onResume() { }",
    "onPause() { }",
    "onStop() { }",
  ];

  late String selectedEvent;

  LifecycleEventBlock(super.name, super.type, super.color);

  LifecycleEventBlock copyStubWith(String selectedEvent) {
    return LifecycleEventBlock(name, type, color)
      ..selectedEvent = selectedEvent;
  }
}
