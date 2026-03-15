import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:lama/features/studio_editor/data/services/ai_mask_generator_service.dart';
import 'package:lama/features/studio_editor/data/services/studio_filter_engine_service.dart';
import 'package:lama/features/studio_editor/domain/entities/studio_processing_request.dart';
import 'package:lama/features/studio_editor/domain/entities/studio_processing_result.dart';
import 'package:lama/features/studio_editor/domain/repositories/studio_style_processing_repository.dart';

class IsolateStudioStyleProcessingRepository
    implements StudioStyleProcessingRepository {
  final AiMaskGeneratorService aiMaskGeneratorService;
  final StudioFilterEngineService filterEngineService;

  const IsolateStudioStyleProcessingRepository({
    required this.aiMaskGeneratorService,
    required this.filterEngineService,
  });

  @override
  Future<StudioProcessingResult> process(
      StudioProcessingRequest request) async {
    Uint8List? aiMaskBytes;
    Uint8List? refAiMaskBytes;
    var targetPersonDetected = false;
    var aiMaskApplied = false;
    final hasRefinedMask = request.manualMaskBytes != null;

    if (request.useAi) {
      if (request.targetPath != null && !hasRefinedMask) {
        final targetMask =
            await aiMaskGeneratorService.generate(request.targetPath!);
        targetPersonDetected = targetMask != null;

        if (targetMask?.isReliableForAutomation ?? false) {
          aiMaskApplied = true;
          aiMaskBytes =
              Uint8List.fromList(img.encodePng(targetMask!.maskImage));
        }
      }

      if (request.refPath != null) {
        final refMask = await aiMaskGeneratorService.generate(request.refPath!);
        if (refMask?.isReliableForAutomation ?? false) {
          refAiMaskBytes =
              Uint8List.fromList(img.encodePng(refMask!.maskImage));
        }
      }
    }

    final params = <String, dynamic>{
      'targetBytes': request.targetBytes,
      'refBytes': request.refBytes,
      'manualMaskBytes': request.manualMaskBytes,
      'aiMaskBytes': hasRefinedMask ? null : aiMaskBytes,
      'refAiMaskBytes': refAiMaskBytes,
      ...request.config.toMap(),
    };

    final processedBytes = await filterEngineService.process(params);
    return StudioProcessingResult(
      processedBytes: processedBytes,
      targetPersonDetected: targetPersonDetected,
      aiMaskApplied: aiMaskApplied,
    );
  }
}
