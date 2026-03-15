import 'package:lama/features/filter_studio/domain/entities/app_preset.dart';
import 'package:lama/features/filter_studio/domain/entities/filter_params.dart';
import 'package:lama/features/filter_studio/domain/entities/filter_studio_ai_insight.dart';
import 'package:lama/features/filter_studio/presentation/models/filter_studio_ai_style_match.dart';
import 'package:lama/features/filter_studio/presentation/models/filter_studio_style_preset.dart';

class FilterStudioAiStyleMatcher {
  const FilterStudioAiStyleMatcher();

  static const Map<AppPreset, List<String>> _categoryAffinity =
      <AppPreset, List<String>>{
    AppPreset.original: <String>['editorial', 'creator', 'luxury'],
    AppPreset.cinematic: <String>['cinematic', 'flash', 'street'],
    AppPreset.dreamy: <String>['dreamy', 'portrait', 'creator'],
    AppPreset.motion: <String>['street', 'flash', 'neon'],
    AppPreset.vintage: <String>['vintage', 'travel', 'cinematic'],
    AppPreset.noir: <String>['mono', 'flash', 'cinematic'],
    AppPreset.neon: <String>['neon', 'flash', 'street'],
    AppPreset.cyber: <String>['neon', 'flash', 'luxury'],
    AppPreset.warm: <String>['summer', 'travel', 'portrait'],
    AppPreset.editorial: <String>['editorial', 'creator', 'luxury'],
    AppPreset.vaporwave: <String>['neon', 'dreamy', 'creator'],
    AppPreset.chrome: <String>['luxury', 'product', 'editorial'],
    AppPreset.halo: <String>['portrait', 'dreamy', 'creator'],
    AppPreset.monoPop: <String>['mono', 'flash', 'editorial'],
    AppPreset.street: <String>['street', 'flash', 'travel'],
  };

  List<FilterStudioAiStyleMatch> match({
    required FilterStudioAiInsight insight,
    required List<FilterStudioStylePreset> styles,
    int maxResults = 4,
  }) {
    final scored = styles
        .map(
          (style) => FilterStudioAiStyleMatch(
            style: style,
            score: _scoreStyle(insight, style),
          ),
        )
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final matches = <FilterStudioAiStyleMatch>[];
    final categoryUsage = <String, int>{};
    for (final match in scored) {
      if (matches.length == maxResults) {
        break;
      }
      final category = match.style.categoryId;
      final seenCount = categoryUsage[category] ?? 0;
      if (seenCount >= 2 && scored.length > maxResults) {
        continue;
      }
      categoryUsage[category] = seenCount + 1;
      matches.add(match);
    }

    return matches;
  }

  double _scoreStyle(
    FilterStudioAiInsight insight,
    FilterStudioStylePreset style,
  ) {
    final recipeScore = _recipeScore(insight.recipe, style.recipe);
    final presetScore = _presetScore(insight, style.categoryId);
    final featuredScore = style.featured ? 1.0 : 0.72;

    return (recipeScore * 0.68 +
            presetScore * 0.22 +
            featuredScore * 0.05 +
            insight.confidence * 0.05)
        .clamp(0.0, 1.0);
  }

  double _presetScore(FilterStudioAiInsight insight, String categoryId) {
    final recommendedCategories =
        _categoryAffinity[insight.recommendedPreset] ?? const <String>[];
    if (recommendedCategories.contains(categoryId)) {
      final rank = recommendedCategories.indexOf(categoryId);
      return rank == 0
          ? 1.0
          : rank == 1
              ? 0.92
              : 0.84;
    }

    for (final alternate in insight.alternatePresets) {
      final alternateCategories = _categoryAffinity[alternate];
      if (alternateCategories == null ||
          !alternateCategories.contains(categoryId)) {
        continue;
      }
      final rank = alternateCategories.indexOf(categoryId);
      return rank == 0
          ? 0.82
          : rank == 1
              ? 0.76
              : 0.70;
    }

    return 0.48;
  }

  double _recipeScore(FilterParams target, FilterParams candidate) {
    final weighted = <(double, double)>[
      (0.12, _closeness(target.contrast, candidate.contrast, 0.45)),
      (0.10, _closeness(target.saturation, candidate.saturation, 0.45)),
      (0.06, _closeness(target.exposure, candidate.exposure, 0.12)),
      (0.05, _closeness(target.brightness, candidate.brightness, 0.10)),
      (0.06, _closeness(target.warmth, candidate.warmth, 0.18)),
      (0.04, _closeness(target.tint, candidate.tint, 0.12)),
      (0.11, _closeness(target.blur, candidate.blur, 4.5)),
      (0.09, _closeness(target.aura, candidate.aura, 0.42)),
      (0.08, _closeness(target.grain, candidate.grain, 0.18)),
      (0.05, _closeness(target.scanlines, candidate.scanlines, 0.16)),
      (0.05, _closeness(target.glitch, candidate.glitch, 0.80)),
      (0.06, _closeness(target.vignette, candidate.vignette, 0.14)),
      (0.04, _closeness(target.prismOverlay, candidate.prismOverlay, 0.16)),
      (0.03, _closeness(target.dustOverlay, candidate.dustOverlay, 0.14)),
      (0.02, target.cinemaMode == candidate.cinemaMode ? 1.0 : 0.0),
      (0.02, target.colorPop == candidate.colorPop ? 1.0 : 0.0),
      (0.01, target.ghost == candidate.ghost ? 1.0 : 0.0),
      (
        0.01,
        target.showDateStamp == candidate.showDateStamp ? 1.0 : 0.0,
      ),
    ];

    var totalWeight = 0.0;
    var totalScore = 0.0;
    for (final (weight, value) in weighted) {
      totalWeight += weight;
      totalScore += weight * value;
    }

    return totalWeight == 0 ? 0.0 : totalScore / totalWeight;
  }

  double _closeness(double a, double b, double range) {
    if (range <= 0) {
      return a == b ? 1.0 : 0.0;
    }
    return (1 - ((a - b).abs() / range)).clamp(0.0, 1.0);
  }
}
