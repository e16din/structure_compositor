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
import 'package:xml/xml.dart';
import '../box/app_utils.dart';
import '../box/data_classes.dart';
import 'editor/main_screen.dart';



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

    _loadRules();
    _loadProjects();
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

  void _loadRules() async {
    var selectedDirectory = await getApplicationDocumentsDirectory();

    var rulesListFile = File("${selectedDirectory.path}/$RULES_LIST_FILE_NAME");
    if (await rulesListFile.exists()) {
      var rules = await rulesListFile.readAsString();
      _initRulesMap(rules);
    } else {
      rulesListFile.create(recursive: true);

      var defaultRules = """
Android=${selectedDirectory.path}/android.rules
iOS=${selectedDirectory.path}/ios.rules
Flutter=${selectedDirectory.path}/flutter.rules
""";
      await rulesListFile.writeAsString(defaultRules);
      _initRulesMap(defaultRules);
    }
  }

  void _initRulesMap(String rules) {
    var lines = rules.split("\n");

    appFruits.rulesMap.clear();

    for (var prop in lines) {
      var pair = prop.split("=");
      if (pair.length > 1) {
        appFruits.rulesMap[pair[0]] = pair[1];

        debugPrint("rule: ${pair[0]} | path: ${pair[1]}");
      }
    }
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
      }
      lastList += "$selectedDirectory\n";

      await projectsListFile.writeAsString(lastList);

      var newProject = Project(name: projectName, path: selectedDirectory);

      await File("${newProject.path}/$PROPERTIES_FILE_NAME").writeAsString("");

      var projectFile = File("${newProject.path}/$PROJECT_FILE_NAME");
      await projectFile.writeAsString("""
<?xml version="1.0" encoding="UTF-8"?>
<project name="${newProject.name}" path="${newProject.path}" />
""");

      setState(() {
        appFruits.projects.add(newProject);
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
                            _updateProjectFile(project);
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
          _onProjectClick(project);
        });
  }

  void _updateProjectFile(Project project) async {
    var projectFile = File("${project.path}/$PROJECT_FILE_NAME");
    var projectXml = await projectFile.readAsString();
    final xmlDocument = XmlDocument.parse(projectXml);
    xmlDocument.rootElement.setAttribute("name", project.name);

    await projectFile.writeAsString(xmlDocument.toXmlString());
  }

  void _onProjectClick(Project project) async {
    appFruits.selectedProject = project;

    var projectFile = File("${project.path}/$PROJECT_FILE_NAME");
    var projectXml = await projectFile.readAsString();
    final xmlDocument = XmlDocument.parse(projectXml);
    var rule = xmlDocument.rootElement.getAttribute("rule");
    if (rule != null) {
      appFruits.selectedProject!.selectedRule = rule;
    } else {
      appFruits.selectedProject!.selectedRule = appFruits.rulesMap.keys.first;
    }

    Get.to(MainScreen());
  }

  void _loadProjects() async {
    final directory = await getApplicationDocumentsDirectory();
    var file = File("${directory.path}/$PROJECTS_LIST_FILE_NAME");
    var projectsList = (await file.readAsString()).trim().split("\n");
    for (var path in projectsList) {
      final projectXml = await File("$path/$PROJECT_FILE_NAME").readAsString();
      final name = XmlDocument.parse(projectXml).rootElement.getAttribute("name");
      final project = Project(name: name!, path: path);
      appFruits.projects.add(project);
    }

    setState(() {});
  }
}
