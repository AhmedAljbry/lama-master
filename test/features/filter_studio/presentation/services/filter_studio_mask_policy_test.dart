import 'package:flutter_test/flutter_test.dart';
import 'package:lama/features/filter_studio/domain/entities/filter_params.dart';
import 'package:lama/features/filter_studio/presentation/services/filter_studio_mask_policy.dart';

void main() {
  group('filter studio mask policy', () {
    test('does not use subject mask for regular creative looks', () {
      expect(
        shouldUseSubjectMask(
          const FilterParams(blur: 4.0, aura: 0.4),
          hasPersonMask: true,
        ),
        isFalse,
      );
    });

    test('uses subject mask for explicit focus effects', () {
      expect(
        shouldUseSubjectMask(
          const FilterParams(subjectMaskEnabled: true, blur: 2.0),
          hasPersonMask: true,
        ),
        isTrue,
      );
    });

    test('requires a person mask before replacing background', () {
      expect(
        shouldReplaceBackground(
          const FilterParams(replaceBackground: true),
          hasPersonMask: false,
        ),
        isFalse,
      );
    });
  });
}
