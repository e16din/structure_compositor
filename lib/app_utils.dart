import 'dart:typed_data';

Uint8List convertToUint8List(String layoutBytes) {
  Uint8List result = Uint8List.fromList(layoutBytes.codeUnits);
  return result;
}