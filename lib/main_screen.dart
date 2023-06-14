// import 'dart:ffi';

// import 'dart:ffi';
// import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';

import 'data_classes.dart';
import 'main.dart';

int _nextColorPosition = 0;

ScreenBundle? getScreenBundle() =>
    appDataTree.selectedProject?.selectedScreenBundle;

var codeBlocks = [
  // Listeners:
  CodeBlock("onClick() { }", CodeType.listener, Colors.purple),
  CodeBlock("onTextChanged() { }", CodeType.listener, Colors.purple),
  CodeBlock("onItemSelected() { }", CodeType.listener, Colors.purple),
  CodeBlock("onResponse() { }", CodeType.listener, Colors.purple),
  CodeBlock("onDataChanged() { }", CodeType.listener, Colors.purple),
  // Actions:
  CodeBlock("sendRequest()", CodeType.action, Colors.green),
  CodeBlock("updateWidget()", CodeType.action, Colors.green),
  CodeBlock("openNextScreen()", CodeType.action, Colors.green),
  CodeBlock("changeData()", CodeType.action, Colors.green),
  CodeBlock("callFunction()", CodeType.action, Colors.green),
];

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

// This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainPage(),
    );
  }
}

// todo: добавить вкладки для нескольких макетов
// todo: сохранять последние открытые вкладки/ восстанавливать их при загрузке
class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  var KEY_LAYOUT_IMAGE = 'KEY_LAYOUT_IMAGE';
  var KEY_ELEMENTS = 'KEY_ELEMENTS';

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Rect? _lastRect;
  String _title = 'Structure Compositor';

  ScreenElement? hoveredElement;

  List<Widget> _buildCodeBlocksList() {
    List<Widget> widgets = [];
    for (var codeBlock in codeBlocks) {
      widgets.add(_buildActionWidget(codeBlock));
    }
    return widgets;
  }

  Widget _buildEditedLayoutWidget() {
    var selectedScreenBundle =
        appDataTree.selectedProject!.selectedScreenBundle;
    if (selectedScreenBundle?.layoutBytes != null) {
      return Expanded(
          flex: 16,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(selectedScreenBundle!.layoutBytes!,
                  fit: BoxFit.fitHeight),
              Listener(
                  onPointerDown: _onPointerDown,
                  onPointerUp: _onPointerUp,
                  onPointerMove: _onPointerMove,
                  child: MouseRegion(
                      cursor: SystemMouseCursors.precise,
                      child: CustomPaint(
                        painter: ElementPainter(),
                      )))
            ],
          ));
    } else {
      return Expanded(flex: 16, child: Container(color: Colors.white));
    }
  }

  Future<void> _onPickAddPressed() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png'],
    );

    if (result != null) {
// _prefs.then((prefs) {
//   var string = base64.encode(_layoutBase64!.toList());
//   prefs.setString(KEY_LAYOUT_IMAGE, string);
// });
      var layoutBytes = result.files.single.bytes;

      ScreenBundle screenBundle = ScreenBundle(name: "New Screen");

      if (layoutBytes != null) {
        screenBundle.layoutBytes = layoutBytes;
      } else if (result.files.single.path != null) {
        screenBundle.layoutBytes =
            await _readFileByte(result.files.single.path!);
      }

      setState(() {
        appDataTree.selectedProject!.selectedScreenBundle = screenBundle;
        appDataTree.selectedProject!.screenBundles.add(screenBundle);
      });
    }
  }

  Future<Uint8List> _readFileByte(String filePath) async {
    File audioFile = File(filePath);
    Uint8List? bytes;
    await audioFile.readAsBytes().then((value) {
      bytes = Uint8List.fromList(value);
    });
    return bytes!;
  }

  @override
  void initState() {
    super.initState();

    _title = 'Structure Compositor: ${appDataTree.selectedProject?.name}';
// _prefs.then((prefs) {
//   var string = prefs.getString(KEY_LAYOUT_IMAGE);
//   if (prefs.containsKey(KEY_LAYOUT_IMAGE)) {
//     setState(() {
//       _selectedLayout = base64.decode(string!);
//     });
//   }
// });
  }

  @override
  Widget build(BuildContext context) {
    developer.log("build", name: 'debug');

    var screenBundle = getScreenBundle();
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: Row(children: [
        Container(
          width: 280,
          color: Colors.amber,
          child: Stack(children: [
            ListView.separated(
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 16,
                endIndent: 24,
              ),
              scrollDirection: Axis.vertical,
              itemCount: (appDataTree.selectedProject != null
                  ? appDataTree.selectedProject?.screenBundles.length
                  : 0)!,
              itemBuilder: (BuildContext context, int index) {
                var screenBundle =
                    appDataTree.selectedProject!.screenBundles[index];
                return InkWell(
                  child: _buildScreenItemRow(screenBundle),
                  onTap: () {
                    setState(
                      () {
                        appDataTree.selectedProject!.selectedScreenBundle =
                            screenBundle;
                      },
                    );
                  },
                );
              },
            ),
            Container(
                padding: const EdgeInsets.all(28),
                alignment: Alignment.bottomCenter,
                child: FilledButton(
                    onPressed: () {
                      _generateCode();
                    },
                    child: const Text("Generate Code")))
          ]),
        ),
        Expanded(
            flex: 10,
            child: Stack(children: [
              Container(color: Colors.amberAccent),
              if (screenBundle?.elements.isNotEmpty == true)
                ListView.builder(
                  itemCount: screenBundle?.elements.length,
                  itemBuilder: (BuildContext context, int index) {
                    var elementRow =
                        _buildElementRow(screenBundle!.elements[index], index);
                    return elementRow;
                  },
                ),
            ])),
        Expanded(
          flex: 5,
          child: Container(
              color: Colors.yellow,
              child: Column(
                children: _buildCodeBlocksList(),
              )),
        ),
        _buildEditedLayoutWidget()
// Shortcuts(// todo: add shortcut
//   shortcuts: <LogicalKeySet, Intent>{
//     LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
//     UndoShortcutIntent(),
//   },
//   child: Actions(
//     actions: <Type, Action<Intent>>{
//       UndoShortcutIntent: CallbackAction<UndoShortcutIntent>(
//           onInvoke: (UndoShortcutIntent intent) => {
//             if(_elements.isNotEmpty) {
//               setState(() {
//                 _elements.removeLast();
//               })
//             }
//           }),
//     },
//     child: Focus(
//         autofocus: true,
//         child:
//     ),
//   ),
// )
        ,
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _onPickAddPressed,
        tooltip: 'Add layout image',
        child: const Icon(Icons.add),
      ),
    );
  }

  Container _buildActionWidget(CodeBlock codeBlock) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 16),
      alignment: Alignment.topLeft,
      child: Draggable(
        feedback: FilledButton(
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(codeBlock.color)),
            onPressed: () {},
            child: Text(codeBlock.name,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center)),
        onDragEnd: (details) {
          _onActionButtonMovingEnd(details, codeBlock, hoveredElement);
        },
        child: FilledButton(
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(codeBlock.color)),
            onPressed: () {},
            child: Text(codeBlock.name,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center)),
      ),
    );
  }

  void _onActionButtonMovingEnd(
      details, CodeBlock codeBlock, ScreenElement? element) {
//     showDialog(
//         context: context,
//         builder: (BuildContext context) => AlertDialog(
//               title: Text("${codeBlock.name}:"),
// // content: _makeMenuWidget(items, context, dialogTitle),
//             )).then((value) => {_resetElementsHoverState()});

    setState(() {
      element?.listeners.add(codeBlock);
    });
  }

  Widget _makeMenuWidget(
      List<String> items, BuildContext context, String dialogTitle) {
    List<Widget> menuItems = [];
    for (var value in items) {
      menuItems.add(InkWell(
        child: Container(
            width: 240,
            padding:
                const EdgeInsets.only(top: 8, bottom: 8, left: 15, right: 17),
            child: Text("-> $value")),
        onTap: () {
          Navigator.pop(context, dialogTitle);
        },
      ));
    }
    return Container(
        alignment: Alignment.centerLeft,
        height: items.length * 36,
        child: Column(children: menuItems));
  }

  Widget _buildScreenItemRow(ScreenBundle screenBundle) {
    bool isSelected =
        appDataTree.selectedProject!.selectedScreenBundle == screenBundle;
    return Container(
      height: 96,
      color: isSelected ? Colors.deepOrangeAccent : Colors.transparent,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 21),
      child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Expanded(
          child: TextFormField(
            initialValue: screenBundle.name,
            decoration: const InputDecoration(labelText: "Screen Name"),
          ),
        ),
        Container(
          width: 24,
        ),
        if (screenBundle.layoutBytes != null)
          Image.memory(screenBundle.layoutBytes!, fit: BoxFit.cover)
        else
          const Icon(Icons.ad_units)
      ]),
    );
  }

  ScreenElement? _activeElement;

  Widget _buildElementRow(ScreenElement element, int index) {
    return Container(
      padding: const EdgeInsets.only(left: 8, top: 12, right: 8, bottom: 12),
      decoration: BoxDecoration(
          color: element.color,
          border: Border.all(
            width: 2,
              color: hoveredElement == element
                  ? Colors.blue.withAlpha(166)
                  : element.color)),
      child: InkWell(
        onTap: () {
          // need to onHover
        },
        onHover: (hovered) {
          if (hovered) {
            if (hoveredElement != element) {
              setState(() {
                hoveredElement = element;
              });
            }
          } else {
            setState(() {
              hoveredElement = null;
            });
          }
        },
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("${index + 1}. "),
                SizedBox(
                    width: 140,
                    child: TextFormField(
                        initialValue:
                            'element${getScreenBundle()!.elements.length}',
                        decoration:
                            const InputDecoration(labelText: "name(id)"),
                        onChanged: (value) {
                          _activeElement = element;
                          _onElementNameChanged.call(value);
                        })),
                DropdownButton(
                    value: element.functionType,
                    items: FunctionType.values
                        .map((type) => DropdownMenuItem<FunctionType>(
                              value: type,
                              child: Text(type.name),
                            ))
                        .toList(),
                    onTap: () {
                      _activeElement = element;
                    },
                    onChanged: _onElementTypeChanged),
                Column(
                  children: [
                    IconButton(
// alignment: Alignment.topRight,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            if (_nextColorPosition > 0) {
                              _nextColorPosition -= 1;
                            }
                            getScreenBundle()!.elements.remove(element);
                          });
                        }),
                    IconButton(
// alignment: Alignment.topRight,
                        icon: const Icon(
                          Icons.alt_route_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_nextColorPosition > 0) {
                              _nextColorPosition -= 1;
                            }
                            getScreenBundle()!.elements.remove(element);
                          });
                        }),
                  ],
                )
              ],
            ),
            Container(
                color: Colors.black.withAlpha(36),
                padding: const EdgeInsets.only(
                    left: 16, top: 8, right: 16, bottom: 12),
                child: TextFormField(
                  decoration: const InputDecoration(labelText: "Description"),
                  initialValue: element.description,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  maxLength: 140,
                  minLines: 1,
                  maxLines: 7,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (text) {
                    element.description = text;
                  },
                )),
            Container(
              child: _buildCodeActionsWidgets(element),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCodeActionsWidgets(ScreenElement screenElement) {
    List<Widget> widgets = [];

    for (var codeBlock in screenElement.listeners) {
      widgets.add(Container(
          alignment: Alignment.topLeft,
          padding:
              const EdgeInsets.only(left: 42, right: 16, top: 12, bottom: 8),
          child: TextFormField(
              decoration: InputDecoration(labelText: codeBlock.name))));
    }

    return Column(children: widgets);
  }

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _lastRect = Rect.fromPoints(event.localPosition, event.localPosition);
      getScreenBundle()!
          .elements
          .add(ScreenElement(_lastRect!, getNextColor(), true));
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    setState(() {
      getScreenBundle()!.elements.last.functionalArea =
          Rect.fromPoints(_lastRect!.topLeft, event.localPosition);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
// debugPrint(
//     "left: ${_elements.last.functionalArea.left.floor()} right: ${_elements.last.functionalArea.right.floor()} top: ${_elements.last.functionalArea.top.floor()} bottom: ${_elements.last.functionalArea.bottom.floor()}");
    var area = getScreenBundle()!.elements.last.functionalArea;
    if (area.left.floor() == area.right.floor() &&
        area.top.floor() == area.bottom.floor()) {
      setState(() {
        getScreenBundle()!.elements.removeLast();
      });
    } else {
// todo: save data to db
      _prefs.then((prefs) {
// var elements = _elements.to.encode(_layoutBase64!.toList());
// prefs.setStringList(KEY_ELEMENTS, string);
      });
    }

    setState(() {
      getScreenBundle()!.elements.last.inEdit = false;
    });
  }

  final List<MaterialColor> _rainbowColors = <MaterialColor>[
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.lightBlue,
    Colors.blue,
    Colors.deepPurple
  ];

  Color getNextColor() {
    var nextColorPosition = _nextColorPosition;

    if (_nextColorPosition < _rainbowColors.length - 1) {
      _nextColorPosition += 1;
    } else {
      _nextColorPosition = 0;
    }

    return _rainbowColors[nextColorPosition].shade400;
  }

  void _onElementTypeChanged(FunctionType? value) {
    setState(() {
      _activeElement?.functionType = value!;
    });
  }

  void _onElementNameChanged(String value) {
    _activeElement?.nameId = value;
  }

  void _generateCode() async {
    var xml =
        "<structure_project name=\"Test\">Hello World!</structure_project>";
    var structure_project_bytes = Uint8List.fromList(xml.codeUnits);
    String path = await FileSaver.instance
        .saveFile(name: "Test.xml", bytes: structure_project_bytes);
    debugPrint("temp!: $path");
  }
}

class ElementPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) async {
    var paint = Paint()..style = PaintingStyle.stroke;
    getScreenBundle()?.elements.forEach((element) {
      paint.strokeWidth = element.inEdit ? 2 : 5;
      paint.color = element.inEdit ? Colors.black : element.color;
      canvas.drawRect(element.functionalArea, paint);
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class UndoShortcutIntent extends Intent {
// final String name;
}
