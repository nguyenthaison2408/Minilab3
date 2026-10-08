import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/ocr_result_model.dart';
import 'receipt_parser.dart';

class OcrService {
  /// Recognize text from receipt image and parse fields using regex heuristics
  static Future<OcrResultModel> processReceiptImage(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await recognizer.processImage(inputImage);

      List<String> rawLines = [];
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          rawLines.add(line.text);
        }
      }

      final parsedResult = ReceiptParser.parse(
        recognizedText.text,
        rawLines,
      );

      return parsedResult;
    } catch (e) {
      debugPrint('Error during OCR processing: $e');
      // Return empty fallback so UI doesn't crash
      return OcrResultModel(
        rawText: '',
        detectedLines: [],
        confidenceNotes: 'Lỗi nhận diện: $e',
      );
    } finally {
      await recognizer.close();
    }
  }

  /// Cache receipt image permanently to application documents directory
  static Future<String> cacheReceiptImage(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(appDir.path, 'receipts'));
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
      final destinationPath = p.join(receiptsDir.path, fileName);

      final sourceFile = File(sourcePath);
      final savedFile = await sourceFile.copy(destinationPath);
      return savedFile.path;
    } catch (e) {
      debugPrint('Error caching receipt image: $e');
      return sourcePath;
    }
  }
}

