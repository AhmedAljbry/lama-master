import 'dart:typed_data';

import 'package:lama/features/luma_editor/domain/entities/ai_filter_insight.dart';
import 'package:lama/features/luma_editor/domain/entities/auto_enhance_profile.dart';

abstract interface class EditorAnalysisRepository {
  Future<AutoEnhanceProfile> analyzeAutoEnhance(Uint8List bytes);

  Future<AiFilterInsight> generateCreativeInsight(
    Uint8List bytes,
    String languageCode,
  );
}
