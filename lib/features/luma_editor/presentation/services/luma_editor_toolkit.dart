import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:lama/core/error/error_reporter.dart';
import 'package:lama/core/performance/render_capture_service.dart';
import 'package:lama/features/luma_editor/domain/entities/ai_filter_insight.dart';
import 'package:lama/features/luma_editor/domain/entities/auto_enhance_profile.dart';
import 'package:lama/features/luma_editor/domain/entities/filter_item.dart';
import 'package:lama/features/luma_editor/domain/entities/random_filter_profile.dart';
import 'package:lama/features/luma_editor/domain/usecases/analyze_auto_enhance.dart';
import 'package:lama/features/luma_editor/domain/usecases/generate_ai_filter_insight.dart';
import 'package:lama/features/luma_editor/domain/usecases/generate_random_filter_profile.dart';
import 'package:lama/features/luma_editor/domain/usecases/save_editor_result.dart';

class LumaEditorToolkit {
  final AnalyzeAutoEnhance analyzeAutoEnhance;
  final GenerateAiFilterInsight generateAiFilterInsight;
  final GenerateRandomFilterProfile generateRandomFilterProfile;
  final SaveEditorResult saveEditorResult;
  final RenderCaptureService renderCaptureService;
  final ErrorReporter reporter;

  const LumaEditorToolkit({
    required this.analyzeAutoEnhance,
    required this.generateAiFilterInsight,
    required this.generateRandomFilterProfile,
    required this.saveEditorResult,
    required this.renderCaptureService,
    required this.reporter,
  });

  Future<AutoEnhanceProfile> analyze(Uint8List bytes) {
    return analyzeAutoEnhance(bytes);
  }

  Future<AiFilterInsight> generateCreativeInsight(
    Uint8List bytes,
    List<FilterItem> filters,
    String languageCode,
  ) {
    return generateAiFilterInsight(bytes, filters, languageCode);
  }

  RandomFilterProfile generateRandomProfile(List<FilterItem> filters) {
    return generateRandomFilterProfile(filters);
  }

  Future<bool> saveRenderedResult(GlobalKey repaintKey) async {
    final pngBytes = await renderCaptureService.capturePng(repaintKey);
    if (pngBytes == null || pngBytes.isEmpty) {
      return false;
    }
    return saveEditorResult(pngBytes);
  }
}
