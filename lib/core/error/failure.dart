sealed class Failure {
  final String message;
  final String code;
  final String? messageKey;
  final Map<String, Object?> meta;
  final bool isRetryable;

  const Failure(
      this.message, {
        required this.code,
        this.messageKey,
        this.meta = const {},
        this.isRetryable = false,
      });
}


class PermissionFailure extends Failure {
  const PermissionFailure(
      super.message, {
        String? messageKey,
        Map<String, Object?> meta = const {},
        bool isRetryable = true,
      }) : super(
    code: 'permission_denied',
    messageKey: messageKey ?? 'errors.permissionDenied',
    meta: meta,
    isRetryable: isRetryable,
  );
}

class UnknownFailure extends Failure {
  const UnknownFailure(
      super.message, {
        String? messageKey,
        Map<String, Object?> meta = const {},
        bool isRetryable = false,
      }) : super(
    code: 'unknown',
    messageKey: messageKey ?? 'errors.unknown',
    meta: meta,
    isRetryable: isRetryable,
  );
}

/// ---- Segmentation ----
class SegmentationFailure extends Failure {
  const SegmentationFailure(
      super.message, {
        String? messageKey,
        Map<String, Object?> meta = const {},
        bool isRetryable = true,
      }) : super(
    code: 'segmentation_failed',
    messageKey: messageKey ?? 'errors.segmentationFailed',
    meta: meta,
    isRetryable: isRetryable,
  );
}

/// ---- Save ----
class SaveFailure extends Failure {
  const SaveFailure(
      super.message, {
        String? messageKey,
        Map<String, Object?> meta = const {},
        bool isRetryable = true,
      }) : super(
    code: 'save_failed',
    messageKey: messageKey ?? 'errors.saveFailed',
    meta: meta,
    isRetryable: isRetryable,
  );
}



