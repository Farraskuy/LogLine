import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownService {
  const MarkdownService();

  String appendOcrText({
    required String markdown,
    required String ocrText,
    String heading = 'OCR Result',
  }) {
    final normalized = ocrText.trim();
    if (normalized.isEmpty) return markdown;

    final block =
        '''

## $heading

```text
$normalized
```
''';
    return '$markdown$block';
  }

  MarkdownBody buildPreview(String markdown) {
    return MarkdownBody(data: markdown);
  }
}
