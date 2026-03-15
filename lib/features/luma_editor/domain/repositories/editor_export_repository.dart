import 'dart:typed_data';

abstract interface class EditorExportRepository {
  Future<bool> savePng(
    Uint8List bytes, {
    required String name,
  });
}
