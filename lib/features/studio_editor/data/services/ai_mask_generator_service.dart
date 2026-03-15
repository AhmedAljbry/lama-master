import 'package:flutter/foundation.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';

import 'package:lama/features/studio_editor/data/services/ai_mask_result.dart';

class AiMaskGeneratorService {
  const AiMaskGeneratorService();

  Future<AiMaskResult?> generate(String imagePath) async {
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

      return buildAiMaskResult(
        width: mask.width,
        height: mask.height,
        confidences: mask.confidences,
      );
    } catch (error) {
      debugPrint('[AI Mask Error] $error');
      return null;
    }
  }
}
