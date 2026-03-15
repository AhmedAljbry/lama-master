import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lama/features/filter_studio/data/services/filter_studio_ai_analysis_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generateInsight returns a usable recipe and keeps recommendation first',
      () async {
    final service = FilterStudioAiAnalysisService();

    final insight = await service.generateInsight(_buildSamplePng(), 'en');

    expect(insight.headline, isNotEmpty);
    expect(insight.summary, isNotEmpty);
    expect(insight.alternatePresets, isNotEmpty);
    expect(insight.alternatePresets.first, insight.recommendedPreset);
    expect(insight.confidence, greaterThanOrEqualTo(0.55));
    expect(insight.confidence, lessThanOrEqualTo(0.97));
    expect(insight.recipe.auraColor, isA<Color>());
  });

  test(
      'generateInsight localizes labels without changing the creative recommendation',
      () async {
    final service = FilterStudioAiAnalysisService();
    final bytes = _buildSamplePng();

    final english = await service.generateInsight(bytes, 'en');
    final arabic = await service.generateInsight(bytes, 'ar');

    expect(arabic.headline, isNotEmpty);
    expect(arabic.summary, isNotEmpty);
    expect(arabic.headline, isNot(equals(english.headline)));
    expect(arabic.recommendedPreset, english.recommendedPreset);
  });
}

Uint8List _buildSamplePng() {
  final image = img.Image(width: 48, height: 48);

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final isCenter = x > 12 && x < 36 && y > 8 && y < 40;

      if (isCenter) {
        image.setPixelRgba(x, y, 250, 96, 184, 255);
      } else if (y < image.height ~/ 2) {
        image.setPixelRgba(x, y, 24, 66, 214, 255);
      } else {
        image.setPixelRgba(x, y, 10, 18, 44, 255);
      }
    }
  }

  return img.encodePng(image);
}
