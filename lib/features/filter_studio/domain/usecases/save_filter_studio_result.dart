import 'dart:typed_data';

import 'package:lama/features/filter_studio/domain/repositories/filter_studio_export_repository.dart';

class SaveFilterStudioResult {
  final FilterStudioExportRepository repository;

  const SaveFilterStudioResult(this.repository);

  Future<bool> call(Uint8List bytes) {
    return repository.savePng(
      bytes,
      name: 'pro_v3_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
