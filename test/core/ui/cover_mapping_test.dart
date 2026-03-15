import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lama/core/ui/cover_mapping.dart';

void main() {
  group('cover_mapping', () {
    test('contain rect centers the full image inside the viewport', () {
      final rect = applyBoxFitContainRect(
        inputImageSize: const Size(100, 200),
        outputSize: const Size(200, 200),
      );

      expect(rect.left, 50);
      expect(rect.top, 0);
      expect(rect.width, 100);
      expect(rect.height, 200);
    });

    test('contain mapping ignores letterboxed taps and round-trips points', () {
      final outside = widgetPointToImage01(
        widgetPoint: const Offset(10, 100),
        widgetSize: const Size(200, 200),
        imageW: 100,
        imageH: 200,
        fit: BoxFit.contain,
      );

      expect(outside, isNull);

      final widgetPoint = image01ToWidgetPoint(
        p01: const Offset(0.25, 0.75),
        widgetSize: const Size(200, 200),
        imageW: 100,
        imageH: 200,
        fit: BoxFit.contain,
      );

      final mappedBack = widgetPointToImage01(
        widgetPoint: widgetPoint,
        widgetSize: const Size(200, 200),
        imageW: 100,
        imageH: 200,
        fit: BoxFit.contain,
      );

      expect(mappedBack, isNotNull);
      expect(mappedBack!.dx, closeTo(0.25, 0.0001));
      expect(mappedBack.dy, closeTo(0.75, 0.0001));
    });

    test('cover mapping keeps crop behavior for full-bleed canvases', () {
      final rect = applyBoxFitCoverRect(
        inputImageSize: const Size(200, 100),
        outputSize: const Size(200, 200),
      );

      expect(rect.left, -100);
      expect(rect.top, 0);
      expect(rect.width, 400);
      expect(rect.height, 200);

      final mapped = widgetPointToImage01(
        widgetPoint: const Offset(0, 100),
        widgetSize: const Size(200, 200),
        imageW: 200,
        imageH: 100,
        fit: BoxFit.cover,
      );

      expect(mapped, isNotNull);
      expect(mapped!.dx, closeTo(0.25, 0.0001));
      expect(mapped.dy, closeTo(0.5, 0.0001));
    });
  });
}
