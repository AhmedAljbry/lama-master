import 'package:flutter_test/flutter_test.dart';
import 'package:lama/features/filter_studio/domain/entities/filter_params.dart';
import 'package:lama/features/filter_studio/presentation/services/filter_params_calibrator.dart';

void main() {
  group('FilterParamsCalibrator', () {
    test('tones down artifact-prone regular looks without a subject mask', () {
      final safe = FilterParamsCalibrator.sanitize(
        const FilterParams(
          blur: 5.2,
          aura: 0.44,
          glitch: 1.2,
          grain: 0.22,
          scanlines: 0.20,
          replaceBackground: true,
          subjectMaskEnabled: true,
          ghost: true,
        ),
        hasPersonMask: false,
      );

      expect(safe.blur, lessThanOrEqualTo(1.2));
      expect(safe.aura, lessThanOrEqualTo(0.10));
      expect(safe.glitch, lessThanOrEqualTo(0.28));
      expect(safe.replaceBackground, isFalse);
      expect(safe.subjectMaskEnabled, isFalse);
      expect(safe.ghost, isFalse);
    });

    test('keeps focus effects stronger but still calibrated with a mask', () {
      final safe = FilterParamsCalibrator.sanitize(
        const FilterParams(
          blur: 6.0,
          aura: 0.40,
          subjectMaskEnabled: true,
        ),
        hasPersonMask: true,
      );

      expect(safe.blur, lessThanOrEqualTo(3.4));
      expect(safe.aura, lessThanOrEqualTo(0.24));
      expect(safe.subjectMaskEnabled, isTrue);
    });
  });
}
