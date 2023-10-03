import 'dart:io';
import 'dart:typed_data';

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:structure_compositor/screens/editor/fruits.dart';

import '../../../box/app_utils.dart';
import '../../../box/data_classes.dart';

import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/kotlin.dart';

import 'logic_code_generator.dart';

class DataCodeGenerator {

  void updateFiles(ElementNode rootNode, LayoutBundle layout) {
//     ScreenBundle screen = getLayoutBundle()! as ScreenBundle;
//     for(var f in screen.settingsFiles){
//       f.codeController.dispose();
//     }
//     screen.settingsFiles.clear();
//
//     var manifest = _generateManifest();
//     CodeFile manifestFile = CodeFile(
//         CodeLanguage.xml,
//         "AndroidManifest.xml",
//         CodeController(language: xml, text: manifest),
//         null);
//     screen.settingsFiles.add(manifestFile);
//
//     var app = _generateApp();
//     CodeFile appFile = CodeFile(
//         CodeLanguage.kotlin,
//         "App.kt",
//         CodeController(language: kotlin, text: app),
//         null);
//     screen.settingsFiles.add(appFile);
//   }
//
//   static Future<void> _generateDataSourceClass(String name) async {
//     var itemLayoutContent = """
// package $_package.data
//
// class ${name}DataSource {
//
//    class Data()
//
//    val data = emptyList<Data>()
//
//    var onDataChanged: (data: List<Data>) -> Unit = {}
//
//    fun get(): List<Data> {
//       TODO("Not yet implemented")
//    }
// }
// """;
//
//     String path = await FileSaver.instance.saveFile(
//       name: "${name}DataSource.kt",
//       bytes: Uint8List.fromList(itemLayoutContent.codeUnits),
//     );
  }
}
