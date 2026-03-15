import 'dart:typed_data';

import 'package:lama/core/error/error_reporter.dart';
import 'package:lama/features/studio_editor/domain/entities/studio_image_asset.dart';
import 'package:lama/features/studio_editor/domain/entities/studio_processing_request.dart';
import 'package:lama/features/studio_editor/domain/entities/studio_processing_result.dart';
import 'package:lama/features/studio_editor/domain/usecases/pick_studio_image.dart';
import 'package:lama/features/studio_editor/domain/usecases/process_studio_style.dart';
import 'package:lama/features/studio_editor/domain/usecases/save_studio_result.dart';
import 'package:lama/features/studio_editor/domain/usecases/share_studio_result.dart';

class StudioEditorToolkit {
  final PickStudioImage pickStudioImage;
  final ProcessStudioStyle processStudioStyle;
  final SaveStudioResult saveStudioResult;
  final ShareStudioResult shareStudioResult;
  final ErrorReporter reporter;

  const StudioEditorToolkit({
    required this.pickStudioImage,
    required this.processStudioStyle,
    required this.saveStudioResult,
    required this.shareStudioResult,
    required this.reporter,
  });

  Future<StudioImageAsset?> pickImage() {
    return pickStudioImage();
  }

  Future<StudioProcessingResult> process(StudioProcessingRequest request) {
    return processStudioStyle(request);
  }

  Future<bool> saveResult(Uint8List bytes) {
    return saveStudioResult(bytes);
  }

  Future<bool> shareResult(Uint8List bytes, {String text = 'Studio Pro'}) {
    return shareStudioResult(bytes, text: text);
  }
}
