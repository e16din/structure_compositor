import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/state_manager.dart';
import 'package:structure_compositor/box/data_classes.dart';

import '../../box/app_utils.dart';
import '../../box/widget_utils.dart';
import 'fruits.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/rendering.dart';

// import 'package:tensorflow_native/tensorflowlite.dart';

class AreasEditorWidget extends StatefulWidget {
  const AreasEditorWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return AreasEditorState();
  }
}

class AreasEditorState extends State<AreasEditorWidget> {
  List? _recognitions;

  // Load the TFLite model and labels
  // loadModel() async {
  //   await Tflite.loadModel(
  //     model: 'assets/ssd_mobilenet.tflite',
  //     labels: 'assets/ssd_mobilenet.txt',
  //   );
  // }

  // @override
  // void initState() {
  //   super.initState();
  //   loadModel();
  // }

  // @override
  // void dispose() {
  //   Tflite.close();
  //   super.dispose();
  // }

  // Draw bounding boxes around the detected objects
  Widget drawBoxes() {
    if (_recognitions == null) return Container();
    double factorX = 200;
    double factorY = 200;
    Color blue = Color.fromRGBO(37, 213, 253, 1.0);
    return Stack(
      children: _recognitions!.map((re) {
        return Positioned(
          left: re["rect"]["x"] * factorX,
          top: re["rect"]["y"] * factorY,
          width: re["rect"]["w"] * factorX,
          height: re["rect"]["h"] * factorY,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: blue,
                width: 3,
              ),
            ),
            child: Text(
              "${re["detectedClass"]} ${(re["confidenceInClass"] * 100)
                  .toStringAsFixed(0)}%",
              style: TextStyle(
                background: Paint()
                  ..color = blue,
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    var layout = appFruits.selectedProject!.selectedLayout;
    if (layout?.layoutBytes != null) {
      // photo = null;
      if (layout != null) {
        List<int> values = layout.layoutBytes!.buffer.asUint8List();

        if (photo == null) {
          photo = img.decodeImage(values)!;
          parent.clear();

          // var copy = img.copyResize(photo!, width: 256, height: (photo!.height * (256.0 / photo!.width)).toInt());
          // savePhoto(copy);
          // bradleyBinarization(copy);

          // findAndOutlineText(copy, true, 6);

          // var pointerX = photo!.width ~/ 2;
          // int elementHex = -1;
          // int x1 = 0;
          // int y1 = 0;
          // for (int y = 0; y < photo!.height; y++) {
          //   var nextHex = _getColorInt(photo!, pointerX, y);
          //   if (elementHex < 0) {
          //     elementHex = nextHex;
          //   } else {
          //     if (nextHex == elementHex) {
          //       continue;
          //     } else {
          //       int deltaX = 4;
          //       int deltaY = 4;
          //
          //       int x1 = pointerX - deltaX;
          //       int y1 = y;
          //       int x2 = pointerX + deltaX;
          //       int y2 = y + deltaY;
          //       // updateElementRect(x1, y1, x2, y2, elementHex);
          //     }
          //   }
          // }

          // var nextElementId = _nextElementId();
          // var color = Colors.red;
          // var element = CodeElement(
          //     getLayoutBundle()!.elements.length, nextElementId, color);
          // element.area = AreaBundle(
          //     Rect.fromLTRB(minX.toDouble(), minY.toDouble(), maxX.toDouble(),
          //         maxY.toDouble()),
          //     color,
          //     nextElementId);
          // getLayoutBundle()!.elements.add(element);

          // findAndOutlineText(copy, false, 6);

          // findObjects(photo!);
          // splitAndOutline(photo!);
          // img.save
          // layout.layoutBytes = photo!.getBytes(format: img.Format.abgr);
        }
      }

      //photo!.getBytes(format: img.Format.abgr);
      print("setImageBytes");

      // determineHorizontalLines();
      // determineHorizontalLines();

      // Tflite.detectObjectOnBinary(
      //   binary: layout!.layoutBytes!,
      //   model: 'SSDMobileNet',
      //   numResultsPerClass: 1,
      //   threshold: 0.4,
      // ).then((recognitions) {
      //   setState(() {
      //     _recognitions = recognitions;
      //   });
      // });

      return Container(
        width: SCREEN_IMAGE_WIDTH,
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.only(left: 64),
                  width: 240,
                  child: TextFormField(
                    autofocus: true,
                    key: Key("${layout?.name.toString()}"),
                    initialValue: layout?.name,
                    decoration: const InputDecoration(labelText: "Layout Name"),
                    onChanged: (text) {
                      EasyDebounce.debounce(
                          'Layout Name', const Duration(milliseconds: 500), () {
                        layout?.name = text;
                        areasEditorFruit.onSelectedLayoutChanged.call(layout);
                      });
                    },
                  ),
                ),
                Container(
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(top: 17, right: 8),
                  child: Row(
                    children: [
                      const Text("isLauncher"),
                      Checkbox(
                          value: (layout as ScreenBundle).isLauncher,
                          onChanged: layout.isLauncher
                              ? null
                              : (checked) {
                            for (var layout
                            in appFruits.selectedProject!.layouts) {
                              (layout as ScreenBundle).isLauncher = false;
                            }
                            layout.isLauncher = checked!;

                            areasEditorFruit.onSelectedLayoutChanged.call(
                                appFruits
                                    .selectedProject?.selectedLayout);
                          }),
                    ],
                  ),
                ),
                Container(
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(top: 12, right: 96),
                  child: IconButton(
                      onPressed: () {
                        appFruits.selectedProject?.layouts.remove(layout);
                        appFruits.selectedProject?.selectedLayout =
                            appFruits.selectedProject!.layouts.firstOrNull;

                        if (layout.isLauncher &&
                            appFruits.selectedProject?.selectedLayout != null) {
                          (appFruits.selectedProject?.selectedLayout
                          as ScreenBundle)
                              .isLauncher = true;
                        }

                        areasEditorFruit.onSelectedLayoutChanged
                            .call(appFruits.selectedProject?.selectedLayout);
                      },
                      icon: const Icon(Icons.delete_forever)),
                )
              ],
            ),
            Container(
              padding: const EdgeInsets.only(top: 64, bottom: 24),
              child: Stack(fit: StackFit.expand, children: [
                Image.memory(layout.layoutBytes!, fit: BoxFit.contain),
                Listener(
                    onPointerDown: _onPointerDown,
                    onPointerUp: _onPointerUp,
                    onPointerMove: _onPointerMove,
                    child: MouseRegion(
                        cursor: SystemMouseCursors.precise,
                        child: CustomPaint(
                          painter: ActionsPainter(
                              getLayoutBundle()!, areasEditorFruit.lastArea),
                        )))
              ]),
            ),
            Container(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                alignment: Alignment.topRight,
                child: _buildLayoutsListWidget()),
            drawBoxes()
          ],
        ),
      );
    } else {
      return Container(width: SCREEN_IMAGE_WIDTH, color: Colors.white);
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      areasEditorFruit.lastArea = AreaBundle(
          Rect.fromPoints(event.localPosition, event.localPosition),
          getNextColor(getLayoutBundle()?.elements.length),
          _nextElementId());
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    setState(() {
      // var element = getLayoutBundle()!.getActiveElement();
      areasEditorFruit.lastArea?.rect = Rect.fromPoints(
          areasEditorFruit.lastArea!.rect.topLeft, event.localPosition);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    var rect = areasEditorFruit.lastArea!.rect;
    if (rect.left.floor() == rect.right.floor() &&
        rect.top.floor() == rect.bottom.floor()) {
      setState(() {
        areasEditorFruit.resetData();
      });
    } else {
      areasEditorFruit.onNewArea.call(areasEditorFruit.lastArea!);
    }
  }

  String _nextElementId() => 'element${getLayoutBundle()!.elements.length + 1}';

  Widget _buildLayoutsListWidget() {
    return Container(
      width: 96,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.indigoAccent, width: 1),
          color: Colors.indigoAccent.withOpacity(0.21)),
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 21),
      child: ListView.separated(
        separatorBuilder: (context, index) =>
        const Divider(
          height: 1,
          indent: 16,
          endIndent: 24,
        ),
        scrollDirection: Axis.vertical,
        itemCount: appFruits.selectedProject!.layouts.length,
        itemBuilder: (BuildContext context, int index) {
          var layout = appFruits.selectedProject!.layouts[index];

          var borderColor = appFruits.selectedProject?.selectedLayout == layout
              ? Colors.indigoAccent
              : Colors.transparent;
          return Container(
              decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 4)),
              width: 50,
              child: Stack(
                children: [
                  InkWell(
                    child:
                    Image.memory(layout.layoutBytes!, fit: BoxFit.contain),
                    onTap: () {
                      appFruits.selectedProject?.selectedLayout = layout;
                      areasEditorFruit.onSelectedLayoutChanged.call(layout);
                    },
                  ),
                ],
              ));
        },
      ),
    );
  }

  img.Image? photo;
  Map<int, Color> linesMap = {};

  // image lib uses uses KML color format, convert #AABBGGRR to regular #AARRGGBB
  int abgrToArgb(int argbColor) {
    int r = (argbColor >> 16) & 0xFF;
    int b = argbColor & 0xFF;
    return (argbColor & 0xFF00FF00) | (b << 16) | r;
  }

  Color _getColor(img.Image photo, int x, int y) {
    int pixel32 = photo.getPixel(x, y);
    int hex = abgrToArgb(pixel32);

    return Color(hex);
  }

  int _getColorInt(img.Image photo, int x, int y) {
    int pixel32 = photo.getPixel(x, y);
    int hex = abgrToArgb(pixel32);

    return hex;
  }

  String _toHex(Color color) {
    return '#${color.value.toRadixString(16)}';
  }

  void determineHorizontalLines() async {
    linesMap.clear();

    // photo!.
    debugPrint("determineHorizontalLines!");
    Color top = await _getColor(photo!, photo!.width ~/ 2, 1);
    Color left = await _getColor(photo!, 1, photo!.height ~/ 2);
    Color right = await _getColor(photo!, 1, photo!.height - 1);
    Color bottom =
    await _getColor(photo!, photo!.width ~/ 2, photo!.height - 1);
    List<String> bgColors = [
      _toHex(top),
      _toHex(left),
      _toHex(right),
      _toHex(bottom)
    ];

    for (int y = 0; y < photo!.height; y += 8) {
      int counter = 0;
      var xDelta = 32;
      for (int x = 0; x < photo!.width; x += xDelta) {
        String c = _toHex(await _getColor(photo!, x, y));

        // for (var hex in bgColors) {

        if (bgColors[3] == c) counter += 1;
        // else debugPrint("hex: $hex | c: $c");

        // }
      }

      // if (counter >= photo!.width~/xDelta * 0.80) {
      debugPrint("counter: $counter");
      debugPrint("line at y: $y");
      // linesMap[y] = Colors.green;//hex.toColor();
      // }
    }
  }

  // Функция для бинаризации изображения Брэдли
  Future<int> bradleyBinarization(img.Image image, {double t = 0.15}) async {
    // Получаем ширину и высоту изображения
    int width = image.width;
    int height = image.height;

    // Создаем массив для хранения интегрального изображения
    List<int> integralImage = List.filled(width * height, 0);

    // Вычисляем интегральное изображение по формуле:
    // S(x, y) = s(x, y - 1) + s(x - 1, y) - s(x - 1, y - 1) + i(x, y)
    // где S(x, y) - значение интегрального изображения в точке (x, y),
    // s(x, y) - сумма всех пикселей в прямоугольнике от (0, 0) до (x, y),
    // i(x, y) - значение исходного изображения в точке (x, y)
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        int index = y * width + x;
        int pixel = image.getPixel(x, y);
        int gray = img.getLuminance(pixel); // Получаем яркость пикселя
        int sum = gray; // Начальное значение суммы равно яркости пикселя
        if (x > 0) {
          sum +=
          integralImage[index - 1]; // Прибавляем сумму в предыдущем столбце
        }
        if (y > 0) {
          sum += integralImage[
          index - width]; // Прибавляем сумму в предыдущей строке
        }
        if (x > 0 && y > 0) {
          sum -= integralImage[
          index - width - 1]; // Вычитаем сумму в предыдущем углу
        }
        integralImage[index] =
            sum; // Сохраняем сумму в интегральном изображении
      }
    }

    // Определяем размер окна для вычисления среднего значения яркости
    int windowSize = min(width, height) ~/ 8;

    // Проходим по всем пикселям исходного изображения
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        int index = y * width + x;

        // Определяем границы окна вокруг текущего пикселя
        int x1 = max(0, x - windowSize ~/ 2);
        int x2 = min(width - 1, x + windowSize ~/ 2);
        int y1 = max(0, y - windowSize ~/ 2);
        int y2 = min(height - 1, y + windowSize ~/ 2);

        // Вычисляем сумму яркости в окне по формуле:
        // S(A, B, C, D) = S(D) - S(B) - S(C) + S(A)
        // где S(A, B, C, D) - сумма яркости в прямоугольнике от A до D,
        // S(P) - значение интегрального изображения в точке P,
        // A = (x1 - 1, y1 - 1), B = (x2, y1 - 1), C = (x1 - 1, y2), D = (x2, y2)
        int count = (x2 - x1 + 1) * (y2 - y1 + 1); // Количество пикселей в окне
        int sum = integralImage[
        y2 * width + x2]; // Начальное значение суммы равно S(D)
        if (x1 > 0) {
          sum -= integralImage[y2 * width + x1 - 1]; // Вычитаем S(C)
        }
        if (y1 > 0) {
          sum -= integralImage[(y1 - 1) * width + x2]; // Вычитаем S(B)
        }
        if (x1 > 0 && y1 > 0) {
          sum += integralImage[(y1 - 1) * width + x1 - 1]; // Прибавляем S(A)
        }

        // Вычисляем среднее значение яркости в окне
        int mean = sum ~/ count;

        // Сравниваем яркость текущего пикселя с средним значением, умноженным на порог t
        // Если яркость пикселя больше, то делаем его белым, иначе - черным
        int pixel = image.getPixel(x, y);
        int gray = img.getLuminance(pixel);
        if (gray > mean * (1.0 + t)) {
          image.setPixel(x, y, 0xFF000000); // Черный цвет
        } else {
          image.setPixel(x, y, 0xFFFFFFFF); // Белый цвет
        }
      }
    }

    return 1;
  }

  // todo: белый это цвет фона(один из цветов), черный это любой отличный от фона, и искать

  void savePhoto(img.Image image) async {
    final png = img.encodePng(image);
    // Write the PNG formatted data to a file.
    await File('image121314.png').writeAsBytes(png);
  }

  // ====

// Функция для поиска текста на бинарной картинке и обводки его прямоугольниками
  void findAndOutlineText(img.Image image, bool filled, int threshold) {
    // Получаем ширину и высоту изображения
    int width = image.width;
    int height = image.height;

    // Создаем массив для хранения меток объектов
    List<int> labels = List.filled(width * height, 0);

    // Создаем переменную для хранения текущей метки
    int currentLabel = 0;

    // Проходим по всем пикселям изображения
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        int index = y * width + x;
        int pixel = image.getPixel(x, y);
        int gray = img.getLuminance(pixel); // Получаем яркость пикселя

        // Проверяем, является ли пиксель черным (принадлежит объекту)
        if (gray == 0) {
          // Проверяем, есть ли у пикселя соседи с уже присвоенными метками
          List<int> neighbors = []; // Список для хранения меток соседей
          if (x > 0 && labels[index - 1] > 0) {
            // Если есть сосед слева с меткой, то добавляем ее в список
            neighbors.add(labels[index - 1]);
          }
          if (y > 0 && labels[index - width] > 0) {
            // Если есть сосед сверху с меткой, то добавляем ее в список
            neighbors.add(labels[index - width]);
          }
          if (x > 0 && y > 0 && labels[index - width - 1] > 0) {
            // Если есть сосед по диагонали слева сверху с меткой, то добавляем ее в список
            neighbors.add(labels[index - width - 1]);
          }
          if (x < width - 1 && y > 0 && labels[index - width + 1] > 0) {
            // Если есть сосед по диагонали справа сверху с меткой, то добавляем ее в список
            neighbors.add(labels[index - width + 1]);
          }

          if (neighbors.isEmpty) {
            // Если у пикселя нет соседей с метками, то присваиваем ему новую метку
            currentLabel++;
            labels[index] = currentLabel;
          } else {
            // Если у пикселя есть соседи с метками, то присваиваем ему минимальную из них
            int minLabel = neighbors.reduce(min);
            labels[index] = minLabel;

            // Объединяем все метки соседей в одну группу, используя алгоритм объединения-поиска
            for (int i = 0; i < neighbors.length; i++) {
              for (int j = i + 1; j < neighbors.length; j++) {
                union(neighbors[i],
                    neighbors[j]); // Объединяем две метки в одну группу
              }
            }
          }
        }
      }
    }

    // Проходим по всем пикселям изображения еще раз и заменяем метки на их представителей
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        int index = y * width + x;
        if (labels[index] > 0) {
          labels[index] = find(
              labels[index]); // Находим представителя группы для данной метки
        }
      }
    }

    // Создаем словарь для хранения координат прямоугольников для каждой метки
    Map<int, List<int>> rectangles = {};

    // Проходим по всем пикселям изображения и обновляем координаты прямоугольников для каждой метки
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        int index = y * width + x;
        int label = labels[index];
        if (label > 0) {
          // Если метка существует, то проверяем, есть ли для нее уже прямоугольник в словаре
          if (rectangles.containsKey(label)) {
            // Если есть, то обновляем его координаты, если нужно
            List<int> rect = rectangles[
            label]!; // Получаем список из четырех координат: [x1, y1, x2, y2]
            rect[0] = min(rect[0], x); // x1 - минимальная координата по x
            rect[1] = min(rect[1], y); // y1 - минимальная координата по y
            rect[2] = max(rect[2], x); // x2 - максимальная координата по x
            rect[3] = max(rect[3], y); // y2 - максимальная координата по y
          } else {
            // Если нет, то создаем новый прямоугольник с начальными координатами, равными текущему пикселю
            rectangles[label] = [x, y, x, y];
          }
        }
      }
    }

    // Определяем цвет для обводки прямоугольников
    int redColor = 0xFFFF0000; // Красный цвет

    // Выводим результаты разбиения на экран
    print("Картинка разбита на ${rectangles.length} прямоугольников:");
    for (int label in rectangles.keys) {
      List<int> rect = rectangles[
      label]!; // Получаем список из четырех координат: [x1, y1, x2, y2]
      print(
          "Прямоугольник с меткой $label имеет координаты: (${rect[0]}, ${rect[1]}) - (${rect[2]}, ${rect[3]})");
      // Рисуем прямоугольник на изображении красным цветом
      // drawRect(image, rect[0], rect[1], rect[2], rect[3], redColor);
    }

    outlineCloseRectangles(image, rectangles.values.toList(), filled,
        threshold: threshold);

    savePhoto(image);
  }

// Функция для объединения двух меток в одну группу
  void union(int a, int b) {
    // Находим представителей групп для каждой метки
    int rootA = find(a);
    int rootB = find(b);

    // Если представители разные, то объединяем их в одну группу
    if (rootA != rootB) {
      parent[rootA] =
          rootB; // Делаем одного из представителей родителем другого
    }
  }

// Функция для поиска представителя группы для данной метки
  int find(int a) {
    // Если метка не имеет родителя, то она сама является представителем
    if (!parent.containsKey(a)) {
      return a;
    }

    // Иначе рекурсивно ищем представителя для родителя
    return find(parent[a]!);
  }

// Словарь для хранения родителей меток
  Map<int, int> parent = {};

// Функция для рисования прямоугольника на изображении заданным цветом
  void drawRect(img.Image image, int x1, int y1, int x2, int y2, int color,
      bool filled) {
    // Рисуем горизонтальные линии сверху и снизу прямоугольника
    if (filled) {
      img.fillRect(image, x1, y1, x2, y2, 0xFF000000);
    } else {
      img.drawRect(image, x1, y1, x2, y2, color);
    }
    // for (int x = x1; x <= x2; x++) {
    //   image.setPixel(x, y1, color);
    //   image.setPixel(x, y2, color);
    // }
    //
    // // Рисуем вертикальные линии слева и справа прямоугольника
    // for (int y = y1; y <= y2; y++) {
    //   image.setPixel(x1, y, color);
    //   image.setPixel(x2, y, color);
    // }
  }

  // Функция для обводки близких прямоугольников общим прямоугольником
  void outlineCloseRectangles(img.Image image, List<List<int>> rectangles,
      bool filled,
      {int threshold = 6}) {
    // Определяем цвет для обводки прямоугольников
    int redColor = 0xFFFF0000; // Красный цвет

    // threshold - Определяем пороговое расстояние между прямоугольниками для их объединения

    // Создаем список для хранения групп прямоугольников
    List<List<List<int>>> groups = [];

    // Проходим по всем прямоугольникам в списке
    for (List<int> rect in rectangles) {
      // Проверяем, есть ли у прямоугольника близкие соседи среди других прямоугольников по горизонтали
      List<int> neighbors = []; // Список для хранения индексов соседей
      for (int i = 0; i < rectangles.length; i++) {
        if (rectangles[i] != rect) {
          // Если это не тот же самый прямоугольник, то проверяем расстояние между ними
          List<int> otherRect = rectangles[
          i]; // Получаем список из четырех координат: [x1, y1, x2, y2]
          int dx = max(
              0,
              max(rect[0], otherRect[0]) -
                  min(rect[2], otherRect[2])); // Расстояние по x
          int dy = max(
              0,
              max(rect[1], otherRect[1]) -
                  min(rect[3], otherRect[3])); // Расстояние по y
          int distance = sqrt(dx * dx + dy * dy)
              .round(); // Расстояние между прямоугольниками

          if (distance <= threshold) {
            // Если расстояние меньше или равно порогу, то добавляем индекс в список соседей
            neighbors.add(i);
          }
        }
      }

      if (neighbors.isEmpty) {
        // Если у прямоугольника нет соседей, то создаем новую группу с одним прямоугольником
        groups.add([rect]);
      } else {
        // Если у прямоугольника есть соседи, то проверяем, есть ли он уже в какой-то группе
        bool found = false;
        for (List<List<int>> group in groups) {
          if (group.contains(rect)) {
            // Если есть, то добавляем всех его соседей в эту же группу
            for (int i in neighbors) {
              group.add(rectangles[i]);
            }
            found = true;
            break;
          }
        }
        if (!found) {
          // Если нет, то создаем новую группу с прямоугольником и его соседями
          groups.add([rect]..addAll(neighbors.map((i) => rectangles[i])));
        }
      }
    }

    // Выводим результаты обводки на экран
    print(
        "На картинке найдено ${groups.length} групп близких прямоугольников:");
    for (List<List<int>> group in groups) {
      print("Группа состоит из ${group.length} прямоугольников:");
      for (List<int> rect in group) {
        print(
            "Прямоугольник с координатами: (${rect[0]}, ${rect[1]}) - (${rect[2]}, ${rect[3]})");
      }
      // Находим минимальный и максимальный x и y для группы
      int minX = group.map((rect) => rect[0]).reduce(min);
      int minY = group.map((rect) => rect[1]).reduce(min);
      int maxX = group.map((rect) => rect[2]).reduce(max);
      int maxY = group.map((rect) => rect[3]).reduce(max);
      // Рисуем общий прямоугольник для группы на изображении красным цветом
      drawRect(
          image,
          minX,
          minY,
          maxX,
          maxY,
          redColor,
          filled);

      var nextElementId = _nextElementId();
      var color = Colors.red;
      var element =
      CodeElement(getLayoutBundle()!.elements.length, nextElementId, color);
      element.area = AreaBundle(
          Rect.fromLTRB(minX.toDouble(), minY.toDouble(), maxX.toDouble(),
              maxY.toDouble()),
          color,
          nextElementId);
      getLayoutBundle()!.elements.add(element);
    }
  }

  // void updateElementRect(
  //     int x1,
  //     int y1,
  //     int x2,
  //     int y2,
  //     int elementHex
  //     ) {
  //   int deltaX = 4;
  //   int deltaY = 4;
  //
  //   // check top line
  //   int counterX1X2 = 0;
  //   for (int ix = x1; ix < photo!.width && ix < x2; ix++) {
  //     var checkHex = _getColorInt(photo!, ix, y1);
  //     if (elementHex != checkHex) {
  //       counterX1X2 += 1;
  //     }
  //   }
  //
  //
  //   if (y + deltaY < photo!.height) {
  //     int counter = 0;
  //     for (int ix = pointerX - deltaX; ix < photo!.width &&
  //         ix < pointerX + deltaX; ix++) {
  //       var checkHex = _getColorInt(photo!, pointerX + 3, ix);
  //       if (elementHex != checkHex) {
  //         counter += 1;
  //       }
  //     }
  //
  //     if (counter > 0) {
  //
  //     }
  //   }
  // }
}
