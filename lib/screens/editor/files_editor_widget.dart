import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:structure_compositor/box/data_classes.dart';

import '../../box/app_utils.dart';
import '../../box/widget_utils.dart';
import 'areas_editor_widget.dart';
import 'fruits.dart';

import 'package:highlight/languages/xml.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/androidstudio.dart';
import 'package:flutter_highlight/themes/vs.dart';
import 'package:flutter_highlight/themes/xcode.dart';
import 'package:highlight/languages/markdown.dart';

class PlatformFilesEditorWidget extends StatefulWidget {
  const PlatformFilesEditorWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return PlatformFilesEditorState();
  }
}

class PlatformFilesEditorState extends State<PlatformFilesEditorWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var layout = getLayoutBundle();

    switch (platformFilesEditorFruit.selectedPlatformEditMode) {
      case PlatformEditModeType.none:
        // do nothing
        break;
      case PlatformEditModeType.settings:
        if (layout != null) {
          return Container(width: 640);
        }
        break;
      case PlatformEditModeType.logic:
        if (layout != null) {
          debugPrint("init === logic");
          return _buildEditorWidget(layout.logicFiles);
        }
        break;
      case PlatformEditModeType.layout:
        if (layout != null) {
          debugPrint("init === layout");
          return _buildEditorWidget(layout.layoutFiles);
        }
        break;

      case PlatformEditModeType.data:
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
            color: Colors.black45,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IntrinsicWidth(
                        child: Container(
                      constraints: const BoxConstraints(minWidth: 180),
                      child: TextFormField(
                          key: Key("${files[index].fileName.toString()}.name"),
                          initialValue: files[index].fileName),
                    )),
                    IconButton(
                        icon: const Icon(
                          Icons.copy,
                          size: 16,
                        ),
                        onPressed: () {
                          String codeText = files[index].codeController.text;
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
                    controller: files[index].codeController,
                    textStyle: const TextStyle(fontFamily: 'SourceCode'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
