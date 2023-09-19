import 'dart:io';
import 'dart:math';

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:structure_compositor/box/data_classes.dart';

import '../../box/app_utils.dart';

import 'package:flutter_highlight/themes/androidstudio.dart';
import 'package:flutter_highlight/themes/vs.dart';

class ChewbaccaEditorScreen extends StatelessWidget {
  final CodeFile codeFile;

  const ChewbaccaEditorScreen(this.codeFile, {super.key});

// This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChewbaccaEditorPage(codeFile),
    );
  }
}

class ChewbaccaEditorPage extends StatefulWidget {
  final CodeFile codeFile;

  const ChewbaccaEditorPage(this.codeFile, {Key? key}) : super(key: key);

  @override
  State<ChewbaccaEditorPage> createState() => _ChewbaccaEditorPageState(codeFile);
}

class _ChewbaccaEditorPageState extends State<ChewbaccaEditorPage> {
  CodeFile codeFile;

  late CodeController chewbaccaController;


  _ChewbaccaEditorPageState(this.codeFile) {



    // chewbaccaController = CodeController(text: codeFile.codeController);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Chewbacca Editor"),
        ),
        body: Row(
          children: [
            Expanded(
                flex: 15,
                child: Container(
                  color: Colors.green,
                  child: CodeTheme(
                    data: const CodeThemeData(styles: androidstudioTheme),
                    // androidstudio, xcode, vs, monokai-sublime
                    child: CodeField(
                      key: Key("chewbacca code"),
                      controller: chewbaccaController,
                      textStyle: const TextStyle(fontFamily: 'SourceCode'),
                    ),
                  ),
                )),
            Expanded(
                flex: 16,
                child: Container(
                  color: Colors.orange,
                )),
          ],
        ));
  }
}
