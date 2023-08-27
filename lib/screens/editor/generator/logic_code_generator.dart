import 'dart:io';
import 'dart:typed_data';

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:structure_compositor/screens/editor/fruits.dart';

import '../../../box/app_utils.dart';
import '../../../box/data_classes.dart';

import 'package:highlight/languages/kotlin.dart';

class LogicCodeGenerator {
  String _makeActivityName(ScreenBundle screen) {
    var parts = screen.name.split(" ");
    var result = "";
    for (var p in parts) {
      result += p.capitalizeFirst!;
    }
    return "${result}Activity";
  }

  void updateLogicFiles(ElementNode rootNode) {
    ScreenBundle screen = getLayoutBundle()! as ScreenBundle;
    for(var f in screen.logicFiles){
      f.codeController.dispose();
    }
    screen.logicFiles.clear();

    CodeFile rootFile = CodeFile(CodeLanguage.kotlin, _makeActivityName(screen),
        CodeController(language: kotlin, text: ""), rootNode);
    screen.logicFiles.add(rootFile);
    // var itemNodes = rootNode.getNodesWhere((node) =>
    // node.containerNode?.element.selectedViewType == ViewType.list);
    // for (var node in itemNodes) {
    //   node.containerNode?.contentNodes.remove(node);
    //   CodeFile itemFile = CodeFile(
    //       CodeLanguage.xml,
    //       "item_${node.element.elementId}.kt",
    //       CodeController(language: kotlin, text: ""),
    //       node);
    //   screen.layoutFiles.add(itemFile);
    // }

    for (var file in screen.logicFiles) {
      String screenLogicText = _makeActivityClass(file.elementNode, screen);
      file.codeController.text = screenLogicText;
    }
  }

  String _tab = "      "; // 6 spaces

  String _makeActivityClass(ElementNode rootNode, ScreenBundle screen) {
    var package = _getPackage();
    var addToEndCodeList = "";

    var activityName = _makeActivityName(screen);
    var result = """
package $package.screens

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
import $package.data.*
import $package.*

import $package.R


class ${activityName} : AppCompatActivity() {
${_tab}override fun onCreate(savedInstanceState: Bundle?) {
${_tab}${_tab}super.onCreate(savedInstanceState)
${_tab}${_tab}setContentView(R.layout.${_makeLayoutName(screen)})""";

    for (var e in screen.elements) {
      var valName = _makeViewId(e);
      result +=
          "\n${_tab}${_tab}val $valName = findViewById<${_makeViewClassName(e)}>(R.id.$valName)";
      switch (e.selectedViewType) {
        case ViewType.text:
          // do nothing
          break;
        case ViewType.field:
          result += """\n${_tab}${_tab}$valName.doAfterTextChanged { text ->
${_tab}${_tab}${_tab}TODO("Not yet implemented")
${_tab}${_tab}}""";

          break;
        case ViewType.button:
          for (var action in e.actions) {
            result += _generateActionCode(e, action);
          }
          break;
        case ViewType.image:
          // do nothing
          break;
        case ViewType.switcher:
          result +=
              """\n${_tab}${_tab}$valName.setOnCheckedChangeListener { v, isChecked -> 
${_tab}${_tab}${_tab}TODO("Not yet implemented")
${_tab}${_tab}}""";
          break;
        case ViewType.list:
        case ViewType.grid:
          var itemLayoutName = "item_${e.elementId.toLowerCase()}";

          var actionCode = _getActionCode(e);

          var layoutManager = "LinearLayoutManager(this)";
          if(e.selectedViewType == ViewType.grid){
            layoutManager = "GridLayoutManager(this, 2)";
          }

          result += """\n
${_tab}${_tab}val layoutManager = ${layoutManager}
${_tab}${_tab}layoutManager.orientation = RecyclerView.VERTICAL
${_tab}${_tab}$valName.layoutManager = layoutManager
${_tab}${_tab}$valName.itemAnimator = DefaultItemAnimator()
${_tab}${_tab}// val dividerDrawable = ContextCompat.getDrawable(this, R.drawable.divider_drawable)
${_tab}${_tab}// $valName.addItemDecoration(DividerItemDecoration(dividerDrawable))
${_tab}${_tab}val adapter = ${e.elementId.capitalizeFirst}Adapter(
${_tab}${_tab}${_tab}items = AppDataState.${e.elementId}DataSource.get(), 
${_tab}${_tab}${_tab}onItemClickListener = { position, viewType ->""";
          result += "\n$actionCode\n";
          result += """${_tab}${_tab}${_tab}}
${_tab}${_tab})
          
${_tab}${_tab}$valName.adapter = adapter
          
${_tab}${_tab}AppDataState.${e.elementId}DataSource.onDataChanged = { newData ->
${_tab}${_tab}${_tab}adapter.update(newData)
${_tab}${_tab}}
""";

          result += "\n\n";
          addToEndCodeList += """
${_tab}class ${e.elementId.capitalizeFirst}Adapter(
${_tab}${_tab}var items: List<${e.elementId.capitalizeFirst}DataSource.Data>,
${_tab}${_tab}var onItemClickListener: (position: Int, viewType: Int) -> Unit
${_tab}) : RecyclerView.Adapter<${e.elementId.capitalizeFirst}Adapter.${e.elementId.capitalizeFirst}ViewHolder>() {

${_tab}${_tab}enum class ViewType {
${_tab}${_tab}${_tab}Default,
${_tab}${_tab}}

${_tab}${_tab}inner class ${e.elementId.capitalizeFirst}ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
${_tab}${_tab}${_tab}init {
${_tab}${_tab}${_tab}${_tab}view.setOnClickListener {
${_tab}${_tab}${_tab}${_tab}${_tab}val position = adapterPosition
${_tab}${_tab}${_tab}${_tab}${_tab}onItemClickListener.invoke(position, getItemViewType(position))
${_tab}${_tab}${_tab}${_tab}}
${_tab}${_tab}${_tab}}
${_tab}${_tab}}

${_tab}${_tab}override fun getItemViewType(position: Int): Int {
${_tab}${_tab}${_tab}return when (items[position]) {
${_tab}${_tab}${_tab}${_tab}else -> ViewType.Default.ordinal
${_tab}${_tab}${_tab}}
${_tab}${_tab}}

${_tab}${_tab}override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ${e.elementId.capitalizeFirst}ViewHolder {
${_tab}${_tab}${_tab}val inflater = LayoutInflater.from(parent.context)
${_tab}${_tab}${_tab}val holderView = inflater.inflate(R.layout.$itemLayoutName, parent, false)
${_tab}${_tab}${_tab}return ${e.elementId.capitalizeFirst}ViewHolder(holderView)
${_tab}${_tab}}

${_tab}${_tab}override fun getItemCount(): Int {
${_tab}${_tab}${_tab}return items.size
${_tab}${_tab}}

${_tab}${_tab}override fun onBindViewHolder(holder: ${e.elementId.capitalizeFirst}ViewHolder, position: Int) {
${_tab}${_tab}${_tab}TODO("Not yet implemented")
${_tab}${_tab}}

${_tab}${_tab}fun update(items: List<${e.elementId.capitalizeFirst}DataSource.Data>) {
${_tab}${_tab}${_tab}this.items = items
${_tab}${_tab}${_tab}notifyDataSetChanged()
${_tab}${_tab}}
${_tab}}
""";
          break;
        case ViewType.otherView:
          break;
      }
    }

    result += "\n${_tab}}";

    result += "\n";
    result += addToEndCodeList;
    result += "\n}";

    return result;
  }

  _getPackage() {
    return platformFilesEditorFruit.package;
  }

  String _makeLayoutName(ScreenBundle screen) {
    return "activity_${screen.name.toLowerCase().replaceAll(" ", "_")}";
  }

  String _makeViewId(CodeElement e) {
    return "${e.elementId}${e.selectedViewType.name}";
  }

  String _makeViewClassName(CodeElement e) {
    var result = switch (e.selectedViewType) {
      ViewType.text => "TextView",
      ViewType.field => "EditText",
      ViewType.button => "Button",
      ViewType.image => "ImageView",
      ViewType.switcher => "Switch",
      // case ViewType.combine:
      //   result = "LinearLayout";
      //   break;
      ViewType.list => "RecyclerView",
      ViewType.grid => "RecyclerView",
      ViewType.otherView => "View",
    };
    return result;
  }

  String _getActionCode(CodeElement e) {
    // var onButtonClick = """${_tab}${_tab}${_tab}TODO("Not yet implemented")""";
    //
    // var openNextScreenBlock = e.listeners.firstWhereOrNull((listener) =>
    //     listener.actions.any((action) =>
    //     action.actionType == ActionCodeTypeMain.openNextScreen));
    // if (openNextScreenBlock != null) {
    //   var action = openNextScreenBlock.actions
    //       .firstWhereOrNull((action) => action is OpenNextScreenBlock)
    //   as OpenNextScreenBlock?;
    //   onButtonClick = """
    // ${_tab}${_tab}${_tab}startActivity(
    // ${_tab}${_tab}${_tab}${_tab}Intent(this, ${_makeActivityName(action!.nextScreenBundle!)}::class.java)
    // ${_tab}${_tab}${_tab})""";
    // } // else {
    //
    // var backToPrevBlock = e.listeners.firstWhereOrNull((listener) =>
    //     listener.actions.any((action) =>
    //     action.actionType == ActionCodeTypeMain.backToPrevious));
    // if (backToPrevBlock != null) {
    //   onButtonClick = "${_tab}${_tab}${_tab}onBackPressedDispatcher.onBackPressed()";
    // }
    // return onButtonClick;
    return "// todo: replace stub;";
  }

  String _generateActionCode(CodeElement element, action) {
    String result = "";

    var valName = _makeViewId(element);

    if (action.description.isNotEmpty) {
      result += "\n${_tab}${_tab}/**"
          "\n${_tab}${_tab}Description: ${action.description}"
          "\n${_tab}${_tab}*/";
    }

    switch (action.type) {
      case CodeActionType.doOnClick:
        var actionCode = _getActionCode(element);
        result += """\n${_tab}${_tab}$valName.setOnClickListener { 
$actionCode
${_tab}${_tab}}""";
        //todo:
        break;
    }

    return result;
  }
}
