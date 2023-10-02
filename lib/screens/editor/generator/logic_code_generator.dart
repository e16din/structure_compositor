import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../box/app_utils.dart';
import '../../../box/data_classes.dart';

import 'package:highlight/languages/kotlin.dart';

String tab = "      "; // 6 spaces

String makeActivityName(LayoutBundle layout) {
  var parts = layout.name.split(" ");
  var result = "";
  for (var p in parts) {
    result += p.capitalizeFirst!;
  }
  return "${result}Activity";
}

String makeLayoutName(LayoutBundle layout) {
  return "activity_${layout.name.toLowerCase().replaceAll(" ", "_")}";
}

class LogicCodeGenerator {
  void updateFiles(ElementNode rootNode) {
    var package = "com.example";
    LayoutBundle layout = getLayoutBundle()!;
    for (var f in layout.logicFiles) {
      f.codeController.dispose();
    }
    layout.logicFiles.clear();

    var rootFileName = "${makeActivityName(layout)}.kt";
    CodeFile rootFile = CodeFile(rootFileName,
        CodeController(language: kotlin, text: ""), rootNode, "/src/main/java/${package.replaceAll(".", "/")}/screens", package,"stub");
    layout.logicFiles.add(rootFile);
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

    String screenLogicText = _makeActivityClass(rootFile.elementNode!, layout, rootFile);
    rootFile.codeController.text = screenLogicText;

    var nodesWithListElement = rootNode.getNodesWhere((node) =>
        node.element.selectedViewType == ViewType.list ||
        node.element.selectedViewType == ViewType.grid);
    for (var node in nodesWithListElement) {
      var adapterClassName = "${node.element.id.capitalizeFirst}Adapter";
      CodeFile adapterFile = CodeFile(
          "$adapterClassName.kt",
          CodeController(language: kotlin, text: ""),
          node, "/src/main/java/${package.replaceAll(".", "/")}/screens", package, "stub");
      layout.logicFiles.add(adapterFile);
      String adapterLogicText =
          _makeAdapterClass(adapterFile.elementNode!, layout, adapterClassName, adapterFile);
      adapterFile.codeController.text = adapterLogicText;
    }
  }

  String _makeAdapterClass(
      ElementNode node, LayoutBundle layout, String adapterClassName, CodeFile file) {
    var package = file.package;
    var e = node.element;
    var itemLayoutName = "item_${e.id.toLowerCase()}";
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
${tab}var items: List<${e.id.capitalizeFirst}DataSource.Data>,
${tab}var onItemClickListener: (position: Int, viewType: Int) -> Unit
) : RecyclerView.Adapter<${adapterClassName}.${e.id.capitalizeFirst}ViewHolder>() {

${tab}enum class ViewType {
${tab}${tab}Default,
${tab}}

${tab}inner class ${e.id.capitalizeFirst}ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
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

${tab}override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ${e.id.capitalizeFirst}ViewHolder {
${tab}${tab}val inflater = LayoutInflater.from(parent.context)
${tab}${tab}val holderView = inflater.inflate(R.layout.$itemLayoutName, parent, false)
${tab}${tab}return ${e.id.capitalizeFirst}ViewHolder(holderView)
${tab}}

${tab}override fun getItemCount(): Int {
${tab}${tab}return items.size
${tab}}

${tab}override fun onBindViewHolder(holder: ${e.id.capitalizeFirst}ViewHolder, position: Int) {
${tab}${tab}TODO("Not yet implemented")
${tab}}

${tab}fun update(items: List<${e.id.capitalizeFirst}DataSource.Data>) {
${tab}${tab}this.items = items
${tab}${tab}notifyDataSetChanged()
${tab}}
}
""";
    return result;
  }

  String _makeActivityClass(ElementNode rootNode, LayoutBundle layout, CodeFile file) {
    var package = file.package;
    var addToEndCodeList = "";

    var activityName = makeActivityName(layout);
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
${tab}${tab}setContentView(R.layout.${makeLayoutName(layout)})""";

    for (var e in layout.elements) {
      var valName = _makeViewId(e);
      result +=
          "\n${tab}${tab}val $valName = findViewById<${_makeViewClassName(e)}>(R.id.$valName)";

      for (var receptor in e.receptors) {
        if (receptor.description.isNotEmpty) {
          result += "\n${tab}${tab}/**"
              "\n * ${tab}${tab}Description: ${receptor.description}"
              "\n${tab}${tab}*/";
        }

        switch (receptor.type) {
          case ReceptorType.doOnClick:
            // if (e.selectedViewType != ViewType.list &&
            //     e.selectedViewType != ViewType.grid) {
              var actionCode = _getActionCode(receptor);
              result += """\n${tab}${tab}$valName.setOnClickListener { 
$actionCode
${tab}${tab}}""";
            // }

            break;
          default:
            // do nothing
            break;
        }
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
${tab}${tab}val adapter = ${e.id.capitalizeFirst}Adapter(
${tab}${tab}${tab}items = AppDataState.${e.id}DataSource.get(), 
${tab}${tab}${tab}onItemClickListener = { position, viewType ->""";

          var receptor = e.receptors.firstWhereOrNull((r) => r.type == ReceptorType.doOnClick);
          if(receptor!=null) {
            var actionCode = _getActionCode(receptor);
            result += "\n$actionCode\n";
          }
          result += """${tab}${tab}${tab}}
${tab}${tab})
          
${tab}${tab}$valName.adapter = adapter
          
${tab}${tab}AppDataState.${e.id}DataSource.onDataChanged = { newData ->
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

  String _makeViewId(CodeElement e) {
    return "${e.id}${e.selectedViewType.name.capitalizeFirst}";
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

  String _getActionCode(CodeReceptor receptor) {
    var onButtonClick = """${tab}${tab}${tab}TODO("Not yet implemented")""";

    var nextScreenValue = receptor.actions
        .firstWhereOrNull(
            (action) => action.type == ActionType.moveToNextScreen)
        ?.nextScreenValue;
      if (nextScreenValue != null) {
        var nextScreenBundle = appFruits.selectedProject!.screens.firstWhere((screen) => screen.name == nextScreenValue!.name);

        onButtonClick = """
    ${tab}${tab}${tab}startActivity(
    ${tab}${tab}${tab}${tab}Intent(this, ${makeActivityName(nextScreenBundle.layouts.first)}::class.java)
    ${tab}${tab}${tab})""";
    } // else {
// todo:
    // var backToPrevBlock = receptor.firstWhereOrNull((listener) =>
    //     listener.actions.any((action) =>
    //     action.actionType == ActionCodeTypeMain.backToPrevious));
    // if (backToPrevBlock != null) {
    //   onButtonClick = "${tab}${tab}${tab}onBackPressedDispatcher.onBackPressed()";
    // }
    return onButtonClick;
  }
}
