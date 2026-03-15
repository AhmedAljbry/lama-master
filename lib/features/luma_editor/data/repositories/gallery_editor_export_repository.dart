import 'dart:typed_data';

import 'package:lama/features/luma_editor/data/services/editor_result_saver_service.dart';
import 'package:lama/features/luma_editor/domain/repositories/editor_export_repository.dart';

class GalleryEditorExportRepository implements EditorExportRepository {
  final EditorResultSaverService saverService;

  const GalleryEditorExportRepository(this.saverService);

  @override
  Future<bool> savePng(Uint8List bytes, {required String name}) {
    return saverService.savePng(bytes, name: name);
  }
}
