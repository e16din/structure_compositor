import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:structure_compositor/screens/start_screen.dart';

import 'box/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

const String BOX_APP_DATA_TREE = "BOX_APP_DATA_TREE";

main() async {
  await Hive.initFlutter();
  var box = await Hive.openBox(BOX_APP_DATA_TREE);

  if (box.length > 0) {
    appFruits = await box.getAt(0);
  }

  runApp(const StartScreen());
}

// LazyBox? hiveBox;