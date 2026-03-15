import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:lama/features/filter_studio/data/services/person_mask_quality.dart';

class SelfieSegmentationService {
  final SelfieSegmenter _segmenter;

  SelfieSegmentationService({SelfieSegmenter? segmenter})
      : _segmenter = segmenter ?? SelfieSegmenter(mode: SegmenterMode.single);

  Future<ui.Image?> generatePersonMask({
    required String filePath,
    required Uint8List originalBytes,
  }) async {
    if (originalBytes.isEmpty) {
      return null;
    }

    final inputImage = InputImage.fromFilePath(filePath);
    final mask = await _segmenter.processImage(inputImage);
    if (mask == null) {
      return null;
    }

    final quality = buildPersonMaskQuality(
      width: mask.width,
      height: mask.height,
      confidences: mask.confidences,
    );
    if (quality == null || !quality.isReliable) {
      return null;
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      quality.rgbaPixels,
      mask.width,
      mask.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  Future<void> dispose() => _segmenter.close();
}
