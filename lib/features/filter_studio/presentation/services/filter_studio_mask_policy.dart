import 'package:lama/features/filter_studio/domain/entities/filter_params.dart';

bool shouldUseSubjectMask(FilterParams params, {required bool hasPersonMask}) {
  if (!hasPersonMask) {
    return false;
  }

  return params.subjectMaskEnabled || params.replaceBackground || params.ghost;
}

bool shouldReplaceBackground(
  FilterParams params, {
  required bool hasPersonMask,
}) {
  return params.replaceBackground &&
      shouldUseSubjectMask(params, hasPersonMask: hasPersonMask);
}
