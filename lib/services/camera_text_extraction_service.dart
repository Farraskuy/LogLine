import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
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
    final selectedCamera = camera ?? cameras.first;
    final controller = CameraController(
      selectedCamera,
      resolution,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await controller.initialize();
    _controller = controller;
    await _yoloTextDetectorService.load();
    return controller;
  }

  Future<OcrResult> extractTextFromImagePath(String imagePath) async {
    // YOLO should run on the image bytes once the trained model output is wired.
    // OCR currently processes the full image; crop-by-detection can be added in this service.
    return _ocrService.recognizeFromInputImage(
      InputImage.fromFilePath(imagePath),
    );
  }

  Future<void> startRealtimeTextDetection({
    required void Function(OcrResult result) onText,
    void Function(Object error)? onError,
    Duration throttle = const Duration(milliseconds: 700),
  }) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('Camera must be initialized before starting detection.');
    }

    var isBusy = false;
    var lastRun = DateTime.fromMillisecondsSinceEpoch(0);

    await controller.startImageStream((CameraImage image) async {
      final now = DateTime.now();
      if (isBusy || now.difference(lastRun) < throttle) return;
      isBusy = true;
      lastRun = now;

      try {
        // TODO: Convert CameraImage to bytes, run YOLO text-region detection,
        // crop the detected regions, then pass each crop into ML Kit OCR.
        // This method is intentionally scaffolded so UI can be connected early.
      } catch (error) {
        onError?.call(error);
      } finally {
        isBusy = false;
      }
    });
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
  }
}

class CameraPermissionDeniedException implements Exception {
  @override
  String toString() => 'Camera permission was denied.';
}
