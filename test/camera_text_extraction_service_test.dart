import 'package:flutter_test/flutter_test.dart';
import 'package:logline/services/camera_text_extraction_service.dart';
import 'package:logline/services/yolo_text_detector_service.dart';

void main() {
  test('CameraTextExtractionResult membuat markdown OCR untuk note', () {
    const result = CameraTextExtractionResult(
      imagePath: 'sample.jpg',
      text: 'Invoice A-104\nTekanan 18 bar',
      ocrBlocks: [],
      detectedRegions: [],
      usedYolo: false,
      usedFallbackFullImage: true,
      statusMessage: 'fallback',
    );

    expect(result.hasText, isTrue);
    expect(result.toMarkdown(), contains('## Hasil OCR'));
    expect(result.toMarkdown(), contains('Invoice A-104'));
  });

  test(
    'YoloTextDetectorService fallback aman saat model asset belum tersedia',
    () async {
      final service = YoloTextDetectorService(
        modelAssetPath: 'assets/models/missing_text_detector.tflite',
      );

      final loaded = await service.load();

      expect(loaded, isFalse);
      expect(service.isAvailable, isFalse);
      expect(service.loadError, isNotNull);
    },
  );
}
