import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class YoloTextDetectorService {
  YoloTextDetectorService({
    this.modelAssetPath = 'assets/models/yolo_text_detector.tflite',
    this.inputSize = 640,
    this.confidenceThreshold = 0.35,
    this.iouThreshold = 0.45,
  });

  final String modelAssetPath;
  final int inputSize;
  final double confidenceThreshold;
  final double iouThreshold;

  Interpreter? _interpreter;
  Object? _loadError;

  bool get isLoaded => _interpreter != null;
  bool get isAvailable => _interpreter != null && _loadError == null;
  Object? get loadError => _loadError;

  Future<bool> load() async {
    if (_interpreter != null) return true;
    try {
      _interpreter = await Interpreter.fromAsset(modelAssetPath);
      _loadError = null;
      return true;
    } catch (error) {
      _loadError = error;
      return false;
    }
  }

  Future<List<TextDetectionBox>> detectTextRegions(Uint8List imageBytes) async {
    final loaded = await load();
    if (!loaded || _interpreter == null) return const [];

    final source = img.decodeImage(imageBytes);
    if (source == null) return const [];

    final resized = img.copyResize(source, width: inputSize, height: inputSize);
    final input = _imageToFloat32(resized);
    final outputTensor = _interpreter!.getOutputTensor(0);
    final outputShape = outputTensor.shape;
    final output = _createOutputBuffer(outputShape);

    _interpreter!.run(input, output);

    return _decodeYoloOutput(
      output: output,
      shape: outputShape,
      originalWidth: source.width,
      originalHeight: source.height,
    );
  }

  Object _imageToFloat32(img.Image image) {
    final buffer = Float32List(1 * inputSize * inputSize * 3);
    var index = 0;
    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final pixel = image.getPixel(x, y);
        buffer[index++] = pixel.r / 255.0;
        buffer[index++] = pixel.g / 255.0;
        buffer[index++] = pixel.b / 255.0;
      }
    }
    return buffer.reshape([1, inputSize, inputSize, 3]);
  }

  Object _createOutputBuffer(List<int> shape) {
    if (shape.length == 3) {
      return List.generate(
        shape[0],
        (_) => List.generate(shape[1], (_) => List.filled(shape[2], 0.0)),
      );
    }
    if (shape.length == 2) {
      return List.generate(shape[0], (_) => List.filled(shape[1], 0.0));
    }
    return List.filled(shape.reduce((a, b) => a * b), 0.0);
  }

  List<TextDetectionBox> _decodeYoloOutput({
    required Object output,
    required List<int> shape,
    required int originalWidth,
    required int originalHeight,
  }) {
    final rows = _flattenDetections(output, shape);
    final boxes = <TextDetectionBox>[];

    for (final row in rows) {
      if (row.length < 5) continue;
      final cx = row[0];
      final cy = row[1];
      final w = row[2];
      final h = row[3];
      final confidence = row.sublist(4).reduce(math.max);
      if (confidence < confidenceThreshold) continue;

      final scaleX = originalWidth / inputSize;
      final scaleY = originalHeight / inputSize;
      final left = ((cx - w / 2) * scaleX).clamp(0.0, originalWidth.toDouble());
      final top = ((cy - h / 2) * scaleY).clamp(0.0, originalHeight.toDouble());
      final width = (w * scaleX).clamp(1.0, originalWidth - left);
      final height = (h * scaleY).clamp(1.0, originalHeight - top);

      boxes.add(
        TextDetectionBox(
          left: left,
          top: top,
          width: width,
          height: height,
          confidence: confidence,
        ),
      );
    }

    boxes.sort((a, b) => b.confidence.compareTo(a.confidence));
    return _nonMaxSuppression(boxes);
  }

  List<List<double>> _flattenDetections(Object output, List<int> shape) {
    if (output is List && output.isNotEmpty && output.first is List) {
      final batch = output.first;
      if (batch is List && batch.isNotEmpty && batch.first is List) {
        final matrix = batch.cast<List>();
        final rows = matrix
            .map((row) => row.map((v) => (v as num).toDouble()).toList())
            .toList();
        if (shape.length == 3 && shape[1] <= 16 && shape[2] > shape[1]) {
          return _transpose(rows);
        }
        return rows;
      }
    }
    return const [];
  }

  List<List<double>> _transpose(List<List<double>> matrix) {
    if (matrix.isEmpty) return const [];
    final rows = matrix.length;
    final cols = matrix.first.length;
    return List.generate(
      cols,
      (col) => List.generate(rows, (row) => matrix[row][col]),
    );
  }

  List<TextDetectionBox> _nonMaxSuppression(List<TextDetectionBox> boxes) {
    final selected = <TextDetectionBox>[];
    for (final box in boxes) {
      final overlaps = selected.any((kept) => _iou(box, kept) > iouThreshold);
      if (!overlaps) selected.add(box);
      if (selected.length >= 12) break;
    }
    return selected;
  }

  double _iou(TextDetectionBox a, TextDetectionBox b) {
    final x1 = math.max(a.left, b.left);
    final y1 = math.max(a.top, b.top);
    final x2 = math.min(a.left + a.width, b.left + b.width);
    final y2 = math.min(a.top + a.height, b.top + b.height);
    final intersection = math.max(0.0, x2 - x1) * math.max(0.0, y2 - y1);
    final union = a.width * a.height + b.width * b.height - intersection;
    return union <= 0 ? 0 : intersection / union;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

class TextDetectionBox {
  const TextDetectionBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.confidence,
    this.label = 'text',
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double confidence;
  final String label;

  Map<String, dynamic> toJson() => {
    'left': left,
    'top': top,
    'width': width,
    'height': height,
    'confidence': confidence,
    'label': label,
  };
}
