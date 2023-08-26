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
          debugPrint("=== logic");
          return _buildEditorWidget(layout.logicFiles);
        }
        break;
      case PlatformEditModeType.layout:
        if (layout != null) {
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
    debugPrint("=== files size: ${files.length}");
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
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                        width: 120,
                        child:
                            TextFormField(initialValue: files[index].fileName)),
                    FilledButton(
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.blueAccent)),
                        onPressed: () {
                          String codeText = files[index].codeController.text;
                          Clipboard.setData(ClipboardData(text: codeText))
                              .then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Copied to your clipboard!')));
                          });
                        },
                        child: const Text("Copy It",
                            style: TextStyle(fontSize: 12),
                            textAlign: TextAlign.center)),
                  ],
                ),
                CodeTheme(
                  data: const CodeThemeData(styles: monokaiSublimeTheme),
                  child: CodeField(
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
