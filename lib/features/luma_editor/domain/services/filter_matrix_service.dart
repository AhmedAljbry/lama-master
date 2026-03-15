import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lama/features/luma_editor/domain/entities/filter_item.dart';

class FilterMatrixService {
  static final List<double> identity = [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static List<FilterItem> generateBaseFilters() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final list = <FilterItem>[
      FilterItem(
        id: 'base_original',
        name: 'Original',
        matrix: identity,
        indicatorColor: Colors.white,
        createdAtMs: now,
      ),
    ];

    for (var index = 1; index <= 5; index++) {
      list.add(
        FilterItem(
          id: 'base_cinema_$index',
          name: 'Cinema $index',
          matrix: _channelMix(
            r: 1.0,
            g: 1.0 + (index * 0.05),
            b: 1.0 - (index * 0.1),
          ),
          indicatorColor: Colors.teal,
          createdAtMs: now,
        ),
      );
    }

    for (var index = 1; index <= 5; index++) {
      list.add(
        FilterItem(
          id: 'base_retro_$index',
          name: 'Retro $index',
          matrix: _sepia(0.2 + (index * 0.1)),
          indicatorColor: Colors.orangeAccent,
          createdAtMs: now,
        ),
      );
    }

    return list;
  }

  static List<FilterItem> generateProPack100() {
    final now = DateTime.now().millisecondsSinceEpoch;

    FilterItem make(String id, String name, List<double> matrix, Color color) {
      return FilterItem(
        id: id,
        name: name,
        matrix: matrix,
        indicatorColor: color,
        createdAtMs: now,
      );
    }

    final out = <FilterItem>[];
    final tints = <Color>[
      const Color(0xFF00A3A3),
      const Color(0xFFFF8A00),
      const Color(0xFF7C4DFF),
      const Color(0xFF00C853),
      const Color(0xFFFF1744),
      const Color(0xFF90A4AE),
      const Color(0xFFBCAAA4),
      const Color(0xFF1A237E),
      const Color(0xFF263238),
      const Color(0xFFFFD54F),
    ];
    const contrasts = [-0.20, -0.10, 0.0, 0.10, 0.20];
    const saturations = [-0.20, -0.10, 0.0, 0.15, 0.30];
    const warmths = [-0.40, -0.20, 0.0, 0.20, 0.40];
    const fades = [0.00, 0.05, 0.10, 0.15, 0.20];

    var idx = 1;
    for (var tintIndex = 0; tintIndex < tints.length; tintIndex++) {
      for (var variation = 0; variation < 10; variation++) {
        final contrastValue =
            contrasts[(tintIndex + variation) % contrasts.length];
        final saturationValue =
            saturations[(tintIndex * 2 + variation) % saturations.length];
        final warmthValue =
            warmths[(tintIndex * 3 + variation) % warmths.length];
        final fadeValue = fades[(tintIndex + 2 * variation) % fades.length];

        final tintMatrix =
            tintFromColor(tints[tintIndex], 0.18 + (variation % 3) * 0.07);
        var matrix = identity;
        matrix = multiply(tintMatrix, matrix);
        matrix = multiply(warmth(warmthValue), matrix);
        matrix = multiply(saturation(saturationValue), matrix);
        matrix = multiply(contrast(contrastValue), matrix);
        matrix = multiply(fade(fadeValue), matrix);

        out.add(
          make(
            'pro_${idx.toString().padLeft(3, '0')}',
            'Pro ${idx.toString().padLeft(3, '0')}',
            matrix,
            tints[tintIndex],
          ),
        );

        idx++;
        if (idx > 100) {
          return out;
        }
      }
    }

    return out;
  }

  static List<double> lerpMatrix(List<double> target, double intensity) {
    if (intensity >= 1.0) {
      return target;
    }
    if (intensity <= 0.0) {
      return identity;
    }

    return List<double>.generate(
      20,
      (index) => identity[index] + (target[index] - identity[index]) * intensity,
    );
  }

  static List<double> tintFromColor(Color color, double intensity) {
    final tint = intensity.clamp(0.0, 1.0);
    final red = _toByte(color.r);
    final green = _toByte(color.g);
    final blue = _toByte(color.b);

    return [
      1 - tint, 0, 0, 0, red * tint,
      0, 1 - tint, 0, 0, green * tint,
      0, 0, 1 - tint, 0, blue * tint,
      0, 0, 0, 1, 0,
    ];
  }

  static List<double> brightness(double value) {
    final offset = value.clamp(-1.0, 1.0) * 255.0;
    return [
      1, 0, 0, 0, offset,
      0, 1, 0, 0, offset,
      0, 0, 1, 0, offset,
      0, 0, 0, 1, 0,
    ];
  }

  static List<double> contrast(double value) {
    final constrained = value.clamp(-1.0, 1.0);
    final factor = 1.0 + constrained;
    final offset = 128.0 * (1.0 - factor);
    return [
      factor, 0, 0, 0, offset,
      0, factor, 0, 0, offset,
      0, 0, factor, 0, offset,
      0, 0, 0, 1, 0,
    ];
  }

  static List<double> saturation(double value) {
    final constrained = 1.0 + value.clamp(-1.0, 1.0);
    const lumR = 0.2126;
    const lumG = 0.7152;
    const lumB = 0.0722;

    final ir = (1 - constrained) * lumR;
    final ig = (1 - constrained) * lumG;
    final ib = (1 - constrained) * lumB;

    return [
      ir + constrained, ig, ib, 0, 0,
      ir, ig + constrained, ib, 0, 0,
      ir, ig, ib + constrained, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  static List<double> warmth(double value) {
    final constrained = value.clamp(-1.0, 1.0);
    final red = constrained > 0 ? 1.0 + constrained * 0.25 : 1.0;
    final blue = constrained < 0 ? 1.0 + (-constrained) * 0.25 : 1.0;
    return _channelMix(r: red, g: 1.0, b: blue);
  }

  static List<double> fade(double value) {
    final constrained = value.clamp(0.0, 1.0);
    final factor = 1.0 - (constrained * 0.25);
    final offset = 128.0 * (1.0 - factor);
    return [
      factor, 0, 0, 0, offset,
      0, factor, 0, 0, offset,
      0, 0, factor, 0, offset,
      0, 0, 0, 1, 0,
    ];
  }

  static List<double> multiply(List<double> a, List<double> b) {
    final out = List<double>.filled(20, 0);

    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 5; col++) {
        final idx = row * 5 + col;
        if (col == 4) {
          out[idx] = a[row * 5 + 4]
              + a[row * 5] * b[4]
              + a[row * 5 + 1] * b[9]
              + a[row * 5 + 2] * b[14]
              + a[row * 5 + 3] * b[19];
        } else {
          out[idx] = a[row * 5] * b[col]
              + a[row * 5 + 1] * b[col + 5]
              + a[row * 5 + 2] * b[col + 10]
              + a[row * 5 + 3] * b[col + 15];
        }
      }
    }

    return out;
  }

  static double estimateWarmth(Color color) {
    final red = _toByte(color.r);
    final blue = _toByte(color.b);
    return ((red - blue) / 255.0).clamp(-1.0, 1.0);
  }

  static double estimateSaturation(Color color) {
    final red = color.r;
    final green = color.g;
    final blue = color.b;
    final mx = math.max<double>(red, math.max<double>(green, blue));
    final mn = math.min<double>(red, math.min<double>(green, blue));
    final delta = mx - mn;
    if (mx == 0) {
      return 0.0;
    }
    return (delta / mx).clamp(0.0, 1.0);
  }

  static double estimateContrastFromPalette(List<Color> colors) {
    if (colors.isEmpty) {
      return 0.0;
    }

    final luminance = colors.map(_luma).toList()..sort();
    final spread = (luminance.last - luminance.first) / 255.0;
    return (0.35 - spread).clamp(-1.0, 1.0);
  }

  static List<double> _channelMix({
    double r = 1,
    double g = 1,
    double b = 1,
  }) {
    return [
      r, 0, 0, 0, 0,
      0, g, 0, 0, 0,
      0, 0, b, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  static List<double> _sepia(double intensity) {
    final inv = 1.0 - intensity;
    return [
      0.393 + 0.607 * inv, 0.769 - 0.769 * inv, 0.189 - 0.189 * inv, 0, 0,
      0.349 - 0.349 * inv, 0.686 + 0.314 * inv, 0.168 - 0.168 * inv, 0, 0,
      0.272 - 0.272 * inv, 0.534 - 0.534 * inv, 0.131 + 0.869 * inv, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  static double _luma(Color color) {
    final red = _toByte(color.r);
    final green = _toByte(color.g);
    final blue = _toByte(color.b);
    return 0.2126 * red + 0.7152 * green + 0.0722 * blue;
  }

  static int _toByte(double component) {
    return (component * 255).round().clamp(0, 255);
  }
}
