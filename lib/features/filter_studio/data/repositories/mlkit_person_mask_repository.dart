import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:lama/features/filter_studio/data/services/selfie_segmentation_service.dart';
import 'package:lama/features/filter_studio/domain/repositories/person_mask_repository.dart';

class MlkitPersonMaskRepository implements PersonMaskRepository {
  final SelfieSegmentationService service;

  MlkitPersonMaskRepository(this.service);

  @override
  Future<ui.Image?> generatePersonMask({
    required String filePath,
    required Uint8List originalBytes,
  }) {
    return service.generatePersonMask(
      filePath: filePath,
      originalBytes: originalBytes,
    );
  }

  @override
  Future<void> dispose() => service.dispose();
}
