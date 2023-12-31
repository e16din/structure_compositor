import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart';

import 'data_classes.dart';

AppDataFruits appFruits = AppDataFruits();

LayoutBundle? getLayoutBundle() =>
    appFruits.selectedProject?.selectedLayout;

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


