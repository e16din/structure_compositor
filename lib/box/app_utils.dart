import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:get/get.dart';

import 'data_classes.dart';

AppDataFruits appFruits = AppDataFruits();

Project? getSelectedProject() => appFruits.selectedProject;

ScreenBundle? getScreenBundle() => appFruits.selectedProject?.selectedScreen;

LayoutBundle? getLayoutBundle() =>
    appFruits.selectedProject?.selectedScreen?.selectedLayout;

Uint8List convertToUint8List(String layoutBytes) {
  Uint8List result = Uint8List.fromList(layoutBytes.codeUnits);
  return result;
}

var onSetStateListener = () {};

Future<Uint8List> readFileByte(String filePath) async {
  File audioFile = File(filePath);
  Uint8List? bytes;
  await audioFile.readAsBytes().then((value) {
    bytes = Uint8List.fromList(value);
  });
  return bytes!;
}

String toHex(Color color) {
  return color.value.toRadixString(16);
}

Color fromHex(String hex) {
  hex = hex.toUpperCase().replaceAll("#", "");
  String formattedHex = (hex.length == 6 ? "FF" : "") + hex;
  return Color(int.parse(formattedHex, radix: 16));
}
