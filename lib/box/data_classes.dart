import 'dart:io';
import 'dart:typed_data';

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:structure_compositor/screens/editor/fruits.dart';

const PROPERTIES_FILE_NAME = "project.properties";
const PROJECT_FILE_NAME = "project.xml";
const PROJECTS_LIST_FILE_NAME = "projects_list.txt";
const RULES_LIST_FILE_NAME = "rules_list.properties";

class AppDataFruits {
  List<Project> projects = [];

  Project? selectedProject;

  Map<String, String> rulesMap = {}; // NOTE: rule name => rule path

  AppDataFruits();
}

class Project {

  String name = "";

  String path = "";

  String selectedRule = "";

  List<ScreenBundle> screens = [];

  ScreenBundle? selectedScreen;

  List<CodeFile> settingsFiles = [];

  String properties = "";
  Map<String, String> propertiesMap = {};

  Project({required this.name, required this.path});

  void initProperties() async {
    var projectPropertiesFile = File("${path}/$PROPERTIES_FILE_NAME");
    properties = await projectPropertiesFile.readAsString();
    var lines = properties.split("\n");

    propertiesMap.clear();
    for (var prop in lines) {
      var pair = prop.split("=");
      if (pair.length > 1) {
        propertiesMap[pair[0]] = pair[1];

        debugPrint("prop: ${prop} | value: ${pair[1]}");
      }
    }
  }
}

class LayoutBundle {
  String name;
  String? path;
  List<CodeElement> elements = [];
  
  Uint8List? layoutBytes;
  List<CodeFile> layoutFiles = [];
  List<CodeFile> logicFiles = [];
  List<CodeFile> dataFiles = [];

  CodeReceptor? activeReceptor;
  CodeElement? activeElement;

  LayoutBundle(this.name);

  void resetActiveElement() {
    activeElement = elements.firstOrNull;
  }

  void resetActiveAction() {
    activeReceptor = elements.firstOrNull?.receptors.firstOrNull;
  }
}

class ScreenBundle {
  
  String name = "";

  var isLauncher = false;

  List<LayoutBundle> layouts = [];

  LayoutBundle? selectedLayout;

  ScreenBundle();
}

// ============

enum ReceptorType { doOnDataChanged, doOnClick, doOnSwitch, doOnTextChanged }

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

// enum SystemType {
//   //todo: load from files
//   android("Android"),
//   ios("iOS"),
//   flutter("Flutter"),
//   ai_prompt("AI Prompt"),
//   pseudo_code("Pseudo Code"),
//   addNew("Add New");
//
//   const SystemType(this.title);
//
//   final String title;
// }

enum ActionsEditModeType {
  none,
  actions, // NOTE: actions editor
  prompts, // NOTE: actions editor
}

enum FilesEditModeType {
  none,
  settings, // NOTE: Manifest, ..
  logic, // NOTE: Activity, Adapter, ..
  layout, // NOTE: xml, Compose, ..
  data // NOTE: DataSource, ..
}

class CodeFile {
  String fileName;

  String text;
  CodeLanguage codeLanguage = CodeLanguage.unknown;

  ElementNode? elementNode;

  String localPath; // example: /src/main/java/com/example/screens
  String package;

  String chewbaccaFilePath;

  CodeFile(this.fileName, this.text, this.codeLanguage, this.elementNode,
      this.localPath, this.package, this.chewbaccaFilePath);

  String getPathWithName() {
    return "$localPath/$fileName";
  }
}

enum CodeLanguage {
  xml,
  kotlin,
  properties,
  unknown
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
      return a.element.area.rect.topLeft.dy
          .compareTo(b.element.area.rect.topLeft.dy);
    });
    for (var n in contentNodes) {
      _sortElementsByY(n);
    }
  }

  void _sortElementsByY(ElementNode n) {
    n.contentNodes.sort((a, b) {
      return a.element.area.rect.topLeft.dy
          .compareTo(b.element.area.rect.topLeft.dy);
    });
  }
}

class CodeElement {
  String id;

  List<ViewType> viewTypes = [];
  ViewType selectedViewType = ViewType.otherView;

  late AreaBundle area;

  List<CodeReceptor> receptors = [];

  CodeElement(this.id);

  bool contains(CodeElement elementContent) {
    return area.rect.contains(elementContent.area.rect.topLeft) &&
        area.rect.contains(elementContent.area.rect.bottomRight);
  }
}

class CodeReceptor {
  String id;
  String name;

  String description = "";
  ReceptorType type;

  List<CodeAction> actions = [];

  bool isActive = false;

  CodeReceptor({required this.id, required this.type, required this.name});
}

class CodeAction {
  String id;
  String name;

  ActionType type;

  String description = "";

  NextScreenValue? nextScreenValue;
  DataSourceValue? dataSourceValue;

  CodeAction({required this.id, required this.type, required this.name});
}

class CodeDataSource {
  String name = "";
// todo:
}

class ActionValue {
  ActionType type;

  ActionValue(this.type);
}

class NextScreenValue extends ActionValue {
  String name = "";

  NextScreenValue(this.name) : super(ActionType.moveToNextScreen);
}

class DataSourceValue extends ActionValue {
  String? dataSourceId;
  CodeDataSource dataSource;

  DataSourceValue(this.dataSource) : super(ActionType.updateDataSource);
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
