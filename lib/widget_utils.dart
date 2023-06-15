import 'package:flutter/material.dart';

Widget _makeMenuWidget(
    List<String> items, BuildContext context, String dialogTitle) {
  List<Widget> menuItems = [];
  for (var value in items) {
    menuItems.add(InkWell(
      child: Container(
          width: 240,
          padding:
          const EdgeInsets.only(top: 8, bottom: 8, left: 15, right: 17),
          child: Text("-> $value")),
      onTap: () {
        Navigator.pop(context, dialogTitle);
      },
    ));
  }
  return Container(
      alignment: Alignment.centerLeft,
      height: items.length * 36,
      child: Column(children: menuItems));
}