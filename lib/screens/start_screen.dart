// import 'dart:convert';
// import 'dart:ffi';

// import 'dart:ffi';
// import 'dart:math';
// import 'dart:typed_data';

import 'dart:io';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:structure_compositor/box/widget_utils.dart';

// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:developer' as developer;
// import 'package:file_picker/file_picker.dart';
import '../box/app_utils.dart';
import '../box/data_classes.dart';
import 'editor/era_editor_widget.dart';

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

// todo: сохранять последние открытые вкладки/ восстанавливать их при загрузке
class StartPage extends StatefulWidget {
  const StartPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {

  @override
  void initState() {
    super.initState();

    _loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("appFruits.projects.length: ${appFruits.projects.length}");
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

  void _onAddProjectPressed() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    var projectName = "New Project";

    if (selectedDirectory != null) {
      final appDirectory = await getApplicationDocumentsDirectory();
      var projectsListFile =
          File("${appDirectory.path}/$PROJECTS_LIST_FILE_NAME");

      String lastList = "";
      if (await projectsListFile.exists()) {
        lastList = await projectsListFile.readAsString();
        lastList += "\n$selectedDirectory";
      } else {
        lastList += "$selectedDirectory";
      }
      await projectsListFile.writeAsString(lastList);

      var newProject = Project(name: projectName, path: selectedDirectory);

      _createTempProjectProperties(newProject);
      setState(() {
        appFruits.projects.add(newProject);
        // var className = appDataTree.runtimeType.toString();
        // box.put(className, appDataTree);
      });
    }
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
                    key: Key(project.path),
                    onChanged: (text) {
                      project.name = text;
                      EasyDebounce.debounce(
                          "project_name", const Duration(milliseconds: 550),
                          () {
                        _updateProjectsList(project);
                      });
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

          Get.to(const EraEditorScreen());
        });
  }

  void _updateProjectsList(Project project) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    var projectsListFile =
        File("${appDirectory.path}/$PROJECTS_LIST_FILE_NAME");

    String lastList = "";
    lastList = await projectsListFile.readAsString();
    var lines = lastList.split("\n");
    var oldValue = lines.firstWhere((text) => text.contains(project.path));
    var newValue = "${project.name}=${project.path}";
    lastList = lastList.replaceFirst(oldValue, newValue);
    debugPrint("12123: "+lastList);
    await projectsListFile.writeAsString(lastList);
  }

  void _createTempProjectProperties(Project project) async {
    var fileName =
        "${project.name.replaceAll(" ", "_").toLowerCase()}.properties";
    debugPrint("fileName: $fileName");
    project.propertiesPath = "${project.path}/$fileName";
    await File("${project.path}/$fileName").writeAsString("");
  }

  var PROJECTS_LIST_FILE_NAME = "projects_list.txt";

  void _loadProjects() async {
    final directory = await getApplicationDocumentsDirectory();
    var file = File("${directory.path}/$PROJECTS_LIST_FILE_NAME");
    var projectsList = await file.readAsString();
    projectsList.split("\n").forEach((nameAndPath) {
      var pair = nameAndPath.split("=");
      var project = Project(name: pair[0], path: pair[1]);
      appFruits.projects.add(project);
    });

    setState(() {});
  }
}
