import 'dart:math' as math;

import 'package:lama/features/luma_editor/domain/entities/filter_item.dart';
import 'package:lama/features/luma_editor/domain/entities/random_filter_profile.dart';

class GenerateRandomFilterProfile {
  const GenerateRandomFilterProfile();

  RandomFilterProfile call(List<FilterItem> filters) {
    final random = math.Random();
    final filter = filters[random.nextInt(filters.length)];

    return RandomFilterProfile(
      filterId: filter.id,
      intensity: (0.55 + random.nextDouble() * 0.45).clamp(0.0, 1.0),
      brightness: (random.nextDouble() * 0.20 - 0.10).clamp(-0.18, 0.18),
      contrast: (random.nextDouble() * 0.34 - 0.06).clamp(-0.12, 0.32),
      saturation: (random.nextDouble() * 0.42 - 0.08).clamp(-0.18, 0.40),
      warmth: (random.nextDouble() * 0.24 - 0.12).clamp(-0.22, 0.22),
      fade: (random.nextDouble() * 0.10).clamp(0.0, 0.12),
    );
  }
}
