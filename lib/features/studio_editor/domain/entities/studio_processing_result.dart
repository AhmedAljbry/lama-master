import 'dart:typed_data';

class StudioProcessingResult {
  final Uint8List processedBytes;
  final bool targetPersonDetected;
  final bool aiMaskApplied;

  const StudioProcessingResult({
    required this.processedBytes,
    required this.targetPersonDetected,
    required this.aiMaskApplied,
  });
}
