import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';

class WidgetToImageCapture {
  static Future<ui.Image?> captureWidget(
      GlobalKey key, {
        double pixelRatio = 1.0,
      }) async {
    try {
      final RenderRepaintBoundary boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;

      //if (!boundary.isRepainted) { await Future.delayed(const Duration(milliseconds: 100)); }

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      return image;
    } catch (e) {
      print('Error capturing widget: $e');
      return null;
    }
  }

  static Future<Uint8List?> captureWidgetAsPNG(
      GlobalKey key, {
        double pixelRatio = 1.0,
      }) async {
    final image = await captureWidget(key, pixelRatio: pixelRatio);
    if (image != null) {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    }
    return null;
  }
}

class GameOfLifeImageCapture extends StatefulWidget {
  final Widget contentWidget; // e.g., Your mole sprite or game result

  const GameOfLifeImageCapture({
    required this.contentWidget,
    super.key,
  });

  @override
  State<GameOfLifeImageCapture> createState() =>
      _GameOfLifeImageCaptureState();
}

class _GameOfLifeImageCaptureState extends State<GameOfLifeImageCapture> {
  final GlobalKey _captureKey = GlobalKey();
  ui.Image? _capturedImage;
  bool _isCapturing = false;

  Future<ui.Image?> captureForGameOfLife({
    int width = 100,
    int height = 100,
  }) async {
    setState(() => _isCapturing = true);

    try {
      // Wait for widget to be laid out
      await Future.delayed(const Duration(milliseconds: 200));

      final image = await WidgetToImageCapture.captureWidget(
        _captureKey,
        pixelRatio: 2.0,
      );

      setState(() {
        _capturedImage = image;
        _isCapturing = false;
      });

      return image;
    } catch (e) {
      print('Failed to capture: $e');
      setState(() => _isCapturing = false);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RepaintBoundary(
          key: _captureKey,
          child: SizedBox(
            width: 200,
            height: 200,
            child: widget.contentWidget,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isCapturing ? null : captureForGameOfLife,
          child: _isCapturing
              ? const CircularProgressIndicator()
              : const Text('Capture for Game of Life'),
        ),
        if (_capturedImage != null) ...[
          const SizedBox(height: 16),
          const Text('Ready for Game of Life animation!'),
          const SizedBox(height: 8),
          SizedBox(
            width: 150,
            height: 150,
            child: RawImage(image: _capturedImage),
          ),
        ],
      ],
    );
  }
}
