import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ocr_service.dart';
import 'yolo_text_detector_service.dart';

class CameraTextExtractionService {
  CameraTextExtractionService({
    OcrService? ocrService,
    YoloTextDetectorService? yoloTextDetectorService,
  }) : _ocrService = ocrService ?? OcrService(),
       _yoloTextDetectorService =
           yoloTextDetectorService ?? YoloTextDetectorService();

  final OcrService _ocrService;
  final YoloTextDetectorService _yoloTextDetectorService;

  CameraController? _controller;
  CameraDescription? _activeCamera;

  CameraController? get controller => _controller;

  Future<List<CameraDescription>> availableDeviceCameras() {
    return availableCameras();
  }

  Future<CameraController> initializeCamera({
    CameraDescription? camera,
    ResolutionPreset resolution = ResolutionPreset.high,
  }) async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      throw CameraPermissionDeniedException();
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) throw CameraUnavailableException();

    final selectedCamera =
        camera ??
        cameras.firstWhere(
          (item) => item.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
    final controller = CameraController(
      selectedCamera,
      resolution,
      enableAudio: false,
      imageFormatGroup: Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.yuv420,
    );

    await controller.initialize();
    _controller = controller;
    _activeCamera = selectedCamera;
    await _yoloTextDetectorService.load();
    return controller;
  }

  Future<CameraTextExtractionResult> extractTextFromImagePath(
    String imagePath,
  ) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final regions = await _yoloTextDetectorService.detectTextRegions(
      imageBytes,
    );
    if (regions.isEmpty) {
      final result = await _ocrService.recognizeFromInputImage(
        InputImage.fromFilePath(imagePath),
      );
      return CameraTextExtractionResult(
        imagePath: imagePath,
        text: result.text,
        ocrBlocks: result.blocks,
        detectedRegions: const [],
        usedYolo: _yoloTextDetectorService.isAvailable,
        usedFallbackFullImage: true,
        isRealtime: false,
        statusMessage: _yoloTextDetectorService.isAvailable
            ? 'YOLO tidak menemukan area teks, OCR memakai full image.'
            : 'Model YOLO belum tersedia, OCR memakai full image.',
      );
    }

    final cropPaths = await _cropDetectedRegions(imageBytes, regions);
    final blockResults = <OcrResult>[];
    for (final path in cropPaths) {
      final result = await _ocrService.recognizeFromFilePath(path);
      if (result.hasText) blockResults.add(result);
    }

    final text = blockResults
        .map((item) => item.text.trim())
        .where((item) => item.isNotEmpty)
        .join('\n');
    final blocks = blockResults.expand((item) => item.blocks).toList();
    return CameraTextExtractionResult(
      imagePath: imagePath,
      text: text,
      ocrBlocks: blocks,
      detectedRegions: regions,
      usedYolo: true,
      usedFallbackFullImage: false,
      isRealtime: false,
      statusMessage: 'YOLO mendeteksi ${regions.length} area teks.',
    );
  }

  Future<List<String>> _cropDetectedRegions(
    Uint8List imageBytes,
    List<TextDetectionBox> regions,
  ) async {
    final source = img.decodeImage(imageBytes);
    if (source == null) return const [];
    final tempDir = await getTemporaryDirectory();
    final paths = <String>[];

    for (var i = 0; i < regions.length; i++) {
      final region = regions[i];
      final x = region.left.floor().clamp(0, source.width - 1);
      final y = region.top.floor().clamp(0, source.height - 1);
      final width = region.width.ceil().clamp(1, source.width - x);
      final height = region.height.ceil().clamp(1, source.height - y);
      final crop = img.copyCrop(
        source,
        x: x,
        y: y,
        width: width,
        height: height,
      );
      final path =
          '${tempDir.path}/logline_ocr_crop_${DateTime.now().microsecondsSinceEpoch}_$i.jpg';
      await File(path).writeAsBytes(img.encodeJpg(crop, quality: 92));
      paths.add(path);
    }
    return paths;
  }

  Future<void> startRealtimeTextDetection({
    required void Function(CameraTextExtractionResult result) onText,
    void Function(Object error)? onError,
    Duration throttle = const Duration(milliseconds: 1200),
  }) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('Camera must be initialized before starting detection.');
    }
    if (controller.value.isStreamingImages) return;

    var isBusy = false;
    var lastRun = DateTime.fromMillisecondsSinceEpoch(0);

    await controller.startImageStream((CameraImage image) async {
      final now = DateTime.now();
      if (isBusy || now.difference(lastRun) < throttle) return;
      isBusy = true;
      lastRun = now;

      try {
        final inputImage = _inputImageFromCameraImage(image);
        if (inputImage == null) return;
        final result = await _ocrService.recognizeFromInputImage(inputImage);
        onText(
          CameraTextExtractionResult(
            imagePath: '',
            text: result.text,
            ocrBlocks: result.blocks,
            detectedRegions: const [],
            usedYolo: false,
            usedFallbackFullImage: true,
            isRealtime: true,
            statusMessage: 'Realtime OCR memakai ML Kit dari stream kamera.',
          ),
        );
      } catch (error) {
        onError?.call(error);
      } finally {
        isBusy = false;
      }
    });
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _activeCamera;
    if (camera == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;

    final bytes = _cameraImageBytes(image);
    if (bytes == null) return null;

    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Uint8List? _cameraImageBytes(CameraImage image) {
    if (image.planes.isEmpty) return null;
    if (image.planes.length == 1) return image.planes.first.bytes;

    final bytes = WriteBuffer();
    for (final plane in image.planes) {
      bytes.putUint8List(plane.bytes);
    }
    return bytes.done().buffer.asUint8List();
  }

  Future<void> stopRealtimeTextDetection() async {
    final controller = _controller;
    if (controller != null && controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
  }

  Future<void> dispose() async {
    await stopRealtimeTextDetection();
    await _controller?.dispose();
    await _ocrService.dispose();
    _yoloTextDetectorService.dispose();
    _controller = null;
    _activeCamera = null;
  }
}

class CameraTextExtractionResult {
  const CameraTextExtractionResult({
    required this.imagePath,
    required this.text,
    required this.ocrBlocks,
    required this.detectedRegions,
    required this.usedYolo,
    required this.usedFallbackFullImage,
    required this.statusMessage,
    this.isRealtime = false,
  });

  final String imagePath;
  final String text;
  final List<OcrTextBlock> ocrBlocks;
  final List<TextDetectionBox> detectedRegions;
  final bool usedYolo;
  final bool usedFallbackFullImage;
  final String statusMessage;
  final bool isRealtime;

  bool get hasText => text.trim().isNotEmpty;

  String toMarkdown() {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    return '## Hasil OCR\n\n```text\n$trimmed\n```';
  }
}

class CameraPermissionDeniedException implements Exception {
  @override
  String toString() => 'Camera permission was denied.';
}

class CameraUnavailableException implements Exception {
  @override
  String toString() => 'No camera is available on this device.';
}
