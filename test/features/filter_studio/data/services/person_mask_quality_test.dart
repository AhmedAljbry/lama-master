import 'package:flutter_test/flutter_test.dart';
import 'package:lama/features/filter_studio/data/services/person_mask_quality.dart';

void main() {
  group('buildPersonMaskQuality', () {
    test('accepts a centered high-confidence subject mask', () {
      const width = 10;
      const height = 10;
      final confidences = List<double>.filled(width * height, 0.05);

      for (var y = 2; y < 8; y++) {
        for (var x = 3; x < 7; x++) {
          confidences[(y * width) + x] = 0.92;
        }
      }

      final result = buildPersonMaskQuality(
        width: width,
        height: height,
        confidences: confidences,
      );

      expect(result, isNotNull);
      expect(result!.foregroundCoverage, greaterThan(0.20));
      expect(result.isReliable, isTrue);
    });

    test('rejects a whole-frame mask as unreliable', () {
      const width = 10;
      const height = 10;
      final confidences = List<double>.filled(width * height, 0.86);

      final result = buildPersonMaskQuality(
        width: width,
        height: height,
        confidences: confidences,
      );

      expect(result, isNotNull);
      expect(result!.foregroundCoverage, 1.0);
      expect(result.isReliable, isFalse);
    });
  });
}
