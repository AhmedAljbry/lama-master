import 'dart:typed_data';

abstract interface class FilterStudioExportRepository {
  Future<bool> savePng(
    Uint8List bytes, {
    required String name,
  });
}
