import 'dart:ui';

import 'package:structure_compositor/screens/editor/generator/layout_code_generator.dart';
import 'package:structure_compositor/screens/editor/generator/logic_code_generator.dart';

import '../../box/data_classes.dart';
import 'generator/settings_code_generator.dart';

var areasEditorFruit = AreasEditorFruit();
var platformFilesEditorFruit = PlatformFilesEditorFruit();
var actionsEditorFruit = ActionsEditorFruit();

class AreaBundle {
  Rect rect;
  Color color;
  String elementId;

  AreaBundle(this.rect, this.color, this.elementId);
}

class AreasEditorFruit {
  AreaBundle? lastArea;

  var onNewArea = (AreaBundle area) {};
  var onSelectedLayoutChanged = (LayoutBundle? layout) {};

  void resetData() {
    lastArea = null;
  }
}

class PlatformFilesEditorFruit {
  LayoutCodeGenerator layoutGenerator = LayoutCodeGenerator();
  LogicCodeGenerator logicGenerator = LogicCodeGenerator();
  SettingsCodeGenerator settingsGenerator = SettingsCodeGenerator();

  PlatformEditModeType selectedPlatformEditMode = PlatformEditModeType.none;
}

class ActionsEditorFruit {
  ActionsEditModeType selectedActionsEditMode = ActionsEditModeType.actions;
}