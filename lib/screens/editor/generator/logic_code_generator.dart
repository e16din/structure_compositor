import 'dart:io';
import 'dart:typed_data';

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:structure_compositor/screens/editor/fruits.dart';

import '../../../box/app_utils.dart';
import '../../../box/data_classes.dart';

import 'package:highlight/languages/kotlin.dart';

String tab = "      "; // 6 spaces

String makeActivityName(ScreenBundle screen) {
  var parts = screen.name.split(" ");
  var result = "";
  for (var p in parts) {
    result += p.capitalizeFirst!;
  }
  return "${result}Activity";
}

String makeLayoutName(ScreenBundle screen) {
  return "activity_${screen.name.toLowerCase().replaceAll(" ", "_")}";
}

class LogicCodeGenerator {
  void updateFiles(ElementNode rootNode) {
    ScreenBundle screen = getLayoutBundle()! as ScreenBundle;
    for (var f in screen.logicFiles) {
      f.codeController.dispose();
    }
    screen.logicFiles.clear();

    var rootFileName = "${makeActivityName(screen)}.kt";
    CodeFile rootFile = CodeFile(CodeLanguage.kotlin, rootFileName,
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

    String screenLogicText = _makeActivityClass(rootFile.elementNode!, screen);
    rootFile.codeController.text = screenLogicText;

    var nodesWithListElement = rootNode.getNodesWhere((node) =>
        node.element.selectedViewType == ViewType.list ||
        node.element.selectedViewType == ViewType.grid);
    for (var node in nodesWithListElement) {
      var adapterClassName = "${node.element.elementId.capitalizeFirst}Adapter";
      CodeFile adapterFile = CodeFile(
          CodeLanguage.kotlin,
          "$adapterClassName.kt",
          CodeController(language: kotlin, text: ""),
          node);
      screen.logicFiles.add(adapterFile);
      String adapterLogicText =
          _makeAdapterClass(adapterFile.elementNode!, screen, adapterClassName);
      adapterFile.codeController.text = adapterLogicText;
    }
  }

  String _makeAdapterClass(
      ElementNode node, ScreenBundle screen, String adapterClassName) {
    var package = _getPackage();
    var e = node.element;
    var itemLayoutName = "item_${e.elementId.toLowerCase()}";
    var result = "";
    result += """
package $package.screens

import android.view.LayoutInflater
import android.view.View
import androidx.recyclerview.widget.RecyclerView
import androidx.recyclerview.widget.RecyclerView.ViewHolder
import $package.data.*
import $package.*

import $package.R


class ${adapterClassName}(
${tab}var items: List<${e.elementId.capitalizeFirst}DataSource.Data>,
${tab}var onItemClickListener: (position: Int, viewType: Int) -> Unit
) : RecyclerView.Adapter<${adapterClassName}.${e.elementId.capitalizeFirst}ViewHolder>() {

${tab}enum class ViewType {
${tab}${tab}Default,
${tab}}

${tab}inner class ${e.elementId.capitalizeFirst}ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
${tab}${tab}init {
${tab}${tab}${tab}view.setOnClickListener {
${tab}${tab}${tab}${tab}val position = adapterPosition
${tab}${tab}${tab}${tab}onItemClickListener.invoke(position, getItemViewType(position))
${tab}${tab}${tab}}
${tab}${tab}}
${tab}}

${tab}override fun getItemViewType(position: Int): Int {
${tab}${tab}return when (items[position]) {
${tab}${tab}${tab}else -> ViewType.Default.ordinal
${tab}${tab}}
${tab}}

${tab}override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ${e.elementId.capitalizeFirst}ViewHolder {
${tab}${tab}val inflater = LayoutInflater.from(parent.context)
${tab}${tab}val holderView = inflater.inflate(R.layout.$itemLayoutName, parent, false)
${tab}${tab}return ${e.elementId.capitalizeFirst}ViewHolder(holderView)
${tab}}

${tab}override fun getItemCount(): Int {
${tab}${tab}return items.size
${tab}}

${tab}override fun onBindViewHolder(holder: ${e.elementId.capitalizeFirst}ViewHolder, position: Int) {
${tab}${tab}TODO("Not yet implemented")
${tab}}

${tab}fun update(items: List<${e.elementId.capitalizeFirst}DataSource.Data>) {
${tab}${tab}this.items = items
${tab}${tab}notifyDataSetChanged()
${tab}}
}
""";
    return result;
  }

  String _makeActivityClass(ElementNode rootNode, ScreenBundle screen) {
    var package = _getPackage();
    var addToEndCodeList = "";

    var activityName = makeActivityName(screen);
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
${tab}override fun onCreate(savedInstanceState: Bundle?) {
${tab}${tab}super.onCreate(savedInstanceState)
${tab}${tab}setContentView(R.layout.${makeLayoutName(screen)})""";

    for (var e in screen.elements) {
      var valName = _makeViewId(e);
      result +=
          "\n${tab}${tab}val $valName = findViewById<${_makeViewClassName(e)}>(R.id.$valName)";

      for (var action in e.actions) {
        result += _generateActionCode(e, action);
      }

      switch (e.selectedViewType) {
        case ViewType.text:
          // do nothing
          break;
        case ViewType.field:
          result += """\n${tab}${tab}$valName.doAfterTextChanged { text ->
${tab}${tab}${tab}TODO("Not yet implemented")
${tab}${tab}}""";

          break;
        case ViewType.button:
          break;
        case ViewType.image:
          // do nothing
          break;
        case ViewType.switcher:
          result +=
              """\n${tab}${tab}$valName.setOnCheckedChangeListener { v, isChecked -> 
${tab}${tab}${tab}TODO("Not yet implemented")
${tab}${tab}}""";
          break;
        case ViewType.list:
        case ViewType.grid:
          var actionCode = _getActionCode(e);

          var layoutManager = "LinearLayoutManager(this)";
          if (e.selectedViewType == ViewType.grid) {
            layoutManager = "GridLayoutManager(this, 2)";
          }

          result += """\n
${tab}${tab}val layoutManager = ${layoutManager}
${tab}${tab}layoutManager.orientation = RecyclerView.VERTICAL
${tab}${tab}$valName.layoutManager = layoutManager
${tab}${tab}$valName.itemAnimator = DefaultItemAnimator()
${tab}${tab}// val dividerDrawable = ContextCompat.getDrawable(this, R.drawable.divider_drawable)
${tab}${tab}// $valName.addItemDecoration(DividerItemDecoration(dividerDrawable))
${tab}${tab}val adapter = ${e.elementId.capitalizeFirst}Adapter(
${tab}${tab}${tab}items = AppDataState.${e.elementId}DataSource.get(), 
${tab}${tab}${tab}onItemClickListener = { position, viewType ->""";
          result += "\n$actionCode\n";
          result += """${tab}${tab}${tab}}
${tab}${tab})
          
${tab}${tab}$valName.adapter = adapter
          
${tab}${tab}AppDataState.${e.elementId}DataSource.onDataChanged = { newData ->
${tab}${tab}${tab}adapter.update(newData)
${tab}${tab}}
""";
          break;
        case ViewType.otherView:
          break;
      }
    }

    result += "\n${tab}}";

    result += "\n";
    result += addToEndCodeList;
    result += "\n}";

    return result;
  }

  _getPackage() {
    return platformFilesEditorFruit.package;
  }

  String _makeViewId(CodeElement e) {
    return "${e.elementId}${e.selectedViewType.name.capitalizeFirst}";
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
    // var onButtonClick = """${tab}${tab}${tab}TODO("Not yet implemented")""";
    //
    // var openNextScreenBlock = e.listeners.firstWhereOrNull((listener) =>
    //     listener.actions.any((action) =>
    //     action.actionType == ActionCodeTypeMain.openNextScreen));
    // if (openNextScreenBlock != null) {
    //   var action = openNextScreenBlock.actions
    //       .firstWhereOrNull((action) => action is OpenNextScreenBlock)
    //   as OpenNextScreenBlock?;
    //   onButtonClick = """
    // ${tab}${tab}${tab}startActivity(
    // ${tab}${tab}${tab}${tab}Intent(this, ${_makeActivityName(action!.nextScreenBundle!)}::class.java)
    // ${tab}${tab}${tab})""";
    // } // else {
    //
    // var backToPrevBlock = e.listeners.firstWhereOrNull((listener) =>
    //     listener.actions.any((action) =>
    //     action.actionType == ActionCodeTypeMain.backToPrevious));
    // if (backToPrevBlock != null) {
    //   onButtonClick = "${tab}${tab}${tab}onBackPressedDispatcher.onBackPressed()";
    // }
    // return onButtonClick;
    return "// todo: replace stub;";
  }

  String _generateActionCode(CodeElement element, CodeAction action) {
    String result = "";

    var valName = _makeViewId(element);

    if (action.description.isNotEmpty) {
      result += "\n${tab}${tab}/**"
          "\n * ${tab}${tab}Description: ${action.description}"
          "\n${tab}${tab}*/";
    }

    switch (action.type) {
      case CodeActionType.doOnClick:
        var actionCode = _getActionCode(element);
        result += """\n${tab}${tab}$valName.setOnClickListener { 
$actionCode
${tab}${tab}}""";
        //todo:
        break;
      default:
        // do nothing
        break;
    }

    return result;
  }
}
