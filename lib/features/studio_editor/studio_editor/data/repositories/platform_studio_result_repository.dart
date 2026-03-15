import 'dart:typed_data';

import 'package:lama/features/studio_editor/data/services/studio_result_service.dart';
import 'package:lama/features/studio_editor/domain/repositories/studio_result_repository.dart';

class PlatformStudioResultRepository implements StudioResultRepository {
  final StudioResultService service;

  const PlatformStudioResultRepository(this.service);

  @override
  Future<bool> save(Uint8List bytes) {
    return service.save(bytes);
  }

  @override
  Future<bool> share(Uint8List bytes, {String text = 'Studio Pro'}) {
    return service.share(bytes, text: text);
  }
}
