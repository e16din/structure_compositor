import 'dart:io';
import 'dart:typed_data';

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:structure_compositor/screens/editor/fruits.dart';

import '../../../box/app_utils.dart';
import '../../../box/data_classes.dart';

import 'package:highlight/languages/xml.dart';

import 'logic_code_generator.dart';

class SettingsCodeGenerator {

  void updateFiles(ElementNode rootNode) {
    ScreenBundle screen = getLayoutBundle()! as ScreenBundle;
    for(var f in screen.settingsFiles){
      f.codeController.dispose();
    }
    screen.settingsFiles.clear();

    var manifest = _generateManifest();
    CodeFile manifestFile = CodeFile(
        CodeLanguage.xml,
        "AndroidManifest.xml",
        CodeController(language: xml, text: manifest),
        null);

    screen.settingsFiles.add(manifestFile);
  }

  String _generateManifest() {
    var activities = "";

    for (var screen in appFruits.selectedProject!.layouts.whereType<ScreenBundle>()) {
      if (screen.isLauncher) {
        continue;
      }

      activities +=
      """\n\n${tab}${tab}<activity android:name=".screens.${makeActivityName(screen)}"
${tab}${tab}${tab}android:exported="false"
${tab}${tab}${tab}android:screenOrientation="fullSensor"/>""";
    }

    var launcherScreen = appFruits.selectedProject?.layouts
        .firstWhere((screen) => screen is ScreenBundle && screen.isLauncher);
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
${tab}${tab}${tab}android:name=".screens.${makeActivityName(launcherScreen as ScreenBundle)}"
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
