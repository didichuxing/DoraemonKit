import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dokit/dokit.dart';
import 'package:dokit/kit/visual/visual.dart';
import 'package:dokit/ui/dokit_btn.dart';
import 'package:dokit/util/screen_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as images;

/// 无法获取到overlay的截图信息，如悬浮窗
class ColorPickerKit extends VisualKit {
  ColorPickerKit._privateConstructor() {
    _initPosition =
        ScreenUtil.instance.screenCenter - Offset(diameter / 2, diameter / 2);
    _position = ValueNotifier<Offset>(initPosition);
    _focusEntry = OverlayEntry(builder: (BuildContext context) {
      return ColorPickerWidget();
    });
    _infoEntry = OverlayEntry(builder: (BuildContext context) {
      return ColorPickerInfoWidget();
    });
    isShown = false;
  }
  static final ColorPickerKit _instance = ColorPickerKit._privateConstructor();
  static ColorPickerKit get instance => _instance;

  bool isShown;
  // 选中的颜色
  final ValueNotifier<Color> color = ValueNotifier<Color>(Colors.white);

  // 当前屏幕的截图快照
  final ValueNotifier<ui.Image> snapshot = ValueNotifier<ui.Image>(null);

  // 放大镜当前位置（左上角）
  ValueNotifier<Offset> _position;
  ValueNotifier<Offset> get position => _position;

  // 放大镜的直径
  final double diameter = 170;
  // 像素点放大的倍数
  final double scale = 8;
  Offset _initPosition;
  Offset get initPosition => _initPosition;

  OverlayEntry _focusEntry;
  OverlayEntry _infoEntry;

  @override
  String getIcon() {
    return 'images/dk_color_pick.png';
  }

  @override
  String getKitName() {
    return VisualKitName.KIT_COLOR_PICK;
  }

  @override
  void tabAction() {
    final DoKitBtnState state = DoKitBtn.doKitBtnKey.currentState;
    state.closeDebugPage();
    show(DoKitBtn.doKitBtnKey.currentContext, state.owner);
  }

  static void show(BuildContext context, OverlayEntry entrance) {
    _instance._show(context, entrance);
  }

  void _show(BuildContext context, OverlayEntry entrance) {
    if (isShown) {
      return;
    }
    isShown = true;
    doKitOverlayKey.currentState.insert(_focusEntry, below: entrance);
    doKitOverlayKey.currentState.insert(_infoEntry, below: _focusEntry);
  }

  static bool hide(BuildContext context) {
    return _instance._hide(context);
  }

  bool _hide(BuildContext context) {
    if (!isShown) {
      return false;
    }
    isShown = false;
    _focusEntry.remove();
    _infoEntry.remove();
    return true;
  }
}

class ColorPickerWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ColorPickerWidgetState();
}

class ColorPickerWidgetState extends State<ColorPickerWidget> {
  // 当前页面的截图快照
  images.Image _image;
  Future<images.Image> get image async {
    if (_image != null) {
      return _image;
    }
    await _updateImage();

    return _image;
  }

  // 是否做好显示颜色拾取器的准备
  bool _ready = false;

  Uint8List _imageUint8List;
  Future<Uint8List> get imageUint8List async {
    if (_imageUint8List != null) {
      return _imageUint8List;
    }

//    final start = DateTime.now();
    final RenderRepaintBoundary boundary =
        _findCurrentPageRepaintBoundaryRenderObject();
//    final finded = DateTime.now();
    final Uint8List imageData = await _boundaryToImageUint8List(boundary);
    _imageUint8List = imageData;
//    final end = DateTime.now();
//    print(
//        '获取repaintBoundary耗时：${finded.millisecondsSinceEpoch - start.millisecondsSinceEpoch}ms');
//    print(
//        '获取Uint8List耗时：${end.millisecondsSinceEpoch - finded.millisecondsSinceEpoch}ms');

    return _imageUint8List;
  }

  // 放大镜左上角的位置
  Offset get position => ColorPickerKit.instance.position.value;
  set position(Offset point) => ColorPickerKit.instance.position.value = point;

  // 手指和屏幕接触的初始位置
  Offset _touchPoint;
  // 手指和屏幕接触时，放大镜左上角的位置
  Offset _lastPosition = ColorPickerKit.instance.position.value;
  Offset get deltaOffset {
    if (_touchPoint == null || _lastPosition == null) {
      return Offset.zero;
    }
    return _touchPoint - _lastPosition;
  }

  // 放大镜的半径
  double get _radius => ColorPickerKit.instance.diameter / 2;

  // width * height 个格子的颜色值
//  Future<List<int>> get argbPixels async {
//    _position ??= ScreenUtil.instance.screenCenter - Offset(_radius, _radius);
//    final List<int> argbPixels =
//        await _findRectARGBPixels(_position, width, height);
//    _argbPixels = argbPixels;
//
//    return _argbPixels;
//  }

//  List<int> _argbPixels;

//  // BackdropFilter组件的变换矩阵
//  Matrix4 _matrix;

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateImage();
      _updateColor();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: position.dy,
      left: position.dx,
      child: Listener(
        onPointerDown: (PointerDownEvent event) {
          _touchPoint = event.position;
          _lastPosition = position;
        },
        onPointerMove: (PointerMoveEvent event) {
          position = event.position - deltaOffset;

          _updateColor();
        },
        child: Draggable<dynamic>(
          child: _buildMagnifier(context),
          feedback: _buildMagnifier(context),
          childWhenDragging: Container(),
          onDragStarted: () async {
            // 开始拖动时，重新获取截图快照
            await _updateImage();
          },
          onDragEnd: (DraggableDetails detail) async {
            final Offset point = detail.offset;
            double x = point.dx;
            double y = point.dy;

            final width = ScreenUtil.instance.screenWidth;
            final height = ScreenUtil.instance.screenHeight;

            bool refresh = false;
            if (x < -_radius) {
              x = -_radius;
              refresh = true;
            }
            if (x > width - _radius) {
              x = width - _radius;
              refresh = true;
            }
            if (y < -_radius) {
              y = -_radius;
              refresh = true;
            }
            if (y > height - _radius) {
              y = height - _radius;
              refresh = true;
            }

            if (refresh) {
              setState(() {
                position = Offset(x, y);
                _updateColor();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildMagnifier(BuildContext context) {
    return Offstage(
      offstage: !_ready,
      child: RepaintBoundary(
        child: ClipOval(
          child: Stack(
            alignment: Alignment.center,
            children: [
              ValueListenableBuilder<Offset>(
                valueListenable: ColorPickerKit.instance.position,
                builder: (BuildContext context, Offset value, Widget child) {
                  return ValueListenableBuilder<ui.Image>(
                    valueListenable: ColorPickerKit.instance.snapshot,
                    builder:
                        (BuildContext context, ui.Image value, Widget child) {
                      return CustomPaint(
                        painter: GridsPainter(),
                        size: Size.fromRadius(_radius),
                      );
                    },
                  );
                },
              ),
              CustomPaint(
                painter: MagnifierPainter(),
                size: Size.fromRadius(_radius),
              ),
            ],
          ),
        ),
      ),
    );
  }

//  Future<List<int>> _findRectARGBPixels(
//      Offset point, int width, int height) async {
//    final double dpr = ui.window.devicePixelRatio;
//    final dx = (point.dx * dpr).toInt();
//    final dy = (point.dy * dpr).toInt();
//
//    if (snapshot == null) {
//      await _updateSnapshot();
//    }
//
//    final List<int> argbPixels = List<int>(width * height);
//
//    for (int j = 0; j < height; j++) {
//      for (int i = 0; i < width; i++) {
//        final int x = dx + i;
//        final int y = dy + j;
//        assert(snapshot.boundsSafe(x, y), '超出范围');
//        final int abgrPixel = snapshot.getPixelSafe(x, y);
//        final int argbPixel = _abgrToArgb(abgrPixel);
//        argbPixels[j * width + i] = argbPixel;
//      }
//    }
//
//    return List.unmodifiable(argbPixels);
//  }

  Future<void> _updateImage() async {
    _imageUint8List = null;
    final imageData = await imageUint8List;
    if (imageData == null) {
      return;
    }
//    final startTimestamp = DateTime.now();
    _image = images.decodeImage(imageData);
//    final imagesImageTimestamp = DateTime.now();
    final codec = await ui.instantiateImageCodec(imageData);
    final info = await codec.getNextFrame();
//    final uiImageTimestamp = DateTime.now();
//    print(
//        '获取当前截图的images.Image耗时：${imagesImageTimestamp.millisecondsSinceEpoch - startTimestamp.millisecondsSinceEpoch}ms');
//    print(
//        '获取当前截图的ui.Image耗时：${uiImageTimestamp.millisecondsSinceEpoch - imagesImageTimestamp.millisecondsSinceEpoch}ms');
    ColorPickerKit.instance.snapshot.value = info.image;
    if (!_ready && mounted) {
      // 第一次获取Image会有耗时
      // 保证MagnifierPainter和GridsPainter同步出现
      setState(() {
        _ready = true;
      });
    }
  }

  Future<void> _updateColor() async {
    final double dpr = ui.window.devicePixelRatio;
    final center = (position + Offset(_radius, _radius)) * dpr;
    final images.Image image = await this.image;
    final abgrPixel = image.getPixelSafe(center.dx.toInt(), center.dy.toInt());
    final int argbPixel = _abgrToArgb(abgrPixel);
    ColorPickerKit.instance.color.value = Color(argbPixel);
  }

  RenderRepaintBoundary _findCurrentPageRepaintBoundaryRenderObject() {
    final owner = context.findRenderObject()?.owner;
    assert(owner != null, '当前正在build，无法获取当前页面的RepaintBoundary！');

    bool isRepaintBoundaryTo_ModalScopeStatus(String desc) {
      if (desc?.isEmpty ?? true) {
        return false;
      }
      final creators = desc.split(' ← ');
      const sampleCreators = [
        'RepaintBoundary',
        '_FocusMarker',
        'Semantics',
        'FocusScope',
        '_ActionsMarker',
        'Actions',
        'PageStorage',
        'Offstage',
        '_ModalScopeStatus',
      ];
      for (int i = 0; i < sampleCreators.length; i++) {
        if (creators.length < i + 1) {
          return false;
        }
        if (creators[i] != sampleCreators[i]) {
          return false;
        }
      }

      return true;
    }

    final ModalRoute<dynamic> rootRoute =
        ModalRoute.of<dynamic>(DoKitApp.appKey.currentContext);

    // 当前页面的_ModalScopeStatus下的RepaintBoundary的RenderObject
    RenderRepaintBoundary currentPageRepaintBoundary;
    void filter(Element element) {
      if (element is RenderObjectElement && element.renderObject is RenderBox) {
        final ModalRoute<dynamic> route = ModalRoute.of<dynamic>(element);
        if (route != null && route != rootRoute) {
          final RenderBox renderBox = element.renderObject as RenderBox;
          if (renderBox.hasSize &&
              renderBox.attached &&
              renderBox.isRepaintBoundary) {
            String desc;
            if (!kReleaseMode) {
              desc = element.renderObject.debugCreator.toString();
            }
            if (isRepaintBoundaryTo_ModalScopeStatus(desc)) {
              currentPageRepaintBoundary =
                  element.renderObject as RenderRepaintBoundary;
            }
          }
        }
      }
      element.visitChildren(filter);
    }

    DoKitApp.appKey.currentContext.visitChildElements(filter);

    return currentPageRepaintBoundary;
  }

  Future<Uint8List> _boundaryToImageUint8List(
      RenderRepaintBoundary boundary) async {
    if (boundary == null) {
      return null;
    }
    final double dpr = ui.window.devicePixelRatio;
    final ui.Image image = await boundary.toImage(pixelRatio: dpr);
    final ByteData byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData.buffer.asUint8List();

    return pngBytes;
  }

  /// Uint32 编码过的像素颜色值（#AABBGGRR)转为（#AARRGGBB）
  int _abgrToArgb(int argbColor) {
    int r = (argbColor >> 16) & 0xFF;
    int b = argbColor & 0xFF;
    return (argbColor & 0xFF00FF00) | (b << 16) | r;
  }

//  void _calculateMatrix4() {
//    if (_position == null) {
//      return;
//    }
//
//    setState(() {
//      final double newX = _position.dx;
//      final double newY = _position.dy;
//
//      final Matrix4 updatedMatrix = Matrix4.identity()
//        ..scale(_scale, _scale)
//        ..translate(-newX, -newY);
//
//      _matrix = updatedMatrix;
//    });
//  }

//  Widget _buildMagnifier(BuildContext context) {
//    return ClipOval(
//      child: BackdropFilter(
//        filter: ui.ImageFilter.matrix(_matrix.storage,
//            filterQuality: FilterQuality.high),
//        child: CustomPaint(
//          painter: ColorPickerPainter(),
//          size: Size.fromRadius(_radius),
//        ),
//      ),
//    );
//  }

}

class GridsPainter extends CustomPainter {
  GridsPainter();

//  final List<int> argbPixels;
  double get scale => ColorPickerKit.instance.scale;
  ui.Image get image => ColorPickerKit.instance.snapshot.value;
  Offset get position => ColorPickerKit.instance.position.value;
  double get radius => ColorPickerKit.instance.diameter / 2;

  // 水平方向上显示多少个颜色格子
  int get width => radius * 2 ~/ scale;

  // 竖直方向上显示多少个颜色格子
  int get height => radius * 2 ~/ scale;

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null || position == null) {
      return;
    }

    final paint = Paint();
    final double dpr = ui.window.devicePixelRatio;

    final center = (position + Offset(radius, radius)) * dpr;
    final left = center.dx - (width - 1) / 2;
    final top = center.dy - (height - 1) / 2;
    final srcRect =
        Rect.fromLTWH(left, top, width.toDouble(), height.toDouble());
    final distRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, srcRect, distRect, paint);

//    final paint = Paint()
//      ..isAntiAlias = true
//      ..strokeWidth = 2.0
//      ..style = PaintingStyle.fill
//      ..color = Color(argbPixels.first)
//      ..invertColors = false;

//    final double radius = gridSide / 2;
//    final int width = size.width ~/ gridSide;
//    final int height = size.height ~/ gridSide;
//
//    for (int j = 0; j < height; j++) {
//      for (int i = 0; i < width; i++) {
//        paint.color = Color(argbPixels[j * width + i]);
//        final double dx = (i + 1 / 2) * gridSide;
//        final double dy = (j + 1 / 2) * gridSide;
//        final Offset center = Offset(dx, dy);
//        final Rect rect = Rect.fromCircle(center: center, radius: radius);
//        canvas.drawRect(rect, paint);
//      }
//    }
  }

  @override
  bool shouldRepaint(GridsPainter old) => true;

  @override
  bool hitTest(ui.Offset position) => true;
}

class MagnifierPainter extends CustomPainter {
  MagnifierPainter();

  final double strokeWidth = 1;
  final Color color = Colors.black;
  double gridSide = ColorPickerKit.instance.scale;

  @override
  void paint(Canvas canvas, Size size) {
    assert(size.height == size.width);
    _drawCircle(canvas, size);
    _drawGrid(canvas, size);
  }

  void _drawCircle(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    canvas.drawCircle(
        size.center(const Offset(0, 0)), size.longestSide / 2, paint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final Paint crossPaint = Paint()
      ..strokeWidth = 1
      ..color = color;

    final List<Offset> points = [
      size.center(Offset(-gridSide / 2, -gridSide / 2)),
      size.center(Offset(gridSide / 2, -gridSide / 2)),
      size.center(Offset(gridSide / 2, gridSide / 2)),
      size.center(Offset(-gridSide / 2, gridSide / 2)),
      size.center(Offset(-gridSide / 2, -gridSide / 2)),
    ];
    canvas.drawPoints(ui.PointMode.polygon, points, crossPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (ColorPickerKit.instance.scale != gridSide) {
      gridSide = ColorPickerKit.instance.scale;
      return true;
    }
    return false;
  }

  @override
  bool hitTest(ui.Offset position) => true;
}

class ColorPickerInfoWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ColorPickerInfoWidgetState();
}

class _ColorPickerInfoWidgetState extends State<ColorPickerInfoWidget> {
  double top = infoWidgetTopMargin;
  Color color;
  String get colorDesc =>
      '#${color?.value?.toRadixString(16)?.padLeft(8, '0')?.toUpperCase() ?? ''}';

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: infoWidgetHorizontalMargin,
      top: top,
      child: Draggable<dynamic>(
          child: _buildInfoView(),
          feedback: _buildInfoView(),
          childWhenDragging: Container(),
          onDragEnd: (DraggableDetails detail) {
            final Offset offset = detail.offset;
            setState(() {
              top = offset.dy;
              if (top < 0) {
                top = 0;
              }
            });
          },
          onDraggableCanceled: (Velocity velocity, Offset offset) {}),
    );
  }

  Widget _buildInfoView() {
    final Size size = MediaQuery.of(context).size;
    return Container(
        width: size.width - 40,
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 20),
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xffeeeeee), width: 0.5),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(4, 4),
                blurRadius: 15,
                spreadRadius: 1,
              )
            ]),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            ValueListenableBuilder<Color>(
              valueListenable: ColorPickerKit.instance.color,
              builder: (BuildContext context, Color value, Widget child) {
                color = value;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      child: const SizedBox(height: 20, width: 20),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xffeeeeee), width: 0.5),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4)),
                          color: color),
                    ),
                    const SizedBox(width: 26),
                    Text(
                      colorDesc,
                      style: const TextStyle(
                        color: Color(0xff333333),
                        fontSize: 16,
                      ),
                    )
                  ],
                );
              },
            ),
            GestureDetector(
              child: Image.asset(
                'images/dokit_ic_close.png',
                package: DK_PACKAGE_NAME,
                height: 22,
                width: 22,
              ),
              onTap: () {
                ColorPickerKit.hide(context);
              },
            )
          ],
        ));
  }
}
