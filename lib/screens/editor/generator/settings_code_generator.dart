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

      activities += """
        <activity android:name=".screens.${makeActivityName(screen)}"
            android:exported="false"
            android:screenOrientation="fullSensor"/>
      """;
    }

    var launcherScreen = appFruits.selectedProject?.layouts
        .firstWhere((screen) => screen is ScreenBundle && screen.isLauncher);
    var result = """
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <application
        android:name=".App"
        android:allowBackup="true"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:fullBackupContent="@xml/backup_rules"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.MyApplication"
        tools:targetApi="31">
        <activity
            android:name=".screens.${makeActivityName(launcherScreen as ScreenBundle)}"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />

                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        
$activities
    </application>

</manifest>
    """;

    return result;
  }
}
