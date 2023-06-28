import 'dart:typed_data';
import 'data_classes.dart';

AppDataFruits appFruits = AppDataFruits();

ScreenBundle? getScreenBundle() =>
    appFruits.selectedProject?.selectedScreenBundle;

Uint8List convertToUint8List(String layoutBytes) {
  Uint8List result = Uint8List.fromList(layoutBytes.codeUnits);
  return result;
}
