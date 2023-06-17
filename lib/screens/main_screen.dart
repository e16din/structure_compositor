// import 'dart:ffi';

// import 'dart:ffi';
// import 'dart:math';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';
import 'package:structure_compositor/screens/demo_screen.dart';

import '../box/app_utils.dart';
import '../box/data_classes.dart';
import '../box/widget_utils.dart';
import 'start_screen.dart';

int _nextColorPosition = 0;

var codeBlocks = [
  // Listeners:
  CodeBlock("onClick() { }", CodeType.listener, Colors.purple),
  CodeBlock("onTextChanged() { }", CodeType.listener, Colors.purple),
  CodeBlock("onItemSelected() { }", CodeType.listener, Colors.purple),
  CodeBlock("onTimerTick() { }", CodeType.listener, Colors.purple),
  CodeBlock("onResponse() { }", CodeType.listener, Colors.purple),
  CodeBlock("onDataChanged() { }", CodeType.listener, Colors.purple),
  // Actions:
  CodeBlock("sendRequest()", CodeType.action, Colors.green),
  CodeBlock("updateWidget()", CodeType.action, Colors.green),
  OpenNextScreenBlock("openNextScreen()", CodeType.action, Colors.green),
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
  CodeBlock? hoveredCodeBlock;

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
                  child: _buildScreenBundleItemRow(index, screenBundle),
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
                padding: const EdgeInsets.all(16),
                alignment: Alignment.bottomCenter,
                child: Row(
                  children: [
                    FilledButton(
                        onPressed: () {
                          _generateCode();
                        },
                        child: const Text("Generate Code")),
                    Container(width: 12, height: 1,),
                    FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              var screen = appDataTree.selectedProject!.screenBundles.first;
                              return DemoScreen(screen);
                            }),
                          );
                        },
                        child: const Text("Run Demo")),
                  ],
                ))
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
                children: _buildDraggableActionsList(),
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
        onPressed: _onAddScreenPressed,
        tooltip: 'Add layout image',
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> _buildDraggableActionsList() {
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
              RepaintBoundary(
                key: screenImageKey,
                child: Image.memory(selectedScreenBundle!.layoutBytes!,
                    fit: BoxFit.contain),
              ),
              Listener(
                  onPointerDown: _onPointerDown,
                  onPointerUp: _onPointerUp,
                  onPointerMove: _onPointerMove,
                  child: MouseRegion(
                      cursor: SystemMouseCursors.precise,
                      child: CustomPaint(
                        painter: ElementPainter(getScreenBundle()!.elements),
                      )))
            ],
          ));
    } else {
      return Expanded(flex: 16, child: Container(color: Colors.white));
    }
  }

  Future<void> _onAddScreenPressed() async {
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

      int index = appDataTree.selectedProject!.screenBundles.length;
      ScreenBundle screenBundle = ScreenBundle(name: "New Screen ${index + 1}");

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
    setState(() {
      if (hoveredCodeBlock == null) {
        element?.listeners.add(codeBlock.copyStub());
      } else {
        var screenBundles = appDataTree.selectedProject!.screenBundles;
        if (codeBlock is OpenNextScreenBlock && screenBundles.isNotEmpty) {
          var hoveredCodeBlockHolder = hoveredCodeBlock!;
          selectScreen(screenBundles, codeBlock, hoveredCodeBlockHolder,
              (selected) {
            setState(() {
              var copyStubWith = codeBlock.copyStubWith(selected);
              hoveredCodeBlockHolder.actions.add(copyStubWith);
            });
          });
        } else {
          hoveredCodeBlock?.actions.add(codeBlock.copyStub());
        }
      }
    });
  }

  void selectScreen(
      List<ScreenBundle> screenBundles,
      OpenNextScreenBlock codeBlock,
      CodeBlock hoveredCodeBlock,
      Function(dynamic) onItemSelected) {
    Map<String, dynamic> itemsMap = {};
    for (var screen in screenBundles) {
      itemsMap.putIfAbsent(screen.name, () => screen);
    }

    showDialog(
        context: context,
        builder: (BuildContext context) {
          var dialogTitle = "Select screen:";
          return AlertDialog(
            title: Text(dialogTitle),
            content:
                makeMenuWidget(itemsMap, context, dialogTitle, onItemSelected),
          );
        }).then((value) => {_resetHoveredBlocks()});
  }

  Widget _buildScreenBundleItemRow(int index, ScreenBundle screenBundle) {
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
            decoration: const InputDecoration(labelText: "Screen Name:"),
            onChanged: (text) {
              screenBundle.name = text;
            },
          ),
        ),
        Container(
          width: 24,
        ),
        if (screenBundle.layoutBytes != null)
          Image.memory(screenBundle.layoutBytes!, fit: BoxFit.contain)
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
            _resetHoveredBlocks();
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
                          _onExtendScreenPressed(element);
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

  void _resetHoveredBlocks() {
    setState(() {
      hoveredElement = null;
      hoveredCodeBlock = null;
    });
  }

  Future<void> _onExtendScreenPressed(ScreenElement screenElement) async {
    var layoutBytes = await _takeElementImage(screenElement);
    int index = appDataTree.selectedProject!.screenBundles.length;
    ScreenBundle screenBundle = ScreenBundle(name: "New Screen ${index + 1}");
    screenBundle.layoutBytes = layoutBytes;

    setState(() {
      appDataTree.selectedProject!.selectedScreenBundle = screenBundle;
      appDataTree.selectedProject!.screenBundles.add(screenBundle);
    });
  }

  Widget _buildCodeActionsWidgets(ScreenElement screenElement) {
    List<Widget> listeners = [];

    for (var listenerBlock in screenElement.listeners) {
      List<Widget> actions = [
        TextFormField(
            decoration: InputDecoration(labelText: listenerBlock.name))
      ];
      for (var actionBlock in listenerBlock.actions) {
        if (actionBlock is OpenNextScreenBlock) {
          var actionContainer = Container(
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.only(
                  left: 42 + 36, right: 16, top: 12, bottom: 8),
              child: Column(
                children: [
                  TextFormField(
                      decoration: InputDecoration(labelText: actionBlock.name)),
                  if (actionBlock.nextScreenBundle == null)
                    IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          var screenBundles =
                              appDataTree.selectedProject!.screenBundles;
                          if (screenBundles.isNotEmpty) {
                            selectScreen(
                                screenBundles, actionBlock, listenerBlock,
                                (selected) {
                              setState(() {
                                actionBlock.nextScreenBundle = selected;
                              });
                            });
                          }
                        })
                ],
              ));
          actions.add(actionContainer);

          if (actionBlock.nextScreenBundle != null) {
            actions.add(Container(
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.only(
                    left: 42 + 36, right: 16, top: 12, bottom: 8),
                child: Row(
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.black12),
                        onPressed: () {
                          // do nothing
                        },
                        child: Text(actionBlock.nextScreenBundle!.name)),
                    IconButton(
// alignment: Alignment.topRight,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            actionBlock.nextScreenBundle = null;
                          });
                        })
                  ],
                )));
          }
        } else {
          var actionContainer = Container(
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.only(
                  left: 42 + 36, right: 16, top: 12, bottom: 8),
              child: TextFormField(
                  decoration: InputDecoration(labelText: actionBlock.name)));
          actions.add(actionContainer);
        }
      }

      var listenerContainer = InkWell(
        onTap: () {
          // need to onHover
        },
        onHover: (hovered) {
          if (hovered) {
            if (hoveredCodeBlock != listenerBlock) {
              setState(() {
                hoveredCodeBlock = listenerBlock;
              });
            }
          } else {
            setState(() {
              hoveredCodeBlock = null;
            });
          }
        },
        child: Container(
            decoration: BoxDecoration(
                border: Border.all(
                    color: hoveredCodeBlock == listenerBlock
                        ? Colors.black
                        : screenElement.color,
                    width: 2)),
            alignment: Alignment.topLeft,
            padding:
                const EdgeInsets.only(left: 42, right: 16, top: 12, bottom: 8),
            child: Column(
              children: actions,
            )),
      );
      listeners.add(listenerContainer);
    }

    return Column(children: listeners);
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

  GlobalKey screenImageKey = GlobalKey();

  Future<Uint8List> _takeElementImage(ScreenElement screenElement) async {
    RenderRepaintBoundary screenImageWidget = screenImageKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    var image = await screenImageWidget.toImage();
    // ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    // Uint8List bytesList = byteData!.buffer.asUint8List();

    var pictureRecorder = ui.PictureRecorder();
    var canvas = Canvas(pictureRecorder);
    var paint = Paint();
    paint.isAntiAlias = true;
    Rect funcArea = screenElement.functionalArea;
    canvas.drawImage(image, Offset(-funcArea.left, -funcArea.top), paint);
    canvas.clipRect(funcArea);
    var pic = pictureRecorder.endRecording();

    ui.Image img =
        await pic.toImage(funcArea.width.toInt(), funcArea.height.toInt());
    var byteDataN =
        await img.toByteData(format: ui.ImageByteFormat.rawUnmodified);
    var resultList = byteDataN!.buffer.asUint8List();

    return resultList;
  }
}

class UndoShortcutIntent extends Intent {
// final String name;
}
