import 'dart:typed_data';

import 'package:lama/features/luma_editor/data/services/editor_image_analysis_service.dart';
import 'package:lama/features/luma_editor/domain/entities/ai_filter_insight.dart';
import 'package:lama/features/luma_editor/domain/entities/auto_enhance_profile.dart';
import 'package:lama/features/luma_editor/domain/repositories/editor_analysis_repository.dart';

class ImagePackageEditorAnalysisRepository implements EditorAnalysisRepository {
  final EditorImageAnalysisService service;

  const ImagePackageEditorAnalysisRepository(this.service);

  @override
  Future<AutoEnhanceProfile> analyzeAutoEnhance(Uint8List bytes) {
    return service.analyzeAutoEnhance(bytes);
  }

  @override
  Future<AiFilterInsight> generateCreativeInsight(
    Uint8List bytes,
    String languageCode,
  ) {
    return service.generateCreativeInsight(bytes, languageCode);
  }
}
