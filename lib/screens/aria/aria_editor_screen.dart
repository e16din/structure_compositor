// import 'dart:ffi';

// import 'dart:ffi';
// import 'dart:math';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';
import 'package:structure_compositor/screens/aria/layouts_list_widget.dart';

import '../../box/app_utils.dart';
import '../../box/data_classes.dart';
import '../../box/widget_utils.dart';


class AriaEditorScreen extends StatelessWidget {
  const AriaEditorScreen({Key? key}) : super(key: key);

// This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AriaEditorPage(),
    );
  }
}

class AriaEditorPage extends StatefulWidget {
  const AriaEditorPage({Key? key}) : super(key: key);

  @override
  State<AriaEditorPage> createState() => _AriaEditorPageState();
}

class _AriaEditorPageState extends State<AriaEditorPage> {
  var KEY_LAYOUT_IMAGE = 'KEY_LAYOUT_IMAGE';
  var KEY_ELEMENTS = 'KEY_ELEMENTS';

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Rect? lastRect;
  String _title = 'Structure Compositor';

  LayoutElement? hoveredElement;
  ListenerCodeBlock? hoveredCodeBlock;

  @override
  void initState() {
    super.initState();

    onSetStateListener = () {
      setState(() {
        // do nothing
      });
    };

    _title = 'Structure Compositor: ${appFruits.selectedProject?.name}';
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

    var screenBundle = getLayoutBundle();
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: Row(children: [
        LayoutsListWidget(),
        Expanded(
            flex: 10,
            child: Shortcuts(
              shortcuts: <ShortcutActivator, Intent>{
                LogicalKeySet(
                        LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
                    const UndoIntent(),
                LogicalKeySet(
                    LogicalKeyboardKey.control,
                    LogicalKeyboardKey.shift,
                    LogicalKeyboardKey.keyZ): const RedoIntent(),
              },
              child: Actions(
                actions: <Type, Action<Intent>>{
                  UndoIntent: UndoAction(),
                  RedoIntent: RedoAction(),
                },
                child: Stack(children: [
                  Container(color: Colors.amberAccent),
                  if (screenBundle?.elementsMain.isNotEmpty == true)
                    ListView.builder(
                      itemCount: screenBundle?.elementsMain.length,
                      itemBuilder: (BuildContext context, int index) {
                        var elementRow = _buildElementRow(
                            screenBundle!.elementsMain[index], index);
                        return elementRow;
                      },
                    ),
                ]),
              ),
            )),
        Container(
            width: 180,
            color: Colors.yellow,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 280),
              child: Column(
                children: _buildDraggableActionsList(),
              ),
            )),
        _buildFunctionalAreasWidget(),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddScreenPressed,
        tooltip: 'Add layout image',
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> _buildDraggableActionsList() {
    List<CodeBlock> codeBlocks = [];
    for (var listenerType in ListenerCodeType.values) {
      switch (listenerType) {
        case ListenerCodeType.onLifecycleEvent:
          codeBlocks.add(LifecycleEventBlock());
          break;

        default:
          codeBlocks.add(ListenerCodeBlock(listenerType));
      }
    }
    for (var actionType in ActionCodeTypeMain.values) {
      switch (actionType) {
        case ActionCodeTypeMain.openNextScreen:
          codeBlocks.add(OpenNextScreenBlock());
          break;

        default:
          codeBlocks.add(ActionCodeBlockMain(actionType));
      }
    }

    List<Widget> widgets = [];
    for (var codeBlock in codeBlocks) {
      widgets.add(_buildActionWidget(codeBlock));
    }

    return widgets;
  }

  Widget _buildFunctionalAreasWidget() {
    var selectedLayout = appFruits.selectedProject!.selectedLayout;
    if (selectedLayout?.layoutBytes != null) {
      return Container(
        width: SCREEN_IMAGE_WIDTH,
        padding: const EdgeInsets.only(top: 42, bottom: 42),
        child: Stack(fit: StackFit.expand, children: [
          RepaintBoundary(
            key: screenImageKey,
            child: Image.memory(selectedLayout!.layoutBytes!,
                fit: BoxFit.contain),
          ),
          Listener(
              onPointerDown: _onPointerDown,
              onPointerUp: _onPointerUp,
              onPointerMove: _onPointerMove,
              child: MouseRegion(
                  cursor: SystemMouseCursors.precise,
                  child: CustomPaint(
                    painter:
                    ElementPainter(getLayoutBundle()!.elementsMain),
                  ))),
          _getAddItemButtons()
          // Column(
          //   children: [
          //     Container(
          //         alignment: Alignment.center,
          //         height: 42,
          //         child: Text(
          //           selectedScreenBundle!.name,
          //           style: const TextStyle(fontSize: 18),
          //         )),
          //   ],
          // ),
        ]),
      );
    } else {
      return Container(width: SCREEN_IMAGE_WIDTH, color: Colors.white);
    }
  }

  Future<void> _onAddScreenPressed() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true
      /*,
      allowedExtensions: ['jpg', 'png']*/
      ,
    );

    if (result != null) {
// _prefs.then((prefs) {
//   var string = base64.encode(_layoutBase64!.toList());
//   prefs.setString(KEY_LAYOUT_IMAGE, string);
// });

      List<ScreenBundle> resultScreens = [];
      for (var f in result.files) {
        var layoutBytes = f.bytes;

        int index =
            appFruits.selectedProject!.layouts.length + resultScreens.length;
        ScreenBundle screenBundle = ScreenBundle("New Screen ${index + 1}")
          ..isLauncher = index == 0;

        if (layoutBytes != null) {
          screenBundle.layoutBytes = layoutBytes;
        } else if (f.path != null) {
          screenBundle.layoutBytes = await readFileByte(f.path!);
        }

        resultScreens.add(screenBundle);
      }
      setState(() {
        appFruits.selectedProject!.layouts.addAll(resultScreens);
        appFruits.selectedProject!.selectedLayout = resultScreens.first;
      });
    }
  }

  Container _buildActionWidget(CodeBlock codeBlock) {
    return Container(
      padding: const EdgeInsets.only(left: 18, right: 8, top: 16),
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
      details, CodeBlock codeBlock, LayoutElement? element) {
    if (hoveredCodeBlock == null) {
      if (codeBlock is LifecycleEventBlock) {
        var itemsMap = <String, String>{};
        for (var event in codeBlock.events) {
          itemsMap.putIfAbsent(event, () => event);
        }
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("Select lifecycle event:"),
                content: makeMenuWidget(itemsMap, context, (selected) {
                  setState(() {
                    element?.listeners.add(codeBlock.copyStubWith(selected));
                  });
                }),
              );
            });
      } else {
        setState(() {
          element?.listeners.add(codeBlock.copyBlock() as ListenerCodeBlock);
        });
      }
    } else {
      var screenBundles = appFruits.selectedProject!.layouts;
      setState(() {
        if (codeBlock is ActionCodeBlockMain) {
          if (codeBlock.actionType == ActionCodeTypeMain.openNextScreen &&
              screenBundles.isNotEmpty) {
            var hoveredCodeBlockHolder = hoveredCodeBlock!;
            selectLayout(
                codeBlock as OpenNextScreenBlock, hoveredCodeBlockHolder,
                (selected) {
              var copyStubWith = codeBlock.copyStubWith(selected);
              hoveredCodeBlockHolder.actions.add(copyStubWith);
            });
          } else if (codeBlock.actionType == ActionCodeTypeMain.backToPrevious &&
              screenBundles.isNotEmpty) {
            hoveredCodeBlock?.actions.add(codeBlock.copyBlock());
          } else {
            hoveredCodeBlock?.actions.add(codeBlock.copyBlock());
          }
        }
      });
    }
  }

  void selectLayout(OpenNextScreenBlock codeBlock,
      ListenerCodeBlock hoveredCodeBlock, Function(dynamic) onItemSelected) {
    var screens = appFruits.selectedProject!.layouts.whereType<ScreenBundle>();

    Map<String, dynamic> itemsMap = {};
    for (var screen in screens) {
      itemsMap.putIfAbsent(screen.name, () => screen);
    }

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Select Screen:"),
            content: makeMenuWidget(itemsMap, context, onItemSelected),
          );
        }).then((value) {
      _resetHoveredBlocks();
    });
  }

  LayoutElement? _activeElement;

  Widget _buildElementRow(LayoutElement element, int index) {
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
                        initialValue: element.name,
                        decoration:
                            const InputDecoration(labelText: "name(id)"),
                        onChanged: (value) {
                          _activeElement = element;
                          _onElementNameChanged.call(value, element);
                        })),
                DropdownButton(
                    value: element.viewType,
                    items: ViewType.values
                        .map((type) => DropdownMenuItem<ViewType>(
                              value: type,
                              child: Text(type.viewName),
                            ))
                        .toList(),
                    onTap: () {
                      _activeElement = element;
                    },
                    onChanged: (ViewType? viewType) {
                      _onElementTypeChanged(viewType, element);
                    }),
                Column(
                  children: [
                    IconButton(
// alignment: Alignment.topRight,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            getLayoutBundle()!.elementsMain.remove(element);
                          });
                        }),
                    IconButton(
// alignment: Alignment.topRight,
                        icon: const Icon(
                          Icons.alt_route_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _onExtendLayoutPressed(element, null);
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

  Future<LayoutBundle> _onExtendLayoutPressed(
      LayoutElement element, String? name) async {
    var layoutBytes = await _takeElementImage(element);
    var index = appFruits.selectedProject!.layouts.length;

    LayoutBundle layoutBundle = LayoutBundle(name ??= "new_layout${index + 1}");
    layoutBundle.layoutBytes = layoutBytes;

    setState(() {
      appFruits.selectedProject!.selectedLayout = layoutBundle;
      appFruits.selectedProject!.layouts.add(layoutBundle);
    });

    return layoutBundle;
  }

  Widget _buildCodeActionsWidgets(LayoutElement layout) {
    List<Widget> listeners = [];

    for (var listener in layout.listeners) {
      var listenerBlockName = listener is LifecycleEventBlock
          ? listener.selectedEvent
          : listener.name;
      List<Widget> actionWidgets = [
        TextFormField(decoration: InputDecoration(labelText: listenerBlockName))
      ];
      for (var action in listener.actions) {
        var removeActionWidget = Align(
          alignment: Alignment.topRight,
          child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  listener.actions.remove(action);
                });
              }),
        );
        if (action is OpenNextScreenBlock) {
          var actionContainer = Stack(
            children: [
              Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.only(
                      left: 42 + 36, right: 16, top: 12, bottom: 8),
                  child: Column(
                    children: [
                      TextFormField(
                          decoration: InputDecoration(labelText: action.name)),
                      if (action.nextScreenBundle == null)
                        IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              var layouts = appFruits.selectedProject!.layouts;
                              if (layouts.isNotEmpty) {
                                selectLayout(action, listener, (selected) {
                                  setState(() {
                                    action.nextScreenBundle = selected;
                                  });
                                });
                              }
                            })
                    ],
                  )),
              removeActionWidget
            ],
          );
          actionWidgets.add(actionContainer);

          if (action.nextScreenBundle != null) {
            actionWidgets.add(Container(
                padding: const EdgeInsets.only(
                    left: 42 + 36, right: 16, top: 12, bottom: 8),
                child: Row(
                  children: [
                    FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.black12),
                        onPressed: () {
                          // do nothing
                        },
                        child: Text(action.nextScreenBundle!.name)),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            action.nextScreenBundle = null;
                          });
                        })
                  ],
                )));
          }
        } else {
          var actionContainer = Stack(
            children: [
              Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.only(
                      left: 42 + 36, right: 16, top: 12, bottom: 8),
                  child: TextFormField(
                      decoration: InputDecoration(labelText: action.name))),
              removeActionWidget
            ],
          );
          actionWidgets.add(actionContainer);
        }
      }

      var listenerContainerWidget = InkWell(
        onTap: () {
          // need to onHover
        },
        onHover: (hovered) {
          if (hovered) {
            if (hoveredCodeBlock != listener) {
              setState(() {
                hoveredCodeBlock = listener;
              });
            }
          } else {
            setState(() {
              hoveredCodeBlock = null;
            });
          }
        },
        child: Stack(
          children: [
            Container(
                decoration: BoxDecoration(
                    border: Border.all(
                        color: hoveredCodeBlock == listener
                            ? Colors.black
                            : layout.color,
                        width: 2)),
                // alignment: Alignment.topLeft,
                padding: const EdgeInsets.only(
                    left: 42, right: 16, top: 12, bottom: 8),
                child: Column(
                  children: actionWidgets,
                )),
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      layout.listeners.remove(listener);
                    });
                  }),
            )
          ],
        ),
      );
      listeners.add(listenerContainerWidget);
    }

    return Column(children: listeners);
  }

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      lastRect = Rect.fromPoints(event.localPosition, event.localPosition);
      _activeElement = LayoutElement(lastRect!, getNextColor(getLayoutBundle()?.elementsMain.length), true)
        ..name = 'element${getLayoutBundle()!.elementsMain.length + 1}';

      getLayoutBundle()!.elementsMain.add(_activeElement!);
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    setState(() {
      getLayoutBundle()!.elementsMain.last.functionalArea =
          Rect.fromPoints(lastRect!.topLeft, event.localPosition);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    var area = getLayoutBundle()!.elementsMain.last.functionalArea;
    if (area.left.floor() == area.right.floor() &&
        area.top.floor() == area.bottom.floor()) {
      setState(() {
        _listWaitedForListItem = null;
        getLayoutBundle()!.elementsMain.removeLast();
      });
    } else {
// todo: save data to db
      _prefs.then((prefs) {
// var elements = _elements.to.encode(_layoutBase64!.toList());
// prefs.setStringList(KEY_ELEMENTS, string);
      });
    }

    var element = _activeElement!;
    showDialog(
        context: context,
        builder: (context) {
          Map<String, ViewType> viewTypesMap = {};
          for (var viewType in ViewType.values) {
            viewTypesMap[viewType.viewName] = viewType;
          }

          return AlertDialog(
              title: const Text("Select view type:"),
              content: makeMenuWidget(viewTypesMap, context, (selected) {
                _onViewTypeSelected(selected, element);
              }));
        }).then((item) {
      setState(() {
        _activeElement!.isInEdit = false;
      });
    });
  }





  void _onElementTypeChanged(ViewType? viewType, LayoutElement element) {
    setState(() {
      switch (viewType) {
        case ViewType.field:
          if (!element.listeners.any((element) =>
              element.listenerType == ListenerCodeType.onTextChanged)) {
            element.listeners
                .add(ListenerCodeBlock(ListenerCodeType.onTextChanged));
          }
          break;
        case ViewType.button:
          if (!element.listeners.any(
              (element) => element.listenerType == ListenerCodeType.onClick)) {
            element.listeners.add(ListenerCodeBlock(ListenerCodeType.onClick));
          }
          break;
        case ViewType.switcher:
          if (!element.listeners.any((element) =>
              element.listenerType == ListenerCodeType.onItemSelected)) {
            element.listeners
                .add(ListenerCodeBlock(ListenerCodeType.onItemSelected));
          }
          break;
        case ViewType.list:
        case ViewType.grid:
          getLayoutBundle()!
              .listLinkListItemsMap
              .putIfAbsent(element, () => []);
          var listItems =
              getLayoutBundle()!.listLinkListItemsMap[element] ??= [];
          for (var listItem in listItems) {
            // todo: check it
            element.listeners
                .add(ListenerCodeBlock(ListenerCodeType.onItemSelected));
          }

          break;
        default:
          // do nothing
          break;
      }
      element.viewType = viewType!;
    });
  }

  LayoutElement? _listWaitedForListItem;

  void _onAddListItemClick(LayoutElement listElement) {
    _listWaitedForListItem = listElement;
    showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
              title: Text("Next Step:"),
              content: Text("Draw an area of List Item on the layout"));
        });
  }

  void _onElementNameChanged(String value, LayoutElement element) {
    element.name = value;
  }

  GlobalKey screenImageKey = GlobalKey();

  Future<Uint8List> _takeElementImage(LayoutElement screenElement) async {
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

  Widget _getAddItemButtons() {
    List<Widget> buttons = [];
    for (var listElement in getLayoutBundle()!.listLinkListItemsMap.keys) {
      buttons.add(Positioned(
          left: listElement.functionalArea.left,
          top: listElement.functionalArea.top,
          child: FloatingActionButton.small(
              backgroundColor: Colors.green,
              onPressed: () {
                _onAddListItemClick(listElement);
              },
              child: const Icon(Icons.add_box_rounded))));
    }
    return Stack(children: buttons);
  }

  void _onViewTypeSelected(ViewType? selected, LayoutElement element) async {
    if (_listWaitedForListItem != null) {
      var listLinkListItemsMap = getLayoutBundle()!.listLinkListItemsMap;
      Map<String, LayoutElement> itemsMap = {};
      for (var listElement in listLinkListItemsMap.keys) {
        itemsMap[listElement.name] = listElement;
      }

      var listItems = listLinkListItemsMap[_listWaitedForListItem!] ??= [];
      var layout =
          await _onExtendLayoutPressed(element, "item_${listItems.length + 1}");

      element.refToExtendedLayout = layout;
      listItems.add(element);
      listLinkListItemsMap[_listWaitedForListItem!] = listItems;

      _listWaitedForListItem = null;
    }

    _onElementTypeChanged(selected, element);
  }
}

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class UndoAction extends Action<UndoIntent> {
  UndoAction();

  @override
  void invoke(covariant UndoIntent intent) {
    // todo: add stack of actions
    debugPrint("Undo");
  }
}

class RedoAction extends Action<RedoIntent> {
  RedoAction();

  @override
  void invoke(covariant RedoIntent intent) {
    debugPrint("Redo");
  }
}
