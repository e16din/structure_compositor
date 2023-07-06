import 'dart:typed_data';
import 'data_classes.dart';

AppDataFruits appFruits = AppDataFruits();

LayoutBundle? getLayoutBundle() =>
    appFruits.selectedProject?.selectedLayout;

Uint8List convertToUint8List(String layoutBytes) {
  Uint8List result = Uint8List.fromList(layoutBytes.codeUnits);
  return result;
}

var onSetStateListener = () {};
