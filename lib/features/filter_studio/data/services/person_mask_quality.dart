import 'dart:math' as math;
import 'dart:typed_data';

class PersonMaskQuality {
  final Uint8List rgbaPixels;
  final double meanConfidence;
  final double foregroundConfidence;
  final double foregroundCoverage;
  final double strongForegroundCoverage;
  final double edgeTouchRatio;

  const PersonMaskQuality({
    required this.rgbaPixels,
    required this.meanConfidence,
    required this.foregroundConfidence,
    required this.foregroundCoverage,
    required this.strongForegroundCoverage,
    required this.edgeTouchRatio,
  });

  bool get isReliable =>
      foregroundCoverage >= 0.04 &&
      foregroundCoverage <= 0.82 &&
      foregroundConfidence >= 0.72 &&
      strongForegroundCoverage >= 0.015 &&
      meanConfidence >= 0.12 &&
      edgeTouchRatio <= 0.68;
}

PersonMaskQuality? buildPersonMaskQuality({
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

  final maskPixels = Uint8List(totalPixels * 4);

  var candidateCount = 0;
  var strongCount = 0;
  var edgeTouchCount = 0;
  var confidenceSum = 0.0;
  var foregroundConfidenceSum = 0.0;

  for (var index = 0; index < totalPixels; index++) {
    final confidence = confidences[index].clamp(0.0, 1.0);
    confidenceSum += confidence;

    final x = index % width;
    final y = index ~/ width;

    if (confidence >= candidateThreshold) {
      candidateCount++;
      foregroundConfidenceSum += confidence;

      if (confidence >= strongThreshold) {
        strongCount++;
      }

      final touchesEdge = x == 0 || y == 0 || x == width - 1 || y == height - 1;
      if (touchesEdge) {
        edgeTouchCount++;
      }
    }

    final normalized =
        ((confidence - softFloor) / (1.0 - softFloor)).clamp(0.0, 1.0);
    final softenedAlpha =
        (math.pow(normalized, gamma).toDouble() * 255.0).round().clamp(0, 255);
    final pixelIndex = index * 4;
    maskPixels[pixelIndex] = 255;
    maskPixels[pixelIndex + 1] = 255;
    maskPixels[pixelIndex + 2] = 255;
    maskPixels[pixelIndex + 3] = softenedAlpha;
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

  return PersonMaskQuality(
    rgbaPixels: maskPixels,
    meanConfidence: meanConfidence,
    foregroundConfidence: foregroundConfidence,
    foregroundCoverage: foregroundCoverage,
    strongForegroundCoverage: strongCount / totalPixels,
    edgeTouchRatio: edgeTouchCount / candidateCount,
  );
}
