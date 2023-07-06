import 'dart:io';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'dart:typed_data';
import 'data_classes.dart';

class CodeGenerator {
  static const _package = "com.example";

  static void generate(Project project, Directory folder) {
    // Structure Compositor project
    _generateProjectXml(project, folder);

    // Android project
    _generateManifestXml(project, folder);
    _generateAppClass(project, folder);
    for (var screen in project.layouts.whereType<ScreenBundle>()) {
      _generateScreenLayoutFile(screen, folder);
      _generateScreenClassFile(screen, folder);
    }
  }

  static void _generateProjectXml(Project project, Directory folder) async {
    var resultXml = "<project name=\"${project.name}\">";
    for (var screen in project.layouts) {
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
          resultXml += "\n          type=\"${listener.listenerType}\"";
          resultXml += "\n          description=\"${listener.description}\"";
          resultXml += "\n          color=\"${listener.color}\" >";

          for (var action in listener.actions) {
            resultXml += "\n          <action name=\"${action.name}\">";
            resultXml += "\n            type=\"${action.actionType}\"";
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
    var dataSources = """
    """;
    for (var screen in project.layouts) {
      for (var element in screen.elements) {
        if (element.hasDataSource()) {
          _generateDataSourceClass(element.name.capitalizeFirst!);

          dataSources +=
              "\n\tval ${element.name}DataSource = ${element.name.capitalizeFirst}DataSource()";
        }
      }
    }
    var result = """package $_package

import android.app.Application
import $_package.data.*
import $_package.*

object AppDataState {
$dataSources
    
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
\txmlns:app="http://schemas.android.com/apk/res-auto"
\txmlns:tools="http://schemas.android.com/tools"
\tandroid:layout_width="match_parent"
\tandroid:layout_height="match_parent"
\tandroid:orientation="vertical">
""";

    for (var e in screen.elements) {
      resultXml += """\n\n\t<!-- Description: ${e.description} -->\n\n""";
      var viewId = "@+id/${_makeViewId(e)}";
      switch (e.viewType) {
        case ViewType.unknown:
          resultXml += """
          <Unknown
              android:id="$viewId"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              android:text="${e.value}" />
    """;
          break;
        case ViewType.label:
          resultXml += """
          <TextView
              android:id="$viewId"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              android:text="${e.value}" />
    """;
          break;
        case ViewType.field:
          resultXml += """
          <EditText
              android:id="$viewId"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              android:hint="${e.value}" />
    """;
          break;
        case ViewType.button:
          resultXml += """
          <Button
              android:id="$viewId"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              android:text="${e.value}" />
    """;
          break;
        case ViewType.image:
          resultXml += """
          <ImageView
              android:id="$viewId"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              app:compatSrc="${e.value}" />
    """;
          break;
        case ViewType.selector:
          resultXml += """
          <Switch
              android:id="$viewId"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              android:checked="${e.value}" />
    """;
          break;
        case ViewType.column:
          resultXml += """
         <LinearLayout 
              android:id="$viewId"
              android:layout_width="match_parent"
              android:layout_height="wrap_content"
              android:orientation="vertical"
              >
          <!-- Value: ${e.value} -->
          
         </LinearLayout>
    """;
          break;
        case ViewType.row:
          resultXml += """
         <LinearLayout 
              android:id="$viewId"
              android:layout_width="match_parent"
              android:layout_height="wrap_content"
              android:orientation="horizontal"
              >
          <!-- Value: ${e.value} -->
          
         </LinearLayout>
    """;
          break;
        case ViewType.stack:
          resultXml += """
         <FrameLayout 
              android:id="$viewId"
              android:layout_width="match_parent"
              android:layout_height="wrap_content"
              >
          <!-- Value: ${e.value} -->
          
         </FrameLayout>
    """;
          break;
        case ViewType.list:
          resultXml += """
         <androidx.recyclerview.widget.RecyclerView 
              android:id="$viewId"
              android:layout_width="match_parent"
              android:layout_height="match_parent"
              />
         <!-- Value: ${e.value} -->
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
    var addToEndCodeList = "";

    var activityName = _makeActivityName(screen);
    var result = """
package $_package.screens

import android.content.Intent
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ImageView
import android.widget.TextView
import androidx.core.widget.doAfterTextChanged
import androidx.recyclerview.widget.DefaultItemAnimator
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import $_package.data.*
import $_package.*

import $_package.R


class ${activityName} : AppCompatActivity() {
\toverride fun onCreate(savedInstanceState: Bundle?) {
\t\tsuper.onCreate(savedInstanceState)
\t\tsetContentView(R.layout.${_makeLayoutName(screen)})""";

    for (var e in screen.elements) {
      if (e.description.isNotEmpty) {
        result += "\n\t\t/**"
            "\n\t\tDescription: ${e.description}"
            "\n\t\t*/";
      }

      var valName = _makeViewId(e);
      result +=
          "\n\t\tval $valName = findViewById<${_makeViewClassName(e)}>(R.id.$valName)";
      switch (e.viewType) {
        case ViewType.unknown:
          // do nothing
          break;
        case ViewType.label:
          // do nothing
          break;
        case ViewType.field:
          result += """\n\t\t$valName.doAfterTextChanged { text ->
\t\t\tTODO("Not yet implemented")
\t\t}""";

          break;
        case ViewType.button:
          var actionCode = _getActionCode(e);
          result += """\n\t\t$valName.setOnClickListener { 
$actionCode
\t\t}""";
          break;
        case ViewType.image:
          // do nothing
          break;
        case ViewType.selector:
          result +=
              """\n\t\t$valName.setOnCheckedChangeListener { v, isChecked -> 
\t\t\tTODO("Not yet implemented")
\t\t}""";
          break;
        case ViewType.column:
          // do nothing
          break;
        case ViewType.row:
          // do nothing
          break;
        case ViewType.stack:
          // do nothing
          break;
        case ViewType.list:
          var itemLayoutName = "item_${e.name.toLowerCase()}";
          await _generateListItemXml(itemLayoutName);

          var actionCode = _getActionCode(e);

          result += """\n
\t\tval layoutManager = LinearLayoutManager(this)
\t\tlayoutManager.orientation = RecyclerView.VERTICAL
\t\t$valName.layoutManager = layoutManager
\t\t$valName.itemAnimator = DefaultItemAnimator()
\t\t// val dividerDrawable = ContextCompat.getDrawable(this, R.drawable.divider_drawable)
\t\t// $valName.addItemDecoration(DividerItemDecoration(dividerDrawable))
\t\tval adapter = ${e.name.capitalizeFirst}Adapter(
\t\t\titems = AppDataState.${e.name}DataSource.get(), 
\t\t\tonItemClickListener = { position, viewType ->""";
          result += "\n$actionCode\n";
          result += """\t\t\t}
\t\t)
          
\t\t$valName.adapter = adapter
          
\t\tAppDataState.${e.name}DataSource.onDataChanged = { newData ->
\t\t\tadapter.update(newData)
\t\t}
""";

          result += "\n\n";
          addToEndCodeList += """
\tclass ${e.name.capitalizeFirst}Adapter(
\t\tvar items: List<${e.name.capitalizeFirst}DataSource.Data>,
\t\tvar onItemClickListener: (position: Int, viewType: Int) -> Unit
\t) : RecyclerView.Adapter<${e.name.capitalizeFirst}Adapter.${e.name.capitalizeFirst}ViewHolder>() {

\t\tenum class ViewType {
\t\t\tDefault,
\t\t}

\t\tinner class ${e.name.capitalizeFirst}ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
\t\t\tinit {
\t\t\t\tview.setOnClickListener {
\t\t\t\t\tval position = adapterPosition
\t\t\t\t\tonItemClickListener.invoke(position, getItemViewType(position))
\t\t\t\t}
\t\t\t}
\t\t}

\t\toverride fun getItemViewType(position: Int): Int {
\t\t\treturn when (items[position]) {
\t\t\t\telse -> ViewType.Default.ordinal
\t\t\t}
\t\t}

\t\toverride fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ${e.name.capitalizeFirst}ViewHolder {
\t\t\tval inflater = LayoutInflater.from(parent.context)
\t\t\tval holderView = inflater.inflate(R.layout.$itemLayoutName, parent, false)
\t\t\treturn ${e.name.capitalizeFirst}ViewHolder(holderView)
\t\t}

\t\toverride fun getItemCount(): Int {
\t\t\treturn items.size
\t\t}

\t\toverride fun onBindViewHolder(holder: ${e.name.capitalizeFirst}ViewHolder, position: Int) {
\t\t\tTODO("Not yet implemented")
\t\t}

\t\tfun update(items: List<${e.name.capitalizeFirst}DataSource.Data>) {
\t\t\tthis.items = items
\t\t\tnotifyDataSetChanged()
\t\t}
\t}
""";
          break;
      }
    }

    result += "\n\t}";

    result += "\n";
    result += addToEndCodeList;
    result += "\n}";

    var bytes = Uint8List.fromList(result.codeUnits);
    String path = await FileSaver.instance.saveFile(
      name: "$activityName.kt",
      bytes: bytes,
    );
    debugPrint("code file path: $path");
  }

  static String _getActionCode(LayoutElement e) {
    var onButtonClick = """\t\t\tTODO("Not yet implemented")""";

    var openNextScreenBlock = e.listeners.firstWhereOrNull((listener) =>
        listener.actions.any(
            (action) => action.actionType == ActionCodeType.openNextScreen));
    if (openNextScreenBlock != null) {
      var action = openNextScreenBlock.actions
              .firstWhereOrNull((action) => action is OpenNextScreenBlock)
          as OpenNextScreenBlock?;
      onButtonClick = """
    \t\t\tstartActivity(
    \t\t\t\tIntent(this, ${_makeActivityName(action!.nextScreenBundle!)}::class.java)
    \t\t\t)""";
    } // else {

    var backToPrevBlock = e.listeners.firstWhereOrNull((listener) => listener
        .actions
        .any((action) => action.actionType == ActionCodeType.backToPrevious));
    if (backToPrevBlock != null) {
      onButtonClick = "\t\t\tonBackPressedDispatcher.onBackPressed()";
    }
    return onButtonClick;
  }

  static Future<void> _generateListItemXml(String itemLayoutName) async {
    var itemLayoutContent = """
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
\txmlns:app="http://schemas.android.com/apk/res-auto"
\txmlns:tools="http://schemas.android.com/tools"
\tandroid:layout_width="match_parent"
\tandroid:layout_height="match_parent"
\tandroid:orientation="vertical">

</LinearLayout>
""";

    String path = await FileSaver.instance.saveFile(
      name: "$itemLayoutName.xml",
      bytes: Uint8List.fromList(itemLayoutContent.codeUnits),
    );
  }

  static Future<void> _generateDataSourceClass(String name) async {
    var itemLayoutContent = """
package $_package.data

class ${name}DataSource {
    
   class Data()

   val data = emptyList<Data>()
   
   var onDataChanged: (data: List<Data>) -> Unit = {}

   fun get(): List<Data> {
      TODO("Not yet implemented")
   }
}
""";

    String path = await FileSaver.instance.saveFile(
      name: "${name}DataSource.kt",
      bytes: Uint8List.fromList(itemLayoutContent.codeUnits),
    );
  }

  static String _makeViewId(LayoutElement e) {
    return "${e.name}${e.viewType.name}";
  }

  static String _makeActivityName(ScreenBundle screen) {
    var parts = screen.name.split(" ");
    var result = "";
    for (var p in parts) {
      result += p.capitalizeFirst!;
    }
    return "${result}Activity";
  }

  static String _makeLayoutName(ScreenBundle screen) {
    return "activity_${screen.name.toLowerCase().replaceAll(" ", "_")}";
  }

  static String _makeViewClassName(LayoutElement e) {
    var result = "";
    switch (e.viewType) {
      case ViewType.unknown:
        result = "View";
        break;
      case ViewType.label:
        result = "TextView";
        break;
      case ViewType.field:
        result = "EditText";
        break;
      case ViewType.button:
        result = "Button";
        break;
      case ViewType.image:
        result = "ImageView";
        break;
      case ViewType.selector:
        result = "Switch";
        break;
      case ViewType.column:
        result = "LinearLayout";
        break;
      case ViewType.row:
        result = "LinearLayout";
        break;
      case ViewType.stack:
        result = "FrameLayout";
        break;
      case ViewType.list:
        result = "RecyclerView";
        break;
    }
    return result;
  }

  static Future<void> _generateManifestXml(
      Project project, Directory folder) async {
    var activities = "";

    for (var screen in project.layouts.whereType<ScreenBundle>()) {
      if (screen.isLauncher) {
        continue;
      }

      activities += """
        <activity android:name=".screens.${_makeActivityName(screen)}"
            android:exported="false"
            android:screenOrientation="fullSensor"/>
      """;
    }

    var launcherScreen = project.layouts
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
            android:name=".screens.${_makeActivityName(launcherScreen as ScreenBundle)}"
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

    var bytes = Uint8List.fromList(result.codeUnits);
    String path = await FileSaver.instance.saveFile(
      name: "AndroidManifest.xml",
      bytes: bytes,
    );
  }
}
