import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

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
        resultXml += "\n    <element name_id=\"${element.name}\""
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
    var result = """package com.example

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
    var resultXml = """
    <?xml version="1.0" encoding="utf-8"?>
    <LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
          xmlns:app="http://schemas.android.com/apk/res-auto"
          xmlns:tools="http://schemas.android.com/tools"
          android:layout_width="match_parent"
          android:layout_height="match_parent"
          android:orientation="vertical">
""";

    for (var e in screen.elements) {
      resultXml += """\n\n<!-- ${e.description} -->\n\n""";
      switch (e.viewType) {
        case ViewType.Unknown:
          resultXml += """
          <Unknown
              android:id="${e.name}"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              android:text="${e.value}" />
    """;
          break;
        case ViewType.Label:
          resultXml += """
          <TextView
              android:id="${e.name}"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              android:text="${e.value}" />
    """;
          break;
        case ViewType.Field:
          resultXml += """
          <EditText
              android:id="${e.name}"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              android:hint="${e.value}" />
    """;
          break;
        case ViewType.Button:
          resultXml += """
          <Button
              android:id="${e.name}"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              android:text="${e.value}" />
    """;
          break;
        case ViewType.Image:
          resultXml += """
          <ImageView
              android:id="${e.name}"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              app:compatSrc="${e.value}" />
    """;
          break;
        case ViewType.Selector:
          resultXml += """
          <Switch
              android:id="${e.name}"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              android:checked="${e.value}" />
    """;
          break;
        case ViewType.Container:
          resultXml += """
         <LinearLayout 
              android:id="${e.name}"
              android:layout_width="match_parent"
              android:layout_height="wrap_content"
              android:orientation="vertical"
              >
          <!-- ${e.value} -->
          
          </LinearLayout>
    """;
          break;
        case ViewType.List:
          resultXml += """
         <RecyclerView 
              android:id="${e.name}"
              android:layout_width="match_parent"
              android:layout_height="match_parent"
              />
         <!-- ${e.value} -->
    """;
          break;
      }
    }

    resultXml += """\n</LinearLayout>""";

    var bytes = Uint8List.fromList(resultXml.codeUnits);

    String path = await FileSaver.instance.saveFile(
      bytes: bytes,
      name: "${_makeLayoutName(screen)}.xml",
    );
    debugPrint("code file path: $path");
  }

  static void _generateScreenClassFile(
      ScreenBundle screen, Directory folder) async {
    var package = "com.example";
    var addToEndCodeList = "";
    var result = """
    package $package.screens

import android.content.Intent
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import $package.R

class ${_makeStateName(screen)} {

}

class ${_makeActivityName(screen)} : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.${_makeLayoutName(screen)})

        """;

    for (var e in screen.elements) {
      var valName = "${e.name}${e.viewType.name}";
      result +=
          "\nval $valName = findViewById<${_makeViewClassName(e)}>(R.id.$valName)";
      switch (e.viewType) {
        case ViewType.Unknown:
          // do nothing
          break;
        case ViewType.Label:
          // do nothing
          break;
        case ViewType.Field:
          result += """\n$valName.doAfterTextChanged { text ->

      }""";

          break;
        case ViewType.Button:
          result += """\n$valName.setOnClickListener { 

      }""";
          break;
        case ViewType.Image:
          // do nothing
          break;
        case ViewType.Selector:
          result += """\n$valName.setOnCheckedChangeListener { v, isChecked -> 
            
        }""";
          break;
        case ViewType.Container:
        // do nothing
          break;
        case ViewType.List:
          result += """\n
          val layoutManager = LinearLayoutManager(this)
          layoutManager.orientation = RecyclerView.VERTICAL
          itemsList.layoutManager = layoutManager
          itemsList.itemAnimator = DefaultItemAnimator()
          // val dividerDrawable = ContextCompat.getDrawable(this, R.drawable.divider_drawable)
          // itemsList.addItemDecoration(DividerItemDecoration(dividerDrawable))
          var adapter = ${e.name}Adapter(
            items = appState.${_makeStateName(screen).camelCase}.${e.name}DataSource.get(), 
            onItemClickListener = {}
          )
          
          itemsList.adapter = adapter
          
          appState.${_makeStateName(screen).camelCase}.${e.name}DataSource.onChanged { newData ->
             adapter.update(newData)
          }
          
  } """;

          result += "\n\n";
          addToEndCodeList += """
              class ${e.name}Adapter(
        val items: MutableList<${e.name}Data>,
        val onItemClickListener: () -> Unit
    ) : RecyclerView.Adapter<${e.name}Adapter.${e.name}ViewHolder>() {

        inner class ${e.name}ViewHolder(view: View) : ViewHolder(view) {
            init {
                view.setOnClickListener {
                    onItemClickListener.invoke()
                }
            }
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ${e.name}ViewHolder {
            val inflater = LayoutInflater.from(parent.context)
            val holderView = inflater.inflate(R.layout.item_${e.name?.toLowerCase()}, false)
            return ${e.name}ViewHolder(holderView)
        }

        override fun getItemCount(): Int {
            return items.size
        }

        override fun onBindViewHolder(holder: ${e.name}ViewHolder, position: Int) {
            TODO("Not yet implemented")
        }
    }
          """;
          break;
      }
    }

    result += """
     
    fun onMessageEdited(text: String) {
        startActivity(Intent(this, ChatActivity::class.java))
    }

    fun onSendMessageClick(text: String) {

    }

    fun onBackClick() {
        onBackPressedDispatcher.onBackPressed()
    }
    """;

    result += "\n\n\n";
    result += addToEndCodeList;
    result += "\n}";

    var bytes = Uint8List.fromList(result.codeUnits);
    String path = await FileSaver.instance.saveFile(
      name: "${_makeActivityName(screen)}.kt",
      bytes: bytes,
    );
    debugPrint("code file path: $path");
  }

  static String _makeStateName(ScreenBundle screen) {
    return "${screen.name.removeAllWhitespace}State";
  }

  static String _makeActivityName(ScreenBundle screen) {
    return "${screen.name.removeAllWhitespace}Activity";
  }

  static String _makeLayoutName(ScreenBundle screen) {
    return "activity_${screen.name.toLowerCase().replaceAll(" ", "_")}";
  }

  static String _makeViewClassName(ScreenElement e) {
    var result = "";
    switch (e.viewType) {
      case ViewType.Unknown:
        result = "View";
        break;
      case ViewType.Label:
        result = "TextView";
        break;
      case ViewType.Field:
        result = "EditText";
        break;
      case ViewType.Button:
        result = "Button";
        break;
      case ViewType.Image:
        result = "ImageView";
        break;
      case ViewType.Selector:
        result = "Switch";
        break;
      case ViewType.Container:
        result = "LinearLayout";
        break;
      case ViewType.List:
        result = "RecyclerView";
        break;
    }
    return result;
  }
}
