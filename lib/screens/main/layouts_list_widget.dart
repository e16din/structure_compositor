import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../box/app_utils.dart';
import '../../box/code_generation.dart';
import '../../box/data_classes.dart';
import '../../box/widget_utils.dart';
import '../demo_screen.dart';


class LayoutsListWidget extends StatefulWidget {
  const LayoutsListWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return LayoutsListState();
  }
}

class LayoutsListState extends State<LayoutsListWidget> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: Colors.amber,
      child: Stack(children: [
        Container(
          padding: const EdgeInsets.only(bottom: 110),
          child: ListView.separated(
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              indent: 16,
              endIndent: 24,
            ),
            scrollDirection: Axis.vertical,
            itemCount: (appFruits.selectedProject != null
                ? appFruits.selectedProject?.layouts.length
                : 0)!,
            itemBuilder: (BuildContext context, int index) {
              var screenBundle = appFruits.selectedProject!.layouts[index];
              return InkWell(
                child: _buildLayoutRow(index, screenBundle),
                onTap: () {
                  appFruits.selectedProject!.selectedLayout = screenBundle;
                  onSetStateListener.call();
                },
              );
            },
          ),
        ),
        Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.bottomCenter,
            child: Row(
              children: [
                FilledButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Project Type:"),
                              content: makeMenuWidget({
                                "Android": "Android",
                                "Flutter": "Flutter",
                                "iOS": "iOS",
                                "Add New Project Type": "Add New Project Type",
                              }, context, (selected) {
                                if (selected == "Android") {
                                  _onGenerateProjectClick();
                                }
                              }),
                            );
                          });
                    },
                    child: const Text("Generate Code")),
                const SizedBox(
                  width: 12,
                  height: 1,
                ),
                FilledButton(
                    onPressed: () {
                      _runDemo();
                    },
                    child: const Text("Run Demo")),
              ],
            ))
      ]),
    );
  }

  Widget _buildLayoutRow(int index, LayoutBundle layout) {
    var selectedProject = appFruits.selectedProject;
    bool isSelected = selectedProject!.selectedLayout == layout;
    return Container(
      height: 108,
      color: isSelected ? Colors.deepOrangeAccent : Colors.transparent,
      padding: const EdgeInsets.only(left: 16, bottom: 21),
      child: Stack(children: [
        Row(children: [
          Expanded(
            child: TextFormField(
              initialValue: layout.name,
              decoration: const InputDecoration(labelText: "Screen Name:"),
              onChanged: (text) {
                layout.name = text;
              },
            ),
          ),
          Container(
            width: 16,
          ),
          if (layout.layoutBytes != null)
            Container(
                width: 84,
                padding: const EdgeInsets.only(right: 36, top: 16),
                child: Image.memory(layout.layoutBytes!, fit: BoxFit.scaleDown))
          else
            const Icon(Icons.ad_units)
        ]),
        Container(
          alignment: Alignment.topRight,
          child: IconButton.filledTonal(
              color: Colors.white30,
              onPressed: () {
                  selectedProject.layouts.remove(layout);
                  if (layout == selectedProject.selectedLayout) {
                    selectedProject.selectedLayout =
                        selectedProject.layouts.isNotEmpty
                            ? selectedProject.layouts.first
                            : null;
                  }
                  onSetStateListener.call();
              },
              icon: const Icon(Icons.close)),
        )
      ]),
    );
  }

  void _runDemo() {
    var demoScreen = appFruits.selectedProject!.layouts.firstWhere(
            (element) => element is ScreenBundle && element.isLauncher)
        as ScreenBundle;
    Get.to(() => DemoScreen(demoScreen));
  }

  _onGenerateProjectClick() async {
    var project = appFruits.selectedProject!;
    // FilePickerResult? result = await FilePicker.platform.pickFiles();

    // todo: select folder

    try {
      // macos
      String? result = await FilePicker.platform.getDirectoryPath();
      debugPrint("PATH! $result");

//     // File folder = File(project.screenBundles.first.layoutPath!);
//     //
//     // String? path = await FilePicker.platform.getDirectoryPath(
//     //   initialDirectory: folder.parent.path
//     // );
//     if (result != null) {
      CodeGenerator.generate(project, Directory("$result"));
    } catch (e) {
      // Web
      CodeGenerator.generate(project, Directory("Downloads"));
    }
    // }
  }
}
