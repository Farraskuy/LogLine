import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  OcrService({TextRecognizer? textRecognizer})
    : _textRecognizer =
          textRecognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _textRecognizer;

  Future<OcrResult> recognizeFromInputImage(InputImage image) async {
    final recognizedText = await _textRecognizer.processImage(image);
    return OcrResult(
      text: recognizedText.text,
      blocks: recognizedText.blocks
          .map(
            (block) => OcrTextBlock(
              text: block.text,
              left: block.boundingBox.left,
              top: block.boundingBox.top,
              width: block.boundingBox.width,
              height: block.boundingBox.height,
            ),
          )
          .toList(),
    );
  }

  Future<OcrResult> recognizeFromFilePath(String path) {
    return recognizeFromInputImage(InputImage.fromFilePath(path));
  }

  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}

class OcrResult {
  const OcrResult({required this.text, required this.blocks});

  final String text;
  final List<OcrTextBlock> blocks;

  bool get hasText => text.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
    'text': text,
    'blocks': blocks.map((block) => block.toJson()).toList(),
  };
}

class OcrTextBlock {
  const OcrTextBlock({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final String text;
  final double left;
  final double top;
  final double width;
  final double height;

  Map<String, dynamic> toJson() => {
    'text': text,
    'left': left,
    'top': top,
    'width': width,
    'height': height,
  };
}
