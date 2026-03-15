import 'dart:math' as math;

import 'package:image/image.dart' as img;

class AiMaskResult {
  final img.Image maskImage;
  final double meanConfidence;
  final double foregroundConfidence;
  final double foregroundCoverage;
  final double strongForegroundCoverage;
  final double edgeTouchRatio;

  const AiMaskResult({
    required this.maskImage,
    required this.meanConfidence,
    required this.foregroundConfidence,
    required this.foregroundCoverage,
    required this.strongForegroundCoverage,
    required this.edgeTouchRatio,
  });

  bool get isReliableForAutomation =>
      foregroundCoverage >= 0.04 &&
      foregroundCoverage <= 0.82 &&
      foregroundConfidence >= 0.72 &&
      strongForegroundCoverage >= 0.015 &&
      meanConfidence >= 0.12 &&
      edgeTouchRatio <= 0.68;
}

AiMaskResult? buildAiMaskResult({
  required int width,
  required int height,
  required List<double> confidences,
}) {
  final totalPixels = width * height;
  if (totalPixels == 0 || confidences.length < totalPixels) {
    return null;
  }

  const candidateThreshold = 0.58;
  const strongThreshold = 0.74;
  const softFloor = 0.34;
  const gamma = 1.35;

  final aiMask = img.Image(width: width, height: height);

  var index = 0;
  var candidateCount = 0;
  var strongCount = 0;
  var edgeTouchCount = 0;
  var confidenceSum = 0.0;
  var foregroundConfidenceSum = 0.0;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final confidence = confidences[index].clamp(0.0, 1.0);
      confidenceSum += confidence;

      if (confidence >= candidateThreshold) {
        candidateCount++;
        foregroundConfidenceSum += confidence;

        if (confidence >= strongThreshold) {
          strongCount++;
        }

        final touchesEdge =
            x == 0 || y == 0 || x == width - 1 || y == height - 1;
        if (touchesEdge) {
          edgeTouchCount++;
        }
      }

      final normalized = ((confidence - softFloor) / (1.0 - softFloor)).clamp(
        0.0,
        1.0,
      );
      final softened = math.pow(normalized, gamma).toDouble();
      final value = (softened * 255.0).round();
      aiMask.setPixelRgba(x, y, value, value, value, 255);
      index++;
    }
  }

  final foregroundCoverage = candidateCount / totalPixels;
  if (foregroundCoverage < 0.012 || strongCount == 0) {
    return null;
  }

  final meanConfidence = confidenceSum / totalPixels;
  final foregroundConfidence = foregroundConfidenceSum / candidateCount;
  if (foregroundConfidence < 0.56) {
    return null;
  }

  final strongForegroundCoverage = strongCount / totalPixels;
  final edgeTouchRatio = edgeTouchCount / candidateCount;

  return AiMaskResult(
    maskImage: img.gaussianBlur(aiMask, radius: 2),
    meanConfidence: meanConfidence,
    foregroundConfidence: foregroundConfidence,
    foregroundCoverage: foregroundCoverage,
    strongForegroundCoverage: strongForegroundCoverage,
    edgeTouchRatio: edgeTouchRatio,
  );
}
