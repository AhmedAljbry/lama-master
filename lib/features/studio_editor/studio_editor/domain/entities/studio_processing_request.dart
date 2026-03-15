import 'dart:typed_data';

import 'package:lama/features/studio_editor/domain/entities/theft_config.dart';

class StudioProcessingRequest {
  final Uint8List targetBytes;
  final Uint8List refBytes;
  final String? targetPath;
  final String? refPath;
  final Uint8List? manualMaskBytes;
  final bool useAi;
  final TheftConfig config;

  const StudioProcessingRequest({
    required this.targetBytes,
    required this.refBytes,
    required this.config,
    this.targetPath,
    this.refPath,
    this.manualMaskBytes,
    this.useAi = false,
  });
}
