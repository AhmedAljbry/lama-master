import 'package:lama/features/filter_studio/domain/entities/app_preset.dart';
import 'package:lama/features/filter_studio/domain/entities/filter_params.dart';

class FilterStudioAiInsight {
  final String headline;
  final String summary;
  final String sceneLabel;
  final String moodLabel;
  final String lightingLabel;
  final AppPreset recommendedPreset;
  final List<AppPreset> alternatePresets;
  final double confidence;
  final double subjectFocus;
  final double colorEnergy;
  final double dynamicRange;
  final FilterParams recipe;

  const FilterStudioAiInsight({
    required this.headline,
    required this.summary,
    required this.sceneLabel,
    required this.moodLabel,
    required this.lightingLabel,
    required this.recommendedPreset,
    required this.alternatePresets,
    required this.confidence,
    required this.subjectFocus,
    required this.colorEnergy,
    required this.dynamicRange,
    required this.recipe,
  });
}
