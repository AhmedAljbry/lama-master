import 'package:lama/features/filter_studio/presentation/models/filter_studio_style_preset.dart';

class FilterStudioAiStyleMatch {
  final FilterStudioStylePreset style;
  final double score;

  const FilterStudioAiStyleMatch({
    required this.style,
    required this.score,
  });
}
