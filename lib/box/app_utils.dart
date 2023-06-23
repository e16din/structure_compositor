import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';

import 'data_classes.dart';

AppDataFruits appFruits = AppDataFruits();

ScreenBundle? getScreenBundle() =>
    appFruits.selectedProject?.selectedScreenBundle;

Uint8List convertToUint8List(String layoutBytes) {
  Uint8List result = Uint8List.fromList(layoutBytes.codeUnits);
  return result;
}

class CodeGenerator {
  static void generate(Project project, Directory folder) {
    _generateProjectXml(project, folder);
    _generateAppClass(project, folder);
    for (var screen in project.screenBundles) {
      _generateScreenLayoutFile(screen, folder);
      _generateScreenClassFile(screen, folder);
    }
  }

  static void _generateProjectXml(Project project, Directory folder) async {
    var resultXml = "<project name=\"${project.name}\">";
    for (var screen in project.screenBundles) {
      resultXml += "\n  <screen name=\"${screen.name}\""
          "\n     layout_path=\"${screen.layoutPath}\" >";
      for (var element in screen.elements) {
        resultXml += "\n    <element name_id=\"${element.nameId}\""
            "\n      view_type=\"${element.viewType.name}\""
            "\n      description=\"${element.description}\""
            "\n      color=\"${element.color}\""
            "\n      functionalArea=\"${element.functionalArea.toString()}\" >";

        for (var listener in element.listeners) {
          resultXml += "\n        <listener name=\"${listener.name}\">";
          resultXml += "\n          type=\"${listener.type}\"";
          resultXml += "\n          description=\"${listener.description}\"";
          resultXml += "\n          color=\"${listener.color}\" >";

          for (var action in listener.actions) {
            resultXml += "\n          <action name=\"${action.name}\">";
            resultXml += "\n            type=\"${action.type}\"";
            resultXml += "\n            description=\"${action.description}\"";
            resultXml += "\n            color=\"${action.color}\" >";
            resultXml += "\n          </action>";
          }

          resultXml += "\n      </listener>";
        }

        resultXml += "\n    </element>";
      }
      resultXml += "\n  </screen>";
    }

    resultXml += "\n</project>";

    var structureProjectBytes = Uint8List.fromList(resultXml.codeUnits);
    String path = await FileSaver.instance.saveFile(
      // filePath: folder.path,
      name: "${project.name}.xml",
      bytes: structureProjectBytes,
    );

    debugPrint("code file path: $path");
  }

  static void _generateAppClass(Project project, Directory folder) async {
    var result = """package com.example}

import android.app.Application

object AppDataState {
   
}

class App: Application() {

    override fun onCreate() {
        super.onCreate()
    }
}
 """;
    var bytes = Uint8List.fromList(result.codeUnits);
    String path = await FileSaver.instance.saveFile(
      name: "App.kt",
      bytes: bytes,
    );
    debugPrint("code file path: $path");
  }

  static void _generateScreenLayoutFile(
      ScreenBundle screen, Directory folder) async {
    var resultXml = """<?xml version="1.0" encoding="utf-8"?>
    <LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">


    <TextView
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:text="Hello World!"
    app:layout_constraintBottom_toBottomOf="parent"
    app:layout_constraintEnd_toEndOf="parent"
    app:layout_constraintStart_toStartOf="parent"
    app:layout_constraintTop_toTopOf="parent" />

    </LinearLayout>""";

    var bytes = Uint8List.fromList(resultXml.codeUnits);

    String path = await FileSaver.instance.saveFile(
      bytes: bytes,
      name: "activity_${screen.name.toLowerCase().replaceAll(" ", "_")}.xml",
    );
    debugPrint("code file path: $path");
  }

  static void _generateScreenClassFile(
      ScreenBundle screen, Directory folder) async {
    var package = "com.example";
    var result = """
    package $package.screens

import android.content.Intent
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import $package.R

class ChatScreenState {
    lateinit var chat: ChatData
}

class ChatActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        showUserData()
        showMessages()
    }



    fun onMessageEdited(text: String) {
        startActivity(Intent(this, ChatActivity::class.java))
    }

    fun onSendMessageClick(text: String) {

    }

    fun onBackClick() {
        onBackPressedDispatcher.onBackPressed()
    }
}
    """;

    var bytes = Uint8List.fromList(result.codeUnits);
    String path = await FileSaver.instance.saveFile(
      name: "${screen.name.replaceAll(" ", "")}Activity.kt",
      bytes: bytes,
    );
    debugPrint("code file path: $path");
  }
}
