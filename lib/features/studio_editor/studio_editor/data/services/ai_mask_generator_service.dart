import 'package:flutter/foundation.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;

class AiMaskGeneratorService {
  const AiMaskGeneratorService();

  Future<img.Image?> generate(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final segmenter = SelfieSegmenter(
        mode: SegmenterMode.single,
        enableRawSizeMask: true,
      );

      final mask = await segmenter.processImage(inputImage);
      await segmenter.close();

      if (mask == null) {
        return null;
      }

      const threshold = 0.60;
      final aiMask = img.Image(width: mask.width, height: mask.height);
      final confidences = mask.confidences;
      var index = 0;

      for (var y = 0; y < mask.height; y++) {
        for (var x = 0; x < mask.width; x++) {
          final value = confidences[index] >= threshold ? 255 : 0;
          aiMask.setPixelRgba(x, y, value, value, value, 255);
          index++;
        }
      }

      return img.gaussianBlur(aiMask, radius: 2);
    } catch (error) {
      debugPrint('[AI Mask Error] $error');
      return null;
    }
  }
}
