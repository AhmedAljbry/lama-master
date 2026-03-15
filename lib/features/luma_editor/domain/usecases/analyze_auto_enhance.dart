import 'dart:typed_data';

import 'package:lama/features/luma_editor/domain/entities/auto_enhance_profile.dart';
import 'package:lama/features/luma_editor/domain/repositories/editor_analysis_repository.dart';

class AnalyzeAutoEnhance {
  final EditorAnalysisRepository repository;

  const AnalyzeAutoEnhance(this.repository);

  Future<AutoEnhanceProfile> call(Uint8List bytes) {
    return repository.analyzeAutoEnhance(bytes);
  }
}
