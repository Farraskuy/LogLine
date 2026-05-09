import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class YoloTextDetectorService {
  YoloTextDetectorService({
    this.modelAssetPath = 'assets/models/yolo_text_detector.tflite',
    this.inputSize = 640,
    this.confidenceThreshold = 0.35,
  });

  final String modelAssetPath;
  final int inputSize;
  final double confidenceThreshold;

  Interpreter? _interpreter;

  bool get isLoaded => _interpreter != null;

  Future<void> load() async {
    _interpreter ??= await Interpreter.fromAsset(modelAssetPath);
  }

  Future<List<TextDetectionBox>> detectTextRegions(Uint8List imageBytes) async {
    await load();

    final source = img.decodeImage(imageBytes);
    if (source == null) return const [];

    // TODO: Match preprocessing and output decoding to the YOLO model you train/export.
    // This placeholder keeps the service API ready while the final model contract is decided.
    final resized = img.copyResize(source, width: inputSize, height: inputSize);
    final input = _imageToFloat32(resized);
    final output = List.generate(1, (_) => List.filled(84 * 8400, 0.0));

    _interpreter!.run(input, output);

    return _decodeYoloOutput(
      output: output,
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

  List<TextDetectionBox> _decodeYoloOutput({
    required List<List<double>> output,
    required int originalWidth,
    required int originalHeight,
  }) {
    // Replace with model-specific YOLO decoding and NMS.
    return const [];
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
