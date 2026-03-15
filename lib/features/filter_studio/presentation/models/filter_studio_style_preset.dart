import 'package:flutter/material.dart';
import 'package:lama/core/i18n/t.dart';
import 'package:lama/features/filter_studio/domain/entities/filter_params.dart';

class FilterStudioStylePreset {
  final String id;
  final String categoryId;
  final String categoryEn;
  final String categoryAr;
  final String badgeEn;
  final String badgeAr;
  final String nameEn;
  final String nameAr;
  final String taglineEn;
  final String taglineAr;
  final IconData icon;
  final Color accent;
  final bool featured;
  final FilterParams recipe;

  const FilterStudioStylePreset({
    required this.id,
    required this.categoryId,
    required this.categoryEn,
    required this.categoryAr,
    required this.badgeEn,
    required this.badgeAr,
    required this.nameEn,
    required this.nameAr,
    required this.taglineEn,
    required this.taglineAr,
    required this.icon,
    required this.accent,
    required this.featured,
    required this.recipe,
  });

  String name(Lang lang) => lang == Lang.ar ? nameAr : nameEn;

  String tagline(Lang lang) => lang == Lang.ar ? taglineAr : taglineEn;

  String categoryLabel(Lang lang) => lang == Lang.ar ? categoryAr : categoryEn;

  String badge(Lang lang) => lang == Lang.ar ? badgeAr : badgeEn;
}
