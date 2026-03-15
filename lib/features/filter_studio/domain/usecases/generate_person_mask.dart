import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:lama/features/filter_studio/domain/repositories/person_mask_repository.dart';

class GeneratePersonMask {
  final PersonMaskRepository repository;

  const GeneratePersonMask(this.repository);

  Future<ui.Image?> call({
    required String filePath,
    required Uint8List originalBytes,
  }) {
    return repository.generatePersonMask(
      filePath: filePath,
      originalBytes: originalBytes,
    );
  }
}
