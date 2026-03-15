import 'package:lama/features/filter_studio/domain/entities/filter_params.dart';
import 'package:lama/features/filter_studio/presentation/services/filter_studio_mask_policy.dart';

class FilterParamsCalibrator {
  static FilterParams sanitize(
    FilterParams params, {
    required bool hasPersonMask,
  }) {
    final usesMask = shouldUseSubjectMask(
      params,
      hasPersonMask: hasPersonMask,
    );

    var blur = params.blur.clamp(0.0, usesMask ? 3.4 : 2.2).toDouble();
    var aura = params.aura.clamp(0.0, usesMask ? 0.24 : 0.16).toDouble();
    var grain = params.grain.clamp(0.0, 0.18).toDouble();
    var scanlines = params.scanlines.clamp(0.0, 0.16).toDouble();
    var glitch = params.glitch.clamp(0.0, 0.42).toDouble();
    var vignette = params.vignette.clamp(0.0, 0.18).toDouble();
    var prismOverlay = params.prismOverlay.clamp(0.0, 0.16).toDouble();
    var dustOverlay = params.dustOverlay.clamp(0.0, 0.16).toDouble();

    if (!usesMask && blur > 1.6 && aura > 0.10) {
      aura = 0.10;
    }

    if (glitch > 0.20) {
      blur = blur.clamp(0.0, 1.2);
      aura = aura.clamp(0.0, 0.10);
      scanlines = scanlines.clamp(0.0, 0.10);
    }

    if (grain > 0.14) {
      glitch = glitch.clamp(0.0, 0.28);
    }

    return params.copyWith(
      contrast: params.contrast.clamp(0.72, 1.24).toDouble(),
      saturation: params.saturation.clamp(0.62, 1.26).toDouble(),
      exposure: params.exposure.clamp(-0.18, 0.18).toDouble(),
      brightness: params.brightness.clamp(-0.14, 0.14).toDouble(),
      warmth: params.warmth.clamp(-0.18, 0.18).toDouble(),
      tint: params.tint.clamp(-0.12, 0.12).toDouble(),
      blur: blur,
      aura: aura,
      grain: grain,
      scanlines: scanlines,
      glitch: glitch,
      ghost: params.ghost && hasPersonMask,
      replaceBackground: params.replaceBackground && hasPersonMask,
      subjectMaskEnabled: params.subjectMaskEnabled && hasPersonMask,
      vignette: vignette,
      prismOverlay: prismOverlay,
      dustOverlay: dustOverlay,
    );
  }
}
