import 'dart:typed_data';

import 'package:lama/features/luma_editor/domain/repositories/editor_export_repository.dart';

class SaveEditorResult {
  final EditorExportRepository repository;

  const SaveEditorResult(this.repository);

  Future<bool> call(Uint8List bytes) {
    return repository.savePng(
      bytes,
      name: 'luma_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
