import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lama/core/config/app_config.dart';
import 'package:lama/features/image_location_intel/data/services/openai_location_scene_service.dart';

void main() {
  test('returns disabled insight when OpenAI API key is absent', () async {
    final service = OpenAiLocationSceneService(
      const AppConfig(baseUrl: 'https://example.invalid'),
    );

    final insight = await service.analyzeScene(
      imageBytes: Uint8List(0),
    );

    expect(insight.enabled, isFalse);
    expect(insight.success, isFalse);
    expect(insight.status, 'disabled');
  });
}
