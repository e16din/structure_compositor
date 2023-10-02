// import 'dart:convert';
// import 'dart:ffi';

// import 'dart:ffi';
// import 'dart:math';
// import 'dart:typed_data';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:structure_compositor/screens/editor/files_list_widget.dart';

import '../../box/app_utils.dart';
import '../../box/data_classes.dart';
import '../../box/widget_utils.dart';
import 'fruits.dart';


String nextActionId() =>
    'action${getLayoutBundle()!.elements.mapMany((e) => e.receptors).mapMany((r) => r.actions).length + 1}';

String nextReceptorId() =>
    'receptor${getLayoutBundle()!.elements.mapMany((e) => e.receptors).length + 1}';

const double ID_WIDTH = 156;

class CodeActionFabric {
  static CodeReceptor createReceptor(ReceptorType type) {
    switch (type) {
    // Containers:
      case ReceptorType.doOnDataChanged:
        return CodeReceptor(
            id: nextActionId(), type: type, name: "doOnDataChanged");
      case ReceptorType.doOnClick:
        return CodeReceptor(id: nextActionId(), type: type, name: "doOnClick");
      case ReceptorType.doOnTextChanged:
        return CodeReceptor(
            id: nextActionId(), type: type, name: "doOnTextChanged");
      case ReceptorType.doOnSwitch:
        return CodeReceptor(id: nextActionId(), type: type, name: "doOnSwitch");
    }
  }

  static CodeAction createAction(ActionType type) {
    switch (type) {
      case ActionType.showText:
        return CodeAction(
            id: nextActionId(), type: ActionType.showText, name: "showText");
      case ActionType.showImage:
        return CodeAction(
            id: nextActionId(), type: ActionType.showImage, name: "showImage");
      case ActionType.showList:
        return CodeAction(
            id: nextActionId(), type: ActionType.showList, name: "showList")
          ..dataSourceValue = DataSourceValue(CodeDataSource());
      case ActionType.showGrid:
        return CodeAction(
            id: nextActionId(), type: ActionType.showGrid, name: "showGrid")
          ..dataSourceValue = DataSourceValue(CodeDataSource());
      case ActionType.updateDataSource:
        return CodeAction(
            id: nextActionId(),
            type: ActionType.updateDataSource,
            name: "updateDataSource")
          ..dataSourceValue = DataSourceValue(CodeDataSource());
      case ActionType.moveToNextScreen:
        return CodeAction(
            id: nextActionId(),
            type: ActionType.moveToNextScreen,
            name: "moveToNextScreen");
      case ActionType.moveToBackScreen:
        return CodeAction(
            id: nextActionId(),
            type: ActionType.moveToBackScreen,
            name: "moveToBackScreen");
      case ActionType.todo:
        return CodeAction(
            id: nextActionId(), type: ActionType.todo, name: "TODO()");
      case ActionType.nothing:
        return CodeAction(
            id: nextActionId(), type: ActionType.nothing, name: "nothing");
      case ActionType.note:
        return CodeAction(
            id: nextActionId(), type: ActionType.note, name: "// NOTE:");
    }
  }

  static List<ReceptorType> getReceptorTypes() {
    List<ReceptorType> result = [
      ReceptorType.doOnDataChanged,
      ReceptorType.doOnClick,
      ReceptorType.doOnSwitch,
      ReceptorType.doOnTextChanged,
    ];
    return result;
  }

  static List<ActionType> getActionTypes() {
    List<ActionType> result = [
      ActionType.showImage,
      ActionType.showList,
      ActionType.showGrid,
      ActionType.showText,
      ActionType.updateDataSource,
      ActionType.moveToNextScreen,
      ActionType.moveToBackScreen,
      ActionType.note,
      ActionType.nothing,
      ActionType.todo,
    ];
    return result;
  }
}

/// * Elements - actions editor elements & areas elements
/// * Files - code editor files
/// * Nodes - editor file nodes
// ERA: Element, Receptor, Action
// Code Example: element.receptor { action() }
class EraEditorWidget extends StatelessWidget {
  const EraEditorWidget({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return EraEditorPage();
  }
}

class EraEditorPage extends StatefulWidget {
  @override
  State<EraEditorPage> createState() => _EraEditorPageState();
}

class _EraEditorPageState extends State<EraEditorPage> {

  final _actionsEditorTypeSelectorState = [
    true, // Action 0
    false, // Prompts 1
  ];

  final _platformEditorTypeSelectorState = [
    false, // Settings 0
    false, // Logic 1
    false, // Layout 2
    false, // Data 3
  ];

  Map<String, LayoutBundle> nextScreensMap = {};

  String _nextElementId() => 'element${getLayoutBundle()!.elements.length + 1}';

  @override
  void initState() {
    super.initState();

    areasEditorFruit.onNewArea = (area) {
      var elementId = _nextElementId();
      var newElement = CodeElement(elementId)
        ..area = area
        ..id = elementId;

      _selectActions(newElement);
    };
  }

  @override
  void dispose() {
    EasyDebounce.cancelAll();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildActionsEditorWidget();
  }

  Widget _buildActionsEditorWidget() {
    var layout = getLayoutBundle();

    Widget content = Container(width: 640);
    var allReceptors = layout?.elements.mapMany((e) => e.receptors).toList();
    switch (actionsEditorFruit.selectedActionsEditMode) {
      case ActionsEditModeType.none:
        // do nothing
        break;
      case ActionsEditModeType.prompts:
        // do nothing
        break;
      case ActionsEditModeType.actions:
        content = Container(
          width: 640,
          padding: const EdgeInsets.only(bottom: 110),
          child: ListView.separated(
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              indent: 16,
              endIndent: 24,
            ),
            scrollDirection: Axis.vertical,
            itemCount: (layout != null ? allReceptors!.length : 0),
            itemBuilder: (BuildContext context, int index) {
              var receptor = allReceptors?[index];
              var element = layout!.elements.firstWhereOrNull((element) {
                return element.receptors.contains(receptor);
              })!;
              return _buildEditorReceptorListItem(element, receptor!);
            },
          ),
        );
        break;
    }

    if (eraEditorFruit.selectedPlatformEditMode !=
        PlatformEditModeType.none) {
      content = FilesListWidget();
    }

    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 40 + 16, top: 4, bottom: 2),
            child: ToggleButtons(
                direction: Axis.horizontal,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                selectedBorderColor: Colors.red[700],
                selectedColor: Colors.white,
                fillColor: Colors.red[200],
                color: Colors.red[400],
                constraints: const BoxConstraints(
                  minHeight: 28.0,
                  minWidth: 80.0,
                ),
                isSelected: _actionsEditorTypeSelectorState,
                onPressed: (int index) {
                  _onActionsEditorTabChanged(index);
                },
                children: _buildActionsEditorTabs()),
          ),
          Container(
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 16, top: 4, bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.only(right: 16),
                  child: FilledButton(
                      onPressed: () {
                        // todo: move generator code templates to files
                        Map<String, String> itemsMap = {};
                        for (var ruleName in appFruits.rulesMap.keys) {
                          itemsMap[ruleName] = ruleName;
                        }
                        showMenuDialog(
                            context, "Select Generation Rules", itemsMap,
                            (selected) {
                          setState(() {
                            appFruits.selectedProject!.selectedRule = selected;
                          });
                        });
                      },
                      child: Text(appFruits.selectedProject!.selectedRule)),
                ),
                ToggleButtons(
                    direction: Axis.horizontal,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    selectedBorderColor: Colors.green[700],
                    selectedColor: Colors.white,
                    fillColor: Colors.green[200],
                    color: Colors.green[400],
                    constraints: const BoxConstraints(
                      minHeight: 28.0,
                      minWidth: 80.0,
                    ),
                    isSelected: _platformEditorTypeSelectorState,
                    onPressed: (int index) {
                      _onPlatformEditorTabChanged(index);
                    },
                    children: _buildPlatformEditorTabs()),
                IconButton(
                    onPressed: () {
                      eraEditorFruit.onDownloadAllClick.call();
                    },
                    color: Colors.green,
                    icon: const Icon(Icons.get_app))
              ],
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  void _onPlatformEditorTabChanged(int index) {
    actionsEditorFruit.selectedActionsEditMode = ActionsEditModeType.none;
    for (int i = 0; i < _actionsEditorTypeSelectorState.length; i++) {
      _actionsEditorTypeSelectorState[i] = false;
    }

    setState(() {
      for (int i = 0; i < _platformEditorTypeSelectorState.length; i++) {
        _platformEditorTypeSelectorState[i] = i == index;
      }
      eraEditorFruit.selectedPlatformEditMode = PlatformEditModeType
          .values[
      _platformEditorTypeSelectorState.indexWhere((element) => element) +
          1];
      debugPrint(
          "selected: ${eraEditorFruit.selectedPlatformEditMode}");
    });
  }

  void _onActionsEditorTabChanged(int index) {
    eraEditorFruit.selectedPlatformEditMode =
        PlatformEditModeType.none;
    for (int i = 0; i < _platformEditorTypeSelectorState.length; i++) {
      _platformEditorTypeSelectorState[i] = false;
    }

    setState(() {
      for (int i = 0; i < _actionsEditorTypeSelectorState.length; i++) {
        _actionsEditorTypeSelectorState[i] = i == index;
      }
      actionsEditorFruit.selectedActionsEditMode = ActionsEditModeType.values[
      _actionsEditorTypeSelectorState.indexWhere((element) => element) + 1];
      debugPrint("selected: ${actionsEditorFruit.selectedActionsEditMode}");
    });
  }

  Widget _buildEditorReceptorListItem(
      CodeElement element, CodeReceptor receptor) {
    List<Widget> innerActionWidgets = [];
    for (var action in receptor.actions) {
      String innerActionName = "${action.name}()";

      var innerActionWidget = Container(
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.only(left: 16 + 64, top: 12, bottom: 4),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    innerActionName,
                    style: const TextStyle(fontSize: 18),
                  ),
                  Container(
                    alignment: Alignment.topRight,
                    // padding: const EdgeInsets.all(16),
                    child: IconButton(
                        onPressed: () {
                          setState(() {
                            receptor.actions.remove(action);
                            nextScreensMap.remove(action.id);
                          });
                        },
                        icon: const Icon(Icons.remove_circle)),
                  )
                ],
              ),
              _buildAdditionActionWidgets(
                  element, receptor, action, innerActionName)
            ],
          ));
      innerActionWidgets.add(innerActionWidget);
    }

    Map<String, ViewType> viewTypesMap = {};
    for (var viewType in element.viewTypes) {
      viewTypesMap[viewType.viewName] = viewType;
    }
    return InkWell(
      onHover: (focused) {
        if (focused) {
          setState(() {
            getLayoutBundle()!.activeElement = element;
            getLayoutBundle()!.activeReceptor = receptor;
          });
        }
      },

      hoverColor: Colors.white,
      // hoverColor,
      // highlightColor,
      focusColor: Colors.white,
      highlightColor: Colors.white,
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(color: element.area.color, width: 4)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                color: Colors.green.withOpacity(0.42),
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 12, bottom: 8),
                child: receptor != getLayoutBundle()!.activeReceptor
                    ? Container(
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    alignment: Alignment.topLeft,
                    child: Text("// Description: ${receptor.description}"))
                    : TextFormField(
                  key: Key("${receptor.id.toString()}.Description"),
                  initialValue: receptor.description,
                  textCapitalization: TextCapitalization.sentences,
                  decoration:
                  const InputDecoration(labelText: "// Description"),
                  onChanged: (text) {
                    EasyDebounce.debounce(
                        'Description', const Duration(milliseconds: 500),
                            () {
                          setState(() {
                            receptor.description = text;
                            eraEditorFruit.onStructureChanged.call(getLayoutBundle()!);
                          });
                        });
                  },
                )),
            Container(
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
                child: Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                        width: ID_WIDTH,
                        child: _elementIdWidget(element, receptor)),
                    Container(
                      child: OutlinedButton(
                          child: Text(element.selectedViewType.viewName),
                          onPressed: () {
                            showMenuDialog(
                                context, "Select View Type", viewTypesMap,
                                    (selected) {
                                  setState(() {
                                    element.selectedViewType = selected;
                                  });
                                });
                          }),
                    ),
                    Container(
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.all(8),
                      child: IconButton(
                          onPressed: () {
                            _selectActions(element);
                          },
                          icon: const Icon(Icons.add_box_rounded)),
                    ),
                    Container(
                        alignment: Alignment.topLeft,
                        padding:
                        const EdgeInsets.only(left: 4, top: 12, bottom: 4),
                        child: Text(
                          ".${receptor.name} {",
                          style: const TextStyle(fontSize: 18),
                        )),
                    Container(
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.all(16),
                      child: IconButton(
                          onPressed: () {
                            _onRemoveActionClick(element);
                          },
                          icon: const Icon(Icons.remove_circle)),
                    )
                  ],
                )),
            Column(
              children: innerActionWidgets,
            ),
            Container(
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
                child: const Text(
                  "}",
                  style: TextStyle(fontSize: 18),
                )),
          ],
        ),
      ),
      onTap: () {
        // appFruits.selectedProject!.selectedLayout = screenBundle;
        // onSetStateListener.call();
      },
    );
  }

  void _onRemoveActionClick(CodeElement element) {
    setState(() {
      var layout = getLayoutBundle();
      layout?.elements.remove(element);
      for (var action in element.receptors) {
        nextScreensMap.remove(action.id);
      }

      layout?.resetActiveElement();
      layout?.resetActiveAction();

      eraEditorFruit.onStructureChanged.call(getLayoutBundle()!);
    });
  }

  Widget _elementIdWidget(CodeElement element, CodeReceptor receptor) {
    final Widget result;
    if (getLayoutBundle()!.activeReceptor == receptor) {
      result = TextFormField(
        key: Key("${element.id}.${receptor.id}"),
        initialValue: element.id,
        onChanged: (text) {
          EasyDebounce.debounce('ElementId', const Duration(milliseconds: 500),
                  () {
                setState(() {
                  element.id = text;
                  eraEditorFruit.onStructureChanged.call(getLayoutBundle()!);
                });
              });
        },
      );
    } else {
      result = Text(element.id);
    }

    return result;
  }

  Widget _buildAdditionActionWidgets(CodeElement element, CodeReceptor receptor,
      CodeAction action, String actionName) {
    List<Widget> widgets = [];

    if (action.dataSourceValue != null) {
      widgets.add(Container(
        child: FilledButton(
            onPressed: () {}, child: Text("${element.id}DataSource")),
      ));
    }

    if (action.type == ActionType.moveToNextScreen) {
      var screenName = nextScreensMap[action.id]?.name;
      screenName ??= "Select Screen";

      Map<String, ScreenBundle> itemsMap = {};
      for (var screen in appFruits.selectedProject!.screens) {
        itemsMap[screen.layouts.first.name] = screen;
      }

      widgets.add(Container(
        child: FilledButton(
            onPressed: () {
              showMenuDialog(context, "Select Screen:", itemsMap, (selected) {
                setState(() {
                  debugPrint("selected: ${action.id}");
                  nextScreensMap[action.id] = selected;
                  action.nextScreenValue = NextScreenValue(selected);
                  eraEditorFruit.onStructureChanged.call(getLayoutBundle()!);
                });
              });
            },
            child: Text(screenName)),
      ));
    }

    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets);
  }

  void _selectActions(CodeElement element) {
    Map<String, ReceptorType> receptorsMap = {};

    for (var receptorType in CodeActionFabric.getReceptorTypes()) {
      receptorsMap["${receptorType.name} { }"] = receptorType;
    }

    showMenuDialog(context, "Select action container:", receptorsMap,
            (selectedContainerType) {
          Map<String, ActionType> actionsMap = {};
          for (var actionType in CodeActionFabric.getActionTypes()) {
            actionsMap["${actionType.name}()"] = actionType;
          }
          showMenuDialog(context, "Select action:", actionsMap, (selectedType) {
            CodeAction newAction = CodeActionFabric.createAction(selectedType);
            newAction.id = nextActionId();
            var newReceptor = CodeActionFabric.createReceptor(selectedContainerType);
            _onActionTypeSelected(element, newReceptor, newAction);
          });
        });
  }

  void _onActionTypeSelected(CodeElement element /* may be reusable */,
      CodeReceptor newReceptor, CodeAction newAction) {
    setState(() {
      newReceptor.isActive = true;

      var layout = getLayoutBundle()!;
      layout.activeReceptor = newReceptor;

      if (newAction.dataSourceValue != null) {
        //todo: make copy of object
        newAction
          ..dataSourceValue?.dataSourceId =
              'dataSource${layout.elements.mapMany((e) => e.receptors).length + 1}'
          ..id = nextActionId();
      }
      newReceptor.actions.add(newAction);

      layout.activeElement = element;
      layout.activeElement?.receptors.add(newReceptor);
      if (!layout.elements.contains(element)) {
        layout.elements.add(element);
      }

      var viewTypes = _getViewTypesByReceptor(newReceptor);
      element.viewTypes = viewTypes;
      if (viewTypes.isNotEmpty) {
        element.selectedViewType = viewTypes.first;
      }

      // eraEditorFruit.onActionTypeSelected.call(element, newReceptor, newAction);
      eraEditorFruit.onStructureChanged.call(getLayoutBundle()!);

      areasEditorFruit.resetData();
    });
  }

  List<ViewType> _getViewTypesByReceptor(CodeReceptor receptor) {
    List<ViewType> result = [];
    switch (receptor.type) {
      case ReceptorType.doOnClick:
        result.add(ViewType.button);
        break;
      case ReceptorType.doOnTextChanged:
        result.add(ViewType.field);
        break;
      case ReceptorType.doOnSwitch:
        result.add(ViewType.switcher);
        break;
      default:
      //do nothing
        break;
    }

    for (var innerAction in receptor.actions) {
      switch (innerAction.type) {
        case ActionType.showText:
          result.add(ViewType.text);
          break;
        case ActionType.showImage:
          result.add(ViewType.image);
          break;
        case ActionType.showList:
          result.add(ViewType.list);
          break;
        case ActionType.showGrid:
          result.add(ViewType.grid);
          break;

        default:
          break;
      }
    }

    return result;
  }

  List<Widget> _buildActionsEditorTabs() {
    return [
      Text("Actions"),
      Text("Prompts"),
    ];
  }

  List<Widget> _buildPlatformEditorTabs() {
    return [
      Text("Settings"),
      Text("Logic"),
      Text("Layout"),
      Text("Data"),
    ];
  }
}
