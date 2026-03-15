import 'package:flutter_test/flutter_test.dart';
import 'package:lama/features/studio_editor/domain/entities/theft_config.dart';

void main() {
  test('TheftConfig sanitized clamps aggressive values', () {
    final safe = const TheftConfig(
      strength: 1.0,
      skinProtect: 0.1,
      lumaTransfer: 1.0,
      colorTransfer: 1.4,
      contrastBoost: 1.5,
      vignette: 0.4,
      grain: 0.2,
      isCyberpunk: true,
    ).sanitized();

    expect(safe.strength, 0.88);
    expect(safe.skinProtect, 0.35);
    expect(safe.lumaTransfer, 0.72);
    expect(safe.colorTransfer, 0.92);
    expect(safe.contrastBoost, 1.18);
    expect(safe.vignette, 0.18);
    expect(safe.grain, 0.08);
    expect(safe.isCyberpunk, isTrue);
  });
}
