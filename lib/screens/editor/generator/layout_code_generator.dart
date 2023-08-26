import 'package:code_text_field/code_text_field.dart';
import 'package:get/get.dart';

import '../../../box/app_utils.dart';
import '../../../box/data_classes.dart';
import 'package:highlight/languages/xml.dart';

class LayoutCodeGenerator {
  String MAIN_XML_FILE_NAME = "main.xml";

  void updateLayoutFiles(ElementNode rootNode) {
    var layout = getLayoutBundle()!;
    layout.layoutFiles.clear();

    CodeFile rootFile = CodeFile(CodeLanguage.xml, MAIN_XML_FILE_NAME,
        CodeController(language: xml, text: ""), rootNode);
    layout.layoutFiles.add(rootFile);

    var itemNodes = rootNode.getNodesWhere((node) =>
    node.containerNode?.element.selectedViewType == ViewType.list);
    for (var node in itemNodes) {
      node.containerNode?.contentNodes.remove(node);
      CodeFile itemFile = CodeFile(
          CodeLanguage.xml,
          "item_${node.element.elementId}.xml",
          CodeController(language: xml, text: ""),
          node);
      layout.layoutFiles.add(itemFile);
    }

    for (var file in layout.layoutFiles) {
      String xmlLayoutText =
      _generateXmlViewsByElements(file.elementNode, true);
      file.codeController.text = xmlLayoutText;
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
            "@+id/${n.element.elementId}${n.element.selectedViewType.viewName.removeAllWhitespace}";
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
        var elementId = n.element.elementId;
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
      "@+id/${e.elementId}${e.selectedViewType.viewName.removeAllWhitespace}";

}