import 'dart:io';

import 'package:code_text_field/code_text_field.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:structure_compositor/box/data_classes.dart';

import '../../box/app_utils.dart';
import '../../box/widget_utils.dart';
import '../start_screen.dart';
import 'areas_editor_widget.dart';
import 'fruits.dart';

import 'package:highlight/languages/xml.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/androidstudio.dart';
import 'package:flutter_highlight/themes/vs.dart';
import 'package:flutter_highlight/themes/xcode.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:highlight/languages/kotlin.dart';
import 'package:highlight/languages/properties.dart';

class FilesListWidget extends StatefulWidget {
  const FilesListWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return FilesListState();
  }
}

class FilesListState extends State<FilesListWidget> {
  @override
  void initState() {
    super.initState();

    _initControllers();
    areasEditorFruit.onSelectedLayoutChanged.add(() {
      _initControllers();
    });
    eraEditorFruit.onStructureChanged.add((layout) {
      _initControllers();
    });
  }

  void _initControllers() {
    getSelectedProject()?.settingsFiles.forEach((file) {
      _initCodeController(file);
    });

    var layout = getLayoutBundle();
    if (layout != null) {
      for (var file
          in layout.layoutFiles + layout.logicFiles + layout.dataFiles) {
        _initCodeController(file);
      }
    }
  }

  void _initCodeController(CodeFile file) {
    var key = file.getPathWithName();
    if (_codeControllersMap.containsKey(key)) {
      _codeControllersMap[key]?.text = file.text;
    } else {

      var codeController = CodeController(
          language: _getLanguage(file.codeLanguage), text: file.text);
      _codeControllersMap[key] = codeController;

      if (file.fileName == PROPERTIES_FILE_NAME) {
        codeController.addListener(() {
          EasyDebounce.debounce('properties', const Duration(milliseconds: 500),
              () {
            File("${appFruits.selectedProject!.path}/$PROPERTIES_FILE_NAME")
                .writeAsString(file.text);
          });
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();

    _codeControllersMap.forEach((key, value) {
      value.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    var project = appFruits.selectedProject!;
    var layout = getLayoutBundle();

    switch (eraEditorFruit.selectedFilesEditMode) {
      case FilesEditModeType.none:
        // do nothing
        break;
      case FilesEditModeType.settings:
        return _buildEditorWidget(project.settingsFiles);
      case FilesEditModeType.logic:
        if (layout != null) {
          return _buildEditorWidget(layout.logicFiles);
        }
        break;
      case FilesEditModeType.layout:
        if (layout != null) {
          return _buildEditorWidget(layout.layoutFiles);
        }
        break;

      case FilesEditModeType.data:
        if (layout != null) {
          return Container(width: 640);
        }
        break;
    }

    return Container(width: 640);
  }

  Widget _buildEditorWidget(List<CodeFile> files) {
    return Container(
      width: 640,
      child: ListView.separated(
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 16,
          endIndent: 24,
        ),
        scrollDirection: Axis.vertical,
        itemCount: files.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            padding: const EdgeInsets.only(top: 12, left: 8, right: 8),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.green,
                  style: BorderStyle.solid,
                  width: 0.6,
                ),
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(files[index].fileName)),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        onPressed: () {
                          // todo: show editor to edit single file template
                        },
                      ),
                      IconButton(
                          icon: const Icon(
                            Icons.copy,
                            size: 16,
                          ),
                          onPressed: () {
                            String codeText = files[index].text;
                            Clipboard.setData(ClipboardData(text: codeText))
                                .then((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Copied to your clipboard!')));
                            });
                          })
                    ],
                  ),
                  CodeTheme(
                    data: const CodeThemeData(styles: androidstudioTheme),
                    // androidstudio, xcode, vs, monokai-sublime
                    child: CodeField(
                      key: Key(files[index].fileName.toString()),
                      controller: _getCodeController(files[index]),
                      textStyle: const TextStyle(fontFamily: 'SourceCode'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, CodeController> _codeControllersMap = {};

  CodeController _getCodeController(CodeFile file) {
    var key = file.getPathWithName();
    return _codeControllersMap[key]!;
  }

  _getLanguage(CodeLanguage codeLanguage) {
    return switch (codeLanguage) {
      CodeLanguage.xml => xml,
      CodeLanguage.kotlin => kotlin,
      CodeLanguage.properties => properties,
      CodeLanguage.unknown => markdown
    };
  }
}
