import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lama/features/filter_studio/domain/entities/app_preset.dart';
import 'package:lama/features/filter_studio/domain/entities/filter_params.dart';
import 'package:lama/features/filter_studio/domain/entities/filter_studio_ai_insight.dart';
import 'package:lama/features/filter_studio/presentation/models/filter_studio_style_preset.dart';
import 'package:lama/features/filter_studio/presentation/services/filter_studio_ai_style_matcher.dart';

void main() {
  const matcher = FilterStudioAiStyleMatcher();

  test('match ranks the closest recipe first', () {
    final insight = FilterStudioAiInsight(
      headline: 'headline',
      summary: 'summary',
      sceneLabel: 'scene',
      moodLabel: 'mood',
      lightingLabel: 'light',
      recommendedPreset: AppPreset.cinematic,
      alternatePresets: const <AppPreset>[
        AppPreset.cinematic,
        AppPreset.street,
      ],
      confidence: 0.91,
      subjectFocus: 0.7,
      colorEnergy: 0.6,
      dynamicRange: 0.8,
      recipe: const FilterParams(
        contrast: 1.18,
        saturation: 1.02,
        blur: 0.8,
        grain: 0.14,
        vignette: 0.18,
        cinemaMode: true,
      ),
    );

    final perfect = _style(
      id: 'perfect',
      categoryId: 'cinematic',
      featured: true,
      recipe: insight.recipe,
    );
    final close = _style(
      id: 'close',
      categoryId: 'street',
      recipe: insight.recipe.copyWith(
        contrast: 1.14,
        blur: 1.2,
        grain: 0.11,
      ),
    );
    final far = _style(
      id: 'far',
      categoryId: 'neon',
      recipe: const FilterParams(
        contrast: 1.04,
        saturation: 1.28,
        blur: 5.6,
        aura: 0.42,
        glitch: 0.6,
      ),
    );

    final matches = matcher.match(
      insight: insight,
      styles: <FilterStudioStylePreset>[close, far, perfect],
      maxResults: 3,
    );

    expect(matches, hasLength(3));
    expect(matches.first.style.id, 'perfect');
    expect(matches.first.score, greaterThan(matches[1].score));
    expect(matches[1].score, greaterThan(matches[2].score));
  });

  test('match limits repeated categories when enough choices exist', () {
    final insight = FilterStudioAiInsight(
      headline: 'headline',
      summary: 'summary',
      sceneLabel: 'scene',
      moodLabel: 'mood',
      lightingLabel: 'light',
      recommendedPreset: AppPreset.cinematic,
      alternatePresets: const <AppPreset>[
        AppPreset.cinematic,
        AppPreset.vintage,
        AppPreset.street,
      ],
      confidence: 0.84,
      subjectFocus: 0.7,
      colorEnergy: 0.5,
      dynamicRange: 0.8,
      recipe: const FilterParams(
        contrast: 1.16,
        saturation: 1.0,
        grain: 0.12,
        vignette: 0.16,
        cinemaMode: true,
      ),
    );

    final styles = List<FilterStudioStylePreset>.generate(
      5,
      (index) => _style(
        id: 'cinematic_$index',
        categoryId: 'cinematic',
        recipe: insight.recipe.copyWith(
          contrast: 1.16 + (index * 0.01),
        ),
      ),
    )
      ..add(
        _style(
          id: 'street_pick',
          categoryId: 'street',
          recipe: insight.recipe.copyWith(grain: 0.14, vignette: 0.18),
        ),
      )
      ..add(
        _style(
          id: 'vintage_pick',
          categoryId: 'vintage',
          recipe: insight.recipe.copyWith(
            grain: 0.18,
            scanlines: 0.10,
          ),
        ),
      );

    final matches = matcher.match(
      insight: insight,
      styles: styles,
      maxResults: 4,
    );

    final cinematicCount =
        matches.where((match) => match.style.categoryId == 'cinematic').length;

    expect(matches, hasLength(4));
    expect(cinematicCount, lessThanOrEqualTo(2));
  });
}

FilterStudioStylePreset _style({
  required String id,
  required String categoryId,
  required FilterParams recipe,
  bool featured = false,
}) {
  return FilterStudioStylePreset(
    id: id,
    categoryId: categoryId,
    categoryEn: categoryId,
    categoryAr: categoryId,
    badgeEn: 'Badge',
    badgeAr: 'Badge',
    nameEn: id,
    nameAr: id,
    taglineEn: 'Tagline',
    taglineAr: 'Tagline',
    icon: Icons.auto_awesome_rounded,
    accent: const Color(0xFF00D4FF),
    featured: featured,
    recipe: recipe,
  );
}
