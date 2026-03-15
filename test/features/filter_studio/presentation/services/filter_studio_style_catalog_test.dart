import 'package:flutter_test/flutter_test.dart';
import 'package:lama/core/i18n/t.dart';
import 'package:lama/features/filter_studio/presentation/services/filter_studio_style_catalog.dart';

void main() {
  test('style catalog exposes 140 curated looks across 14 packs', () {
    final styles = FilterStudioStyleCatalog.presets;
    final categories = styles.map((style) => style.categoryId).toSet();

    expect(styles, hasLength(140));
    expect(styles.map((style) => style.id).toSet(), hasLength(140));
    expect(categories, hasLength(14));
    expect(
      categories,
      containsAll(<String>['creator', 'flash', 'product', 'travel']),
    );
    expect(
      styles.where((style) => style.featured).length,
      greaterThanOrEqualTo(42),
    );
  });

  test('style catalog keeps labels localized and recipes populated', () {
    final style = FilterStudioStyleCatalog.presets.first;

    expect(style.name(Lang.en), isNotEmpty);
    expect(style.name(Lang.ar), isNotEmpty);
    expect(style.categoryLabel(Lang.en), isNot(style.categoryLabel(Lang.ar)));
    expect(style.badge(Lang.en), isNotEmpty);
    expect(style.tagline(Lang.en), isNotEmpty);
    expect(style.recipe.contrast, greaterThan(0));
    expect(style.recipe.saturation, greaterThan(0));
  });
}
