import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:structure_compositor/screens/editor/generator/logic_code_generator.dart';

import '../../../box/app_utils.dart';
import '../../../box/data_classes.dart';
import 'package:highlight/languages/xml.dart';

class LayoutCodeGenerator {
  void updateFiles(ElementNode rootNode, LayoutBundle layout) {
    var package = "com.example";

    layout.layoutFiles.clear();

    String fileName = "${makeLayoutName(layout)}.xml";
    CodeFile rootFile = CodeFile(fileName, "", CodeLanguage.xml, rootNode,
        "/src/main/res/layout", package, "stub");
    layout.layoutFiles.add(rootFile);

    var itemNodes = rootNode.getNodesWhere((node) =>
        node.containerNode?.element.selectedViewType == ViewType.list ||
        node.containerNode?.element.selectedViewType == ViewType.grid);
    for (var node in itemNodes) {
      debugPrint("itemNodes node: ${node.containerNode!.element.id}");
      node.containerNode?.contentNodes.remove(node);
      CodeFile itemFile = CodeFile("item_${node.element.id}.xml", "",
          CodeLanguage.xml, node, "/src/main/res/layout", package, "stub");
      layout.layoutFiles.add(itemFile);
    }

    for (var file in layout.layoutFiles) {
      String xmlLayoutText =
          _generateXmlViewsByElements(file.elementNode!, true);
      file.text = xmlLayoutText;
    }

  }

  String _generateXmlViewsByElements(ElementNode node, bool isRoot) {
    String result = """<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
\txmlns:app="http://schemas.android.com/apk/res-auto"
\txmlns:tools="http://schemas.android.com/tools"
\tandroid:layout_width="match_parent"
\tandroid:layout_height="match_parent"
\tandroid:orientation="vertical">
      """;

    for (var n in node.contentNodes) {
      if (n.isContainer()) {
        var containerViewId =
            "@+id/${n.element.id}${n.element.selectedViewType.viewName.removeAllWhitespace}";
        result += """
        <LinearLayout
              android:id="$containerViewId"
              android:layout_width="match_parent"
              android:layout_height="wrap_content"
              android:orientation="vertical"
              >
        """;
        result += _generateXmlViewsByElements(n, false);
        result += """

        </LinearLayout>
        """;
      } else {
        var elementId = n.element.id;
        var viewId = _getViewId(n.element);
        switch (n.element.selectedViewType) {
          case ViewType.text:
            result += """

          <TextView
              android:id="$viewId"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              android:text="todo" />
    """;
            break;
          case ViewType.field:
            result += """

          <EditText
              android:id="$viewId"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              android:hint="todo" />
    """;
            break;
          case ViewType.button:
            result += """

          <Button
              android:id="$viewId"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              android:text="todo" />
    """;
            break;
          case ViewType.image:
            result += """

          <ImageView
              android:id="$viewId"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              app:compatSrc="todo" />
    """;
            break;
          case ViewType.switcher:
            result += """

          <Switch
              android:id="$viewId"
              android:layout_width="wrap_content"
              android:layout_height="wrap_content"
              android:checked="todo" />
    """;
            break;
          case ViewType.list:
          case ViewType.grid:
            result += """

         <androidx.recyclerview.widget.RecyclerView
              android:id="$viewId"
              android:layout_width="match_parent"
              android:layout_height="match_parent"
              />
    """;
            break;
          case ViewType.otherView:
            result += """

         <View
              android:id="$viewId"
              android:layout_width="200dp"
              android:layout_height="200dp"
              />
    """;
            break;
        }
      }
    }

    result += "\n</LinearLayout>";
    return result;
  }

  String _getViewId(CodeElement e) =>
      "@+id/${e.id}${e.selectedViewType.viewName.removeAllWhitespace}";
}
