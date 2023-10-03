import 'dart:ui';

import 'package:structure_compositor/screens/editor/generator/layout_code_generator.dart';
import 'package:structure_compositor/screens/editor/generator/logic_code_generator.dart';

import '../../box/data_classes.dart';
import 'generator/data_code_generator.dart';
import 'generator/settings_code_generator.dart';

var areasEditorFruit = AreasEditorFruit();
var eraEditorFruit = EraEditorFruit();
var actionsEditorFruit = ActionsEditorFruit();

class AreaBundle {
  Rect rect;
  Color color;

  AreaBundle(this.rect, this.color);
}

void disposeFruitListeners() {
  areasEditorFruit.onNewArea.clear();
  areasEditorFruit.onSelectedLayoutChanged.clear();
  eraEditorFruit.onDownloadAllClick.clear();
  eraEditorFruit.onStructureChanged.clear();
  eraEditorFruit.onFilesTabChanged.clear();
}

class AreasEditorFruit {
  AreaBundle? lastArea;

  List<Function(AreaBundle)> onNewArea = [(AreaBundle area) {}];
  void callOnNewArea(AreaBundle area) {
    for (var f in onNewArea) {
      f.call(area);
    }
  }

  List<Function> onSelectedLayoutChanged = [];
  void callOnSelectedLayoutChanged() {
    for (var f in onSelectedLayoutChanged) {
      f.call();
    }
  }

  void resetData() {
    lastArea = null;
  }
}

class EraEditorFruit {
  final actionsEditorTypeSelectorState = [
    true, // Action 0
    false, // Prompts 1
  ];

  final filesEditorTypeSelectorState = [
    false, // Settings 0
    false, // Logic 1
    false, // Layout 2
    false, // Data 3
  ];

  LayoutCodeGenerator layoutGenerator = LayoutCodeGenerator();
  LogicCodeGenerator logicGenerator = LogicCodeGenerator();
  SettingsCodeGenerator settingsGenerator = SettingsCodeGenerator();
  DataCodeGenerator dataGenerator = DataCodeGenerator();

  FilesEditModeType selectedFilesEditMode = FilesEditModeType.none;

  List<Function> onDownloadAllClick = [];

  void callOnDownloadAllClick() {
    for (var f in onDownloadAllClick) {
      f.call();
    }
  }

  List<Function(LayoutBundle?)> onStructureChanged = [];

  void callOnStructureChanged(LayoutBundle? layout) {
    for (var f in onStructureChanged) {
      f.call(layout);
    }
  }

  List<Function> onFilesTabChanged = [];

  void callOnFilesTabChanged() {
    for (var f in onFilesTabChanged) {
      f.call();
    }
  }
}

class ActionsEditorFruit {
  ActionsEditModeType selectedActionsEditMode = ActionsEditModeType.actions;
}
