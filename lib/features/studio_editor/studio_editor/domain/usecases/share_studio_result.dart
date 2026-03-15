import 'dart:typed_data';

import 'package:lama/features/studio_editor/domain/repositories/studio_result_repository.dart';

class ShareStudioResult {
  final StudioResultRepository repository;

  const ShareStudioResult(this.repository);

  Future<bool> call(Uint8List bytes, {String text = 'Studio Pro'}) {
    return repository.share(bytes, text: text);
  }
}
