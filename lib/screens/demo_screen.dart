import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:structure_compositor/box/data_classes.dart';

import '../box/app_utils.dart';
import '../box/widget_utils.dart';

class DemoScreen extends StatelessWidget {
  final ScreenBundle demoScreen;

  const DemoScreen(this.demoScreen, {super.key});

// This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DemoPage(demoScreen),
    );
  }
}

class DemoPage extends StatefulWidget {
  final ScreenBundle demoScreen;

  const DemoPage(this.demoScreen, {Key? key}) : super(key: key);

  @override
  State<DemoPage> createState() => _DemoPageState(demoScreen);
}

class _DemoPageState extends State<DemoPage> {
  ScreenBundle demoScreen;

  _DemoPageState(this.demoScreen) {
    screensHistory.add(demoScreen);
  }

  List<ScreenBundle> screensHistory = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("${appFruits.selectedProject!.name} Demo"),
        ),
        body: Row(
          children: [
            Expanded(
                flex: 15,
                child: Container(
                  color: Colors.green,
                  child: const Stack(children: []),
                )),
            Container(
                width: SCREEN_IMAGE_WIDTH,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                        padding: const EdgeInsets.only(top: 42, bottom: 42),
                        child: Image.memory(demoScreen.layoutBytes!, fit: BoxFit.contain)),
                    Container(
                      padding: const EdgeInsets.only(top: 42, bottom: 42),
                      child: Listener(
                        // onPointerDown: _onPointerUp,
                        onPointerUp: _onPointerUp,
                        // onPointerMove: _onPointerUp,
                        child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: CustomPaint(
                              painter: ElementPainter(demoScreen.elements),
                            )),
                      ),
                    ),
                    Container(
                      alignment: Alignment.topLeft,
                      child: BackButton(onPressed: () {
                        _onDemoBackPressed();
                      }),
                    ),
                    Expanded(
                      child: Container(
                          alignment: Alignment.topCenter,
                          height: 42,
                          child: Text(
                            demoScreen.name,
                            style: const TextStyle(fontSize: 18),
                          )),
                    ),
                    Container(
                        alignment: Alignment.topRight,
                        child: IconButton.filled(
                            onPressed: () {
                              Get.back();
                            },
                            icon: Transform.rotate(
                                angle: -90 * pi / 180,
                                child: const Icon(Icons.exit_to_app)))),
                  ],
                )),
            Expanded(
                flex: 16,
                child: Container(
                  color: Colors.orange,
                )),
          ],
        ));
  }

  void _onDemoBackPressed() {
    screensHistory.removeLast();
    if (screensHistory.isNotEmpty) {
      setState(() {
        demoScreen = screensHistory.last;
      });
    } else {
      Get.back();
    }
  }

  void _onPointerUp(PointerEvent event) {
    setState(() {
      for (var element in demoScreen.elements) {
        if (element.functionalArea.contains(event.localPosition)) {
          for (var listener in element.listeners) {
            for (var action in listener.actions) {
              switch (action.actionType) {
                case ActionCodeTypeMain.sendRequest:
                  // TODO: Handle this case.
                  break;
                case ActionCodeTypeMain.updateWidget:
                  // TODO: Handle this case.
                  break;
                case ActionCodeTypeMain.openNextScreen:
                  setState(() {
                    demoScreen =
                        (action as OpenNextScreenBlock).nextScreenBundle!;
                    screensHistory.add(demoScreen);
                  });
                  break;
                case ActionCodeTypeMain.backToPrevious:
                  _onDemoBackPressed();
                  break;
                case ActionCodeTypeMain.changeData:
                  // TODO: Handle this case.
                  break;
                case ActionCodeTypeMain.callFunction:
                  // TODO: Handle this case.
                  break;
                case ActionCodeTypeMain.showAlertDialog:
                  // TODO: Handle this case.
                  break;
                case ActionCodeTypeMain.showSnackBar:
                  // TODO: Handle this case.
                  break;
                case ActionCodeTypeMain.comment:
                  // TODO: Handle this case.
                  break;
              }
            }
          }
        }
      }
    });
  }
}
