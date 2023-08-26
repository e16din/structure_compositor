import 'dart:ui';

import 'package:structure_compositor/screens/editor/generator/layout_code_generator.dart';
import 'package:structure_compositor/screens/editor/generator/logic_code_generator.dart';

import '../../box/data_classes.dart';

var areasEditorFruit = AreasEditorFruit();
var platformFilesEditorFruit = PlatformFilesEditorFruit();
var actionsEditorFruit = ActionsEditorFruit();

class AreasEditorFruit {
  Rect? lastRect;
  Color? lastColor;
  String? lastElementId;

  var onNewArea = () {};
  var onSelectedLayoutChanged = (LayoutBundle? layout) {};

  void resetData() {
    lastRect = null;
    lastColor = null;
    lastElementId = null;
  }
}

class PlatformFilesEditorFruit {
  var package = "com.example";

  LayoutCodeGenerator layoutGenerator = LayoutCodeGenerator();
  LogicCodeGenerator logicGenerator = LogicCodeGenerator();

  PlatformEditModeType selectedPlatformEditMode = PlatformEditModeType.none;
}

class ActionsEditorFruit {
  ActionsEditModeType selectedActionsEditMode = ActionsEditModeType.actions;
}