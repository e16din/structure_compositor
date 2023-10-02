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

class AreasEditorFruit {
  AreaBundle? lastArea;

  var onNewArea = (AreaBundle area) {};
  var onSelectedLayoutChanged = () {};

  void resetData() {
    lastArea = null;
  }
}

class EraEditorFruit {
  LayoutCodeGenerator layoutGenerator = LayoutCodeGenerator();
  LogicCodeGenerator logicGenerator = LogicCodeGenerator();
  SettingsCodeGenerator settingsGenerator = SettingsCodeGenerator();
  DataCodeGenerator dataGenerator = DataCodeGenerator();

  PlatformEditModeType selectedPlatformEditMode = PlatformEditModeType.none;

  var onDownloadAllClick = () {};

  var onStructureChanged = (LayoutBundle layout) {};
}

class ActionsEditorFruit {
  ActionsEditModeType selectedActionsEditMode = ActionsEditModeType.actions;
}