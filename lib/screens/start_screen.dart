// import 'dart:convert';
// import 'dart:ffi';

// import 'dart:ffi';
// import 'dart:math';
// import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';

// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:developer' as developer;
// import 'package:file_picker/file_picker.dart';
import '../box/app_utils.dart';
import '../screens/main_screen.dart';
import '../box/data_classes.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Structure Compositor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const StartPage(title: 'Structure Compositor'),
    );
  }
}

// todo: добавить вкладки для нескольких макетов
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
                itemCount: appDataTree.projects.length,
                itemBuilder: (BuildContext context, int index) {
                  return _buildProjectRow(appDataTree.projects[index]);
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
      appDataTree.projects.add(newProject);
      // var className = appDataTree.runtimeType.toString();
      // box.put(className, appDataTree);
    });
  }

  Widget _buildProjectRow(Project project) {
    return InkWell(
        child: Container(
          color: Colors.deepPurpleAccent,
          padding:
              const EdgeInsets.only(top: 16, left: 16, bottom: 16, right: 16),
          width: 280,
          child: TextFormField(
            initialValue: project.name,
            onChanged: (text) {
              project.name = text;
            },
          ),
        ),
        onTap: () {
          appDataTree.selectedProject = project;

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        });
  }
}
