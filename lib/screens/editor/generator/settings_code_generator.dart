import 'dart:io';
import 'dart:typed_data';
import 'package:easy_debounce/easy_debounce.dart';

import '../../../box/app_utils.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:structure_compositor/screens/editor/fruits.dart';

import '../../../box/app_utils.dart';
import '../../../box/data_classes.dart';

import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/kotlin.dart';
import 'package:highlight/languages/properties.dart' as lang;

import '../../start_screen.dart';
import 'logic_code_generator.dart';

class SettingsCodeGenerator {
  // /todo: request field to enter package
  // /todo: add gradle files for build and for app

  void updateFiles(ElementNode rootNode) async {
    var package = "com.example";

    // ScreenBundle screen = getScreenBundle()!;
    Project project = appFruits.selectedProject!;
    for (var f in project.settingsFiles) {
      f.codeController.dispose();
    }
    project.settingsFiles.clear();
    debugPrint("settingsFiles.clear()");
    /////////

    var projectPropertiesFile = File("${project.path}/$PROPERTIES_PATH");
    var properties = await projectPropertiesFile.readAsString();
    var lines = properties.split("\n");

    project.propertiesMap.clear();
    for (var prop in lines) {
      var pair = prop.split("=");
      if (pair.length > 1) {
        project.propertiesMap[pair[0]] = pair[1];

        debugPrint("prop: ${prop} | value: ${pair[1]}");
      }
    }

    // var lastPropertyFile = project.settingsFiles
    //     .firstWhereOrNull((codeFile) {
    //   debugPrint("fileName: ${codeFile.fileName}");
    //       return codeFile.fileName == PROPERTIES_PATH;
    //     });
    // debugPrint("propertyPath: ${propertyPath}");
    //
    // if (lastPropertyFile != null) {
    //   lastPropertyFile.codeController.text = properties;
    //
    // } else {
    // var propertyPath = "${project.path}/$PROPERTIES_PATH";
    CodeFile propertiesFile = CodeFile(
        PROPERTIES_PATH,
        CodeController(language: lang.properties, text: properties),
        null,
        "",
        "",
        "stub");
    project.settingsFiles.add(propertiesFile);
    propertiesFile.codeController.addListener(() {
      EasyDebounce.debounce('properties', const Duration(milliseconds: 500),
          () {
        File("${appFruits.selectedProject!.path}/$PROPERTIES_PATH")
            .writeAsString(propertiesFile.codeController.text);
      });
    });
    // }

    // var package = _generateManifest();
    // CodeFile manifestFile = CodeFile("AndroidManifest.xml",
    //     CodeController(language: xml, text: manifest), null, "/src/main", package);
    // screen.settingsFiles.add(manifestFile);

    var manifest = _generateManifest();
    CodeFile manifestFile = CodeFile(
        "AndroidManifest.xml",
        CodeController(language: xml, text: manifest),
        null,
        "/src/main",
        package,
        "stub");
    project.settingsFiles.add(manifestFile);

    var app = _generateApp(package);
    CodeFile appFile = CodeFile(
        "App.kt",
        CodeController(language: kotlin, text: app),
        null,
        "/src/main/java/${package.replaceAll(".", "/")}",
        package,
        "stub");
    project.settingsFiles.add(appFile);
  }

  String _generateApp(String package) {
    var dataSources = "";
    for (var screen in appFruits.selectedProject!.screens
        .mapMany((screen) => screen.layouts)) {
      var allActions = screen.elements
          .mapMany((e) => e.receptors)
          .mapMany((r) => r.actions)
          .where((a) => a.dataSourceValue != null);
      allActions.forEach((action) {
        dataSources +=
            "\n\tval ${action.dataSourceValue?.dataSource.name.decapitalizeFirst()} = ${action.dataSourceValue?.dataSource.name}()";
      });
    }

    var result = """package $package

import android.app.Application
import $package.data.*
import $package.*

object AppDataState {
$dataSources

}

class App: Application() {

    override fun onCreate() {
        super.onCreate()
    }
}
 """;

    return result;
  }

  String _generateManifest() {
    var activities = "";

    for (var screen
        in appFruits.selectedProject!.screens.whereType<ScreenBundle>()) {
      if (screen.isLauncher) {
        continue;
      }

      activities +=
          """\n\n${tab}${tab}<activity android:name=".screens.${makeActivityName(screen.layouts.first)}"
${tab}${tab}${tab}android:exported="false"
${tab}${tab}${tab}android:screenOrientation="fullSensor"/>""";
    }

    var launcherScreen = appFruits.selectedProject?.screens
        .firstWhere((screen) => screen.isLauncher);
    var result = """
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
${tab}xmlns:tools="http://schemas.android.com/tools">

${tab}<application
${tab}${tab}android:name=".App"
${tab}${tab}android:allowBackup="true"
${tab}${tab}android:dataExtractionRules="@xml/data_extraction_rules"
${tab}${tab}android:fullBackupContent="@xml/backup_rules"
${tab}${tab}android:icon="@mipmap/ic_launcher"
${tab}${tab}android:label="@string/app_name"
${tab}${tab}android:roundIcon="@mipmap/ic_launcher_round"
${tab}${tab}android:supportsRtl="true"
${tab}${tab}android:theme="@style/Theme.MyApplication"
${tab}${tab}tools:targetApi="31">

${tab}${tab}<activity
${tab}${tab}${tab}android:name=".screens.${makeActivityName(launcherScreen!.layouts.first)}"
${tab}${tab}${tab}android:exported="true">
${tab}${tab}${tab}<intent-filter>
${tab}${tab}${tab}${tab}<action android:name="android.intent.action.MAIN" />

${tab}${tab}${tab}${tab}<category android:name="android.intent.category.LAUNCHER" />
${tab}${tab}${tab}</intent-filter>
${tab}${tab}</activity> 
$activities
${tab}</application>

</manifest>
    """;

    return result;
  }
}

extension on String {
  String decapitalizeFirst() {
    if (this.isBlank == true) return this;
    return this[0].toLowerCase() + this.substring(1).toLowerCase();
  }
}
