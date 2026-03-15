import 'dart:typed_data';

import 'package:lama/features/studio_editor/domain/repositories/studio_result_repository.dart';

class SaveStudioResult {
  final StudioResultRepository repository;

  const SaveStudioResult(this.repository);

  Future<bool> call(Uint8List bytes) {
    return repository.save(bytes);
  }
}
