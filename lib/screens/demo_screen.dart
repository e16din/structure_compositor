import 'package:flutter/material.dart';
import 'package:structure_compositor/box/data_classes.dart';

import '../box/app_utils.dart';
import '../box/widget_utils.dart';

class DemoScreen extends StatelessWidget {
  final ScreenBundle demoScreen;

  DemoScreen(this.demoScreen, {super.key});

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

  DemoPage(this.demoScreen, {Key? key}) : super(key: key);

  @override
  State<DemoPage> createState() => _DemoPageState(demoScreen);
}

class _DemoPageState extends State<DemoPage> {
  ScreenBundle demoScreen;

  _DemoPageState(this.demoScreen);

  List<ScreenBundle> screensHistory = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("${appDataTree.selectedProject!.name} Demo"),
        ),
        body: Row(
          children: [
            Expanded(
                flex: 16,
                child: Container(
                  child: Column(children: [
                    BackButton(onPressed: () {
                      screensHistory.removeLast();
                      if (screensHistory.isNotEmpty) {
                        setState(() {
                          demoScreen = screensHistory.last;
                        });
                      } else {
                        Navigator.of(context).pop();
                      }
                    })
                  ]),
                )),
            Expanded(
              flex: 16,
              child: Listener(
                  // onPointerDown: _onPointerUp,
                  onPointerUp: _onPointerUp,
                  // onPointerMove: _onPointerUp,
                  child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Stack(children: [
                        Image.memory(demoScreen.layoutBytes!,
                            fit: BoxFit.contain),
                        CustomPaint(
                          painter: ElementPainter(demoScreen.elements),
                        )
                      ]))),
            ),
            Expanded(flex: 16, child: Container()),
          ],
        ));
  }

  void _onPointerUp(PointerEvent event) {
    setState(() {
      for (var element in demoScreen.elements) {
        if (element.functionalArea.contains(event.localPosition)) {
          for (var listener in element.listeners) {
            for (var action in listener.actions) {
              if (action is OpenNextScreenBlock) {
                setState(() {
                  demoScreen = action.nextScreenBundle!;
                  screensHistory.add(demoScreen);
                });
              }
            }
          }
        }
      }
    });
  }
}
