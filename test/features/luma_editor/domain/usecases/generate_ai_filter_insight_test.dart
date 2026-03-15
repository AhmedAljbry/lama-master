import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lama/features/luma_editor/domain/entities/ai_filter_insight.dart';
import 'package:lama/features/luma_editor/domain/entities/auto_enhance_profile.dart';
import 'package:lama/features/luma_editor/domain/entities/filter_item.dart';
import 'package:lama/features/luma_editor/domain/repositories/editor_analysis_repository.dart';
import 'package:lama/features/luma_editor/domain/usecases/generate_ai_filter_insight.dart';

void main() {
  test('keeps only available AI recommendations and fills fallbacks', () async {
    final usecase = GenerateAiFilterInsight(_FakeAnalysisRepository());
    final filters = [
      const FilterItem(
        id: 'base_original',
        name: 'Original',
        matrix: [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0],
        indicatorColor: Colors.white,
      ),
      const FilterItem(
        id: 'base_cinema_2',
        name: 'Cinema 2',
        matrix: [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0],
        indicatorColor: Colors.teal,
      ),
      const FilterItem(
        id: 'pro_015',
        name: 'Pro 015',
        matrix: [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0],
        indicatorColor: Colors.blue,
      ),
    ];

    final insight = await usecase(Uint8List(0), filters, 'en');

    expect(
      insight.recommendedFilterIds,
      ['base_cinema_2', 'base_original', 'pro_015'],
    );
  });
}

class _FakeAnalysisRepository implements EditorAnalysisRepository {
  @override
  Future<AutoEnhanceProfile> analyzeAutoEnhance(Uint8List bytes) async {
    return const AutoEnhanceProfile(
      brightness: 0,
      contrast: 0,
      saturation: 0,
      warmth: 0,
      fade: 0,
    );
  }

  @override
  Future<AiFilterInsight> generateCreativeInsight(
    Uint8List bytes,
    String languageCode,
  ) async {
    return const AiFilterInsight(
      headline: 'headline',
      summary: 'summary',
      sceneLabel: 'scene',
      moodLabel: 'mood',
      suggestedName: 'style',
      recommendedFilterIds: ['missing_filter', 'base_cinema_2'],
      intensity: 0.8,
      brightness: 0.1,
      contrast: 0.1,
      saturation: 0.1,
      warmth: 0.1,
      fade: 0.1,
    );
  }
}
