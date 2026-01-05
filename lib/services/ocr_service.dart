import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class OcrService {
  Future<String> extractText(String imagePath) async {
    try {
      // Defaulting to English ('eng')
      // args empty for now
      String text = await FlutterTesseractOcr.extractText(
        imagePath,
        language: 'eng',
        args: {},
      );
      return text;
    } catch (e) {
      return "Error extracting text: $e";
    }
  }
}
