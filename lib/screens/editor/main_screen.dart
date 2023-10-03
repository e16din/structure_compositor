// import 'dart:convert';
// import 'dart:ffi';

// import 'dart:ffi';
// import 'dart:math';
// import 'dart:typed_data';

import 'dart:io';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:structure_compositor/screens/editor/areas_editor_widget.dart';
import 'package:structure_compositor/screens/editor/era_editor_widget.dart';
import '../../box/app_utils.dart';
import '../../box/data_classes.dart';
import '../start_screen.dart';
import 'fruits.dart';

class MainScreen extends StatefulWidget {
  MainScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MainPageState();
  }
}

class _MainPageState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();

    appFruits.selectedProject!.initProperties();

    areasEditorFruit.onSelectedLayoutChanged.add(() {
      setState(() {
        // _updateFiles();
      });
    });

    eraEditorFruit.onFilesTabChanged.add(() {
      setState(() {
        // _updateFiles();
      });
    });

    eraEditorFruit.onDownloadAllClick.add(() {
      _downloadAllProjectFiles();
    });

    eraEditorFruit.onStructureChanged.add((layout) {
      setState(() {
        _onStructureChanged(layout);
      });

      //todo:
      // var projectXml = _makeProjectXml();
      // File("${appFruits.selectedProject!.path}/project.xml")
      //     .writeAsString(projectXml);
    });
  }

  void _onStructureChanged(LayoutBundle? layout) async {
    var rootNode =
        ElementsTreeBuilder.buildTree(layout != null ? layout.elements : []);

    if (layout != null) {
      eraEditorFruit.layoutGenerator.updateFiles(rootNode, layout);
      eraEditorFruit.logicGenerator.updateFiles(rootNode, layout);
      eraEditorFruit.dataGenerator.updateFiles(rootNode, layout);
    }

    eraEditorFruit.settingsGenerator.updateFiles();

    //todo:
    // var projectXml = _makeProjectXml();
    // File("${appFruits.selectedProject!.path}/project.xml")
    //     .writeAsString(projectXml);
  }

  @override
  void dispose() {
    disposeFruitListeners();
    EasyDebounce.cancelAll();
    areasEditorFruit.resetData();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("build!");
    return Scaffold(
      appBar: AppBar(
        title: Text('Structure Compositor: Code Editor'),
      ),
      body: Row(
        children: [
          EraEditorWidget(),
          AreasEditorWidget() // ATTENTION: do not add 'const'!
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _onAddLayoutPressed();
        },
        tooltip: 'Select layout',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _onAddLayoutPressed() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: true);

    if (result != null) {
      List<ScreenBundle> resultScreens = [];
      for (var f in result.files) {
        var layoutBytes = f.bytes;

        int index = appFruits.selectedProject!.screens.length;
        ScreenBundle screenBundle = ScreenBundle()..isLauncher = index == 0;
        var layoutBundle = LayoutBundle("New Screen ${index + 1}");
        screenBundle.layouts.add(layoutBundle);

        debugPrint("Add screen: ${layoutBundle.name}");

        if (layoutBytes != null) {
          layoutBundle.layoutBytes = layoutBytes;
        } else if (f.path != null) {
          layoutBundle.layoutBytes = await readFileByte(f.path!);
        }

        resultScreens.add(screenBundle);
        appFruits.selectedProject!.screens.add(screenBundle);
      }

      appFruits.selectedProject!.selectedScreen = resultScreens.first;
      appFruits.selectedProject!.selectedScreen!.selectedLayout =
          appFruits.selectedProject!.selectedScreen!.layouts.first;

      for (var layout in resultScreens.mapMany((screen) => screen.layouts)) {
        var rootColor = Colors.white;
        var rootId = "rootContainer";
        var rootElement = CodeElement(rootId)
          ..viewTypes = [ViewType.otherView]
          ..selectedViewType = ViewType.otherView
          ..area = AreaBundle(Rect.largest, rootColor);

        layout.elements.add(rootElement);
        eraEditorFruit.callOnStructureChanged(layout);
      }

      setState(() {});
    }
  }

  String _makeProjectXml() {
    var project = appFruits.selectedProject!;
    var result = "";

    var screens = "";
    project.screens.forEach((screen) {
      String layouts = "";
      screen.layouts.forEach((layout) {
        String elements = "";
        layout.elements.forEach((element) {
          String area =
              """              <area rect="${element.area.rect}" color="${toHex(element.area.color)}"" />\n\n""";

          String receptors = "";
          element.receptors.forEach((receptor) {
            String actions = "";
            receptor.actions.forEach((action) {
              String nextScreenValue = "";
              if (action.nextScreenValue != null) {
                nextScreenValue =
                    """                 <next_scree_value name="${action.nextScreenValue?.name}" />""";
              }
              String dataSourceValue = "";
              if (action.dataSourceValue != null) {
                dataSourceValue =
                    """                 <data_source_value id="${action.dataSourceValue?.dataSourceId}" />""";
              }

              actions += """
              <action id="${action.id}" name="${action.name}" type="${action.type}" description="${action.description}">
$nextScreenValue

$dataSourceValue
              </action>\n\n""";
            });

            receptors += """
              <receptor id="${receptor.id}" name="${receptor.name}" description="${receptor.description}" type="${receptor.type}">
$actions
              </receptor>\n\n""";
          });
          elements += """
              <element id="${element.id}" viewTypes="${element.viewTypes.toString()}" selectedViewType="${element.selectedViewType}">
$area

$receptors
              </element>\n\n""";
        });

        layouts += """
          <layout name="${layout.name}" path="${layout.path}">
$elements
          </layout>\n\n""";
      });

      screens += """
      <screen name="${screen.name}" isLauncher="${screen.isLauncher}">
$layouts
      </screen>\n\n""";
    });

    result += """<?xml version="1.0" encoding="UTF-8"?>
<project name="${project.name} rule="${appFruits.selectedProject!.selectedRule}">
    $screens
</project>""";

    return result;
  }

  void _downloadAllProjectFiles() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    debugPrint("selectedDirectory: $selectedDirectory");

    if (selectedDirectory != null) {
      appFruits.selectedProject?.settingsFiles.forEach((file) async {
        var path = "$selectedDirectory${file.localPath}";
        var directory = Directory(path);
        try {
          directory.deleteSync(recursive: true);
        } catch (Exception) {}
        await directory.create(recursive: true);
        await File("$path/${file.fileName}").writeAsString(file.text);
      });

      appFruits.selectedProject?.screens
          .mapMany((screen) => screen.layouts)
          .forEach((element) {
        element.layoutFiles.forEach((file) async {
          var path = "$selectedDirectory/${file.localPath}";
          var directory = Directory(path);
          try {
            directory.deleteSync(recursive: true);
          } catch (Exception) {}
          await directory.create(recursive: true);
          await File("$path/${file.fileName}").writeAsString(file.text);
        });

        element.logicFiles.forEach((file) async {
          var path = "$selectedDirectory${file.localPath}";
          var directory = Directory(path);
          try {
            directory.deleteSync(recursive: true);
          } catch (Exception) {}
          await directory.create(recursive: true);
          await File("$path/${file.fileName}").writeAsString(file.text);
        });

        element.dataFiles.forEach((file) async {
          var path = "$selectedDirectory${file.localPath}";
          var directory = Directory(path);
          try {
            directory.deleteSync(recursive: true);
          } catch (Exception) {}
          await directory.create(recursive: true);
          await File("$path/${file.fileName}").writeAsString(file.text);
        });
      });

      var message = 'Code has been saved to the directory: $selectedDirectory';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class ElementsTreeBuilder {
  const ElementsTreeBuilder();

  static ElementNode buildTree(List<CodeElement> elements) {
    elements.sort((a, b) => (b.area.rect.width * b.area.rect.height)
        .compareTo(a.area.rect.width * a.area.rect.height));
    var root = ElementNode(elements.first);
    for (var i = 1; i < elements.length; i++) {
      _addContent(root, ElementNode(elements[i]));
    }

    root.sortElementsByY();
    return root;
  }

  static void _addContent(ElementNode container, ElementNode content) {
    for (var node in container.contentNodes) {
      if (node.element.contains(content.element)) {
        _addContent(node, content);
        return;
      }
    }
    container.addContent(content);
  }
}
