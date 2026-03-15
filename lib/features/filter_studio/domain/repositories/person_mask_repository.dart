import 'dart:typed_data';
import 'dart:ui' as ui;

abstract interface class PersonMaskRepository {
  Future<ui.Image?> generatePersonMask({
    required String filePath,
    required Uint8List originalBytes,
  });

  Future<void> dispose();
}
