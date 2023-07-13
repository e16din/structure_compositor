// import 'dart:convert';
// import 'dart:ffi';

// import 'dart:ffi';
// import 'dart:math';
// import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:structure_compositor/box/widget_utils.dart';

// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:developer' as developer;
// import 'package:file_picker/file_picker.dart';
import '../box/app_utils.dart';
import 'aria/aria_editor_screen.dart';
import '../box/data_classes.dart';
import 'actions_editor_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Structure Compositor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const StartPage(title: 'Structure Compositor'),
    );
  }
}

enum WayToCreateCode {
  aria("Functional Areas Editor"),
  elemental("Actions Code Editor");

  final String title;

  const WayToCreateCode(this.title);
}

// todo: сохранять последние открытые вкладки/ восстанавливать их при загрузке
class StartPage extends StatefulWidget {
  const StartPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  // var KEY_APP_DATA = 'KEY_APP_DATA';
  // var KEY_LAST_PROJECT = 'KEY_LAST_PROJECT';

  // final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Project makeNewProject() {
    return Project(name: "New Project");
  }

  @override
  void initState() {
    super.initState();

    // _prefs.then((prefs) {
    //
    //   if (prefs.containsKey(KEY_APP_DATA)) {
    //     var json = prefs.getString(KEY_APP_DATA)!;
    //     var jsonMap = jsonDecode(json);
    //     setState(() {
    //       appDataTree = AppDataTree.fromJson(jsonMap);
    //     });
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Row(
        children: [
          Container(
            width: 380,
            color: Colors.lightBlue,
            child: ListView.separated(
                separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 24,
                    ),
                scrollDirection: Axis.vertical,
                itemCount: appFruits.projects.length,
                itemBuilder: (BuildContext context, int index) {
                  return _buildProjectRow(appFruits.projects[index]);
                }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddProjectPressed,
        tooltip: 'New project',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _onAddProjectPressed() {
    var newProject = makeNewProject();

    // _prefs.then((prefs) {
    //   var jsonMap = appDataTree.toJson();
    //   var json = jsonEncode(jsonMap);
    //   prefs.setString(KEY_APP_DATA, json);
    // });

    // var box = Hive.box(BOX_APP_DATA_TREE);
    setState(() {
      appFruits.projects.add(newProject);
      // var className = appDataTree.runtimeType.toString();
      // box.put(className, appDataTree);
    });
  }

  Widget _buildProjectRow(Project project) {
    return InkWell(
        child: Container(
          color: Colors.deepPurpleAccent,
          child: Container(
            padding:
                const EdgeInsets.only(top: 16, left: 16, bottom: 16, right: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: project.name,
                    onChanged: (text) {
                      project.name = text;
                    },
                  ),
                ),
                Container(
                    padding: const EdgeInsets.only(
                        top: 24, left: 24, bottom: 24, right: 24),
                    child: const Icon(Icons.navigate_next))
              ],
            ),
          ),
        ),
        onTap: () async {
          appFruits.selectedProject = project;

          var way = WayToCreateCode.aria;
          await showDialog(
              context: context,
              builder: (context) {
                Map<String, WayToCreateCode> itemsMap = {};
                for (var way in WayToCreateCode.values) {
                  itemsMap[way.title] = way;
                }

                return AlertDialog(
                    title: const Text("Select The Way:"),
                    content: makeMenuWidget(
                        itemsMap, context, (selected) => {way = selected}));
              }).then((value) => {_onProjectClick(way)});
        });
  }

  void _onProjectClick(selected) {
    switch (selected) {
      case WayToCreateCode.aria:
        Get.to(const AriaEditorScreen());
        break;
      case WayToCreateCode.elemental:
        Get.to(const ActionsEditorScreen());
        break;
    }
  }
}
