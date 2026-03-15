import 'dart:typed_data';

import 'package:lama/features/luma_editor/domain/entities/ai_filter_insight.dart';
import 'package:lama/features/luma_editor/domain/entities/filter_item.dart';
import 'package:lama/features/luma_editor/domain/repositories/editor_analysis_repository.dart';

class GenerateAiFilterInsight {
  final EditorAnalysisRepository repository;

  const GenerateAiFilterInsight(this.repository);

  Future<AiFilterInsight> call(
    Uint8List bytes,
    List<FilterItem> filters,
    String languageCode,
  ) async {
    final insight = await repository.generateCreativeInsight(
      bytes,
      languageCode,
    );
    final availableIds = filters.map((filter) => filter.id).toSet();
    final fallbackIds = filters
        .where((filter) => !filter.isCustom)
        .map((filter) => filter.id)
        .take(4);

    final sanitizedIds = <String>[];
    for (final id in [...insight.recommendedFilterIds, ...fallbackIds]) {
      if (!availableIds.contains(id) || sanitizedIds.contains(id)) {
        continue;
      }
      sanitizedIds.add(id);
      if (sanitizedIds.length == 3) {
        break;
      }
    }

    return insight.copyWith(
      recommendedFilterIds: sanitizedIds,
    );
  }
}
