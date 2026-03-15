import 'dart:typed_data';

class StudioProcessingResult {
  final Uint8List processedBytes;
  final bool targetPersonDetected;

  const StudioProcessingResult({
    required this.processedBytes,
    required this.targetPersonDetected,
  });
}
