import 'dart:typed_data';

class StudioImageAsset {
  final String path;
  final Uint8List bytes;

  const StudioImageAsset({
    required this.path,
    required this.bytes,
  });
}
