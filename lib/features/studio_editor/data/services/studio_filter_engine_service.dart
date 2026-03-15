import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:lama/features/studio_editor/domain/entities/theft_config.dart';

int _clamp255(num value) => value < 0 ? 0 : (value > 255 ? 255 : value.toInt());

int _fastHash(int x, int y) {
  var n = x * 374761393 + y * 668265263;
  n = (n ^ (n >> 13)) * 1274126177;
  return (n ^ (n >> 16)) & 255;
}

void _rgbToYCbCr(int r, int g, int b, List<int> out) {
  out[0] = _clamp255(0.299 * r + 0.587 * g + 0.114 * b);
  out[1] = _clamp255(128 - 0.168736 * r - 0.331264 * g + 0.5 * b);
  out[2] = _clamp255(128 + 0.5 * r - 0.418688 * g - 0.081312 * b);
}

void _yCbCrToRgb(int y, int cb, int cr, List<int> out) {
  final yy = y.toDouble();
  final cbf = cb - 128.0;
  final crf = cr - 128.0;
  out[0] = _clamp255(yy + 1.402 * crf);
  out[1] = _clamp255(yy - 0.344136 * cbf - 0.714136 * crf);
  out[2] = _clamp255(yy + 1.772 * cbf);
}

double _getSkinWeight(int r, int g, int b) {
  if (r > 60 && g > 30 && b > 15 && r > g && r > b) {
    final diff = r - math.max(g, b);
    if (diff > 10) {
      return (diff / 100.0).clamp(0.0, 1.0);
    }
  }
  return 0.0;
}

List<double> _cdfFromHist(List<int> hist) {
  final total = hist.fold<int>(0, (sum, value) => sum + value);
  if (total == 0) {
    return List<double>.filled(256, 0.0);
  }

  final cdf = List<double>.filled(256, 0.0);
  var cumulative = 0;
  for (var i = 0; i < 256; i++) {
    cumulative += hist[i];
    cdf[i] = cumulative / total;
  }
  return cdf;
}

List<int> _lutFromCdfs(List<double> src, List<double> ref) {
  final lut = List<int>.filled(256, 0);
  var refIndex = 0;
  for (var i = 0; i < 256; i++) {
    while (refIndex < 255 && ref[refIndex] < src[i]) {
      refIndex++;
    }
    lut[i] = refIndex;
  }
  return lut;
}

TheftSignature analyzeUnifiedStyle(
  img.Image ref, {
  img.Image? refMaskImage,
}) {
  final small = img.copyResize(ref, width: 400);
  img.Image? smallMask;
  if (refMaskImage != null) {
    smallMask = img.copyResize(
      refMaskImage,
      width: small.width,
      height: small.height,
    );
  }

  final histY = List<int>.filled(256, 0);
  final ycc = List<int>.filled(3, 0);
  var sumCb = 0.0;
  var sumCr = 0.0;
  var validPixels = 0;

  for (var y = 0; y < small.height; y++) {
    for (var x = 0; x < small.width; x++) {
      if (smallMask != null && smallMask.getPixelSafe(x, y).r > 128) {
        continue;
      }

      final pixel = small.getPixel(x, y);
      _rgbToYCbCr(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), ycc);
      histY[ycc[0]]++;
      sumCb += ycc[1];
      sumCr += ycc[2];
      validPixels++;
    }
  }

  if (validPixels == 0) {
    validPixels = 1;
  }

  final meanCb = sumCb / validPixels;
  final meanCr = sumCr / validPixels;
  var varCb = 0.0;
  var varCr = 0.0;

  for (var y = 0; y < small.height; y++) {
    for (var x = 0; x < small.width; x++) {
      if (smallMask != null && smallMask.getPixelSafe(x, y).r > 128) {
        continue;
      }

      final pixel = small.getPixel(x, y);
      _rgbToYCbCr(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), ycc);
      varCb += math.pow(ycc[1] - meanCb, 2).toDouble();
      varCr += math.pow(ycc[2] - meanCr, 2).toDouble();
    }
  }

  return TheftSignature(
    histY: histY,
    meanCb: meanCb,
    meanCr: meanCr,
    stdCb: math.sqrt(varCb / validPixels),
    stdCr: math.sqrt(varCr / validPixels),
  );
}

img.Image applyStudioStyle({
  required img.Image target,
  required TheftSignature sig,
  img.Image? maskImage,
  img.Image? aiMaskImage,
  TheftConfig cfg = const TheftConfig(),
}) {
  final small = img.copyResize(target, width: 400);
  final histY = List<int>.filled(256, 0);
  final ycc = List<int>.filled(3, 0);
  var sumCb = 0.0;
  var sumCr = 0.0;
  final pixels = small.width * small.height;

  for (final pixel in small) {
    _rgbToYCbCr(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), ycc);
    histY[ycc[0]]++;
    sumCb += ycc[1];
    sumCr += ycc[2];
  }

  final targetMeanCb = sumCb / pixels;
  final targetMeanCr = sumCr / pixels;
  var varCb = 0.0;
  var varCr = 0.0;

  for (final pixel in small) {
    _rgbToYCbCr(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), ycc);
    varCb += math.pow(ycc[1] - targetMeanCb, 2).toDouble();
    varCr += math.pow(ycc[2] - targetMeanCr, 2).toDouble();
  }

  final targetStdCb = math.sqrt(varCb / pixels);
  final targetStdCr = math.sqrt(varCr / pixels);
  final lutY = _lutFromCdfs(_cdfFromHist(histY), _cdfFromHist(sig.histY));

  final width = target.width;
  final height = target.height;
  final centerX = width / 2.0;
  final centerY = height / 2.0;
  final maxDistance = math.sqrt(centerX * centerX + centerY * centerY);
  final out = target.clone();
  final rgb = List<int>.filled(3, 0);

  img.Image? resizedMask;
  if (maskImage != null) {
    resizedMask = img.copyResize(maskImage, width: width, height: height);
  }
  img.Image? resizedAiMask;
  if (aiMaskImage != null) {
    resizedAiMask = img.copyResize(aiMaskImage, width: width, height: height);
  }

  var activeLuma = cfg.lumaTransfer;
  var activeColor = cfg.colorTransfer;
  if (cfg.isColorTheft) {
    activeLuma = 0.0;
    activeColor = 1.2;
  }
  if (cfg.isLightTheft) {
    activeLuma = 1.0;
    activeColor = 0.0;
  }
  if (cfg.isStyleTheft) {
    activeLuma = 1.0;
    activeColor = 1.2;
  }
  if (cfg.isThemeTheft) {
    activeLuma = 0.2;
    activeColor = 0.8;
  }

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixel = out.getPixel(x, y);
      final originalR = pixel.r.toInt();
      final originalG = pixel.g.toInt();
      final originalB = pixel.b.toInt();

      var protect = 0.0;
      if (resizedMask != null) {
        protect = resizedMask.getPixelSafe(x, y).r / 255.0;
      } else if (resizedAiMask != null) {
        protect = resizedAiMask.getPixelSafe(x, y).r / 255.0;
      } else {
        protect = _getSkinWeight(originalR, originalG, originalB);
      }
      protect *= (0.35 + 0.65 * cfg.skinProtect);

      _rgbToYCbCr(originalR, originalG, originalB, ycc);
      var originalY = ycc[0];
      var cb = ycc[1];
      var cr = ycc[2];

      var currentY = originalY;
      if (cfg.isHDR) {
        currentY = currentY < 128
            ? currentY + (128 - currentY) ~/ 3
            : currentY - (currentY - 128) ~/ 4;
      }

      var newY = _clamp255(
        currentY * (1.0 - activeLuma) + lutY[currentY] * activeLuma,
      );

      final yNorm = newY / 255.0;
      final contrastY = yNorm < 0.5
          ? 2.0 * yNorm * yNorm
          : 1.0 - 2.0 * (1.0 - yNorm) * (1.0 - yNorm);
      newY = _clamp255(
        newY * (1.0 - (cfg.contrastBoost - 1.0)) +
            contrastY * 255.0 * (cfg.contrastBoost - 1.0),
      );

      if (cfg.isSepia) {
        cb = _clamp255(cb * 0.82 + 110 * 0.18);
        cr = _clamp255(cr * 0.82 + 145 * 0.18);
      } else if (cfg.isCyberpunk) {
        cb = _clamp255(cb + 12 * activeColor);
        cr = _clamp255(cr - 10 * activeColor);
      } else if (cfg.isColorSplash) {
        final average = (cb + cr) ~/ 2;
        cb = _clamp255(cb * 0.25 + average * 0.75);
        cr = _clamp255(cr * 0.25 + average * 0.75);
      } else {
        final shiftedCb = sig.meanCb +
            ((cb - targetMeanCb) * (sig.stdCb / (targetStdCb + 1e-6)));
        final shiftedCr = sig.meanCr +
            ((cr - targetMeanCr) * (sig.stdCr / (targetStdCr + 1e-6)));
        cb = _clamp255(cb * (1.0 - activeColor) + shiftedCb * activeColor);
        cr = _clamp255(cr * (1.0 - activeColor) + shiftedCr * activeColor);
      }

      _yCbCrToRgb(newY, cb, cr, rgb);

      final styleMix = (1.0 - protect) * cfg.strength.clamp(0.0, 1.0);
      final preserveMix = 1.0 - styleMix;

      var finalR = _clamp255(originalR * preserveMix + rgb[0] * styleMix);
      var finalG = _clamp255(originalG * preserveMix + rgb[1] * styleMix);
      var finalB = _clamp255(originalB * preserveMix + rgb[2] * styleMix);

      if (cfg.vignette > 0) {
        final dx = x - centerX;
        final dy = y - centerY;
        final distance = math.sqrt(dx * dx + dy * dy) / maxDistance;
        final vignetteFactor = 1.0 - cfg.vignette * math.pow(distance, 1.8);
        finalR = _clamp255(finalR * vignetteFactor);
        finalG = _clamp255(finalG * vignetteFactor);
        finalB = _clamp255(finalB * vignetteFactor);
      }

      if (cfg.grain > 0) {
        final grain = ((_fastHash(x, y) - 128) * cfg.grain).toInt();
        finalR = _clamp255(finalR + grain);
        finalG = _clamp255(finalG + grain);
        finalB = _clamp255(finalB + grain);
      }

      out.setPixelRgba(x, y, finalR, finalG, finalB, pixel.a.toInt());
    }
  }

  return out;
}

Future<Uint8List> runStudioFilterEngine(Map<String, dynamic> params) async {
  final targetImage = img.decodeImage(params['targetBytes'] as Uint8List)!;
  final refImage = img.decodeImage(params['refBytes'] as Uint8List)!;

  img.Image? manualMask;
  if (params['manualMaskBytes'] != null) {
    manualMask = img.decodeImage(params['manualMaskBytes'] as Uint8List);
  }

  img.Image? aiMask;
  if (params['aiMaskBytes'] != null) {
    aiMask = img.decodeImage(params['aiMaskBytes'] as Uint8List);
  }

  img.Image? refAiMask;
  if (params['refAiMaskBytes'] != null) {
    refAiMask = img.decodeImage(params['refAiMaskBytes'] as Uint8List);
  }

  final config = TheftConfig.fromMap(params);
  final signature = analyzeUnifiedStyle(refImage, refMaskImage: refAiMask);
  final result = applyStudioStyle(
    target: targetImage,
    sig: signature,
    maskImage: manualMask,
    aiMaskImage: aiMask,
    cfg: config,
  );

  return Uint8List.fromList(img.encodeJpg(result, quality: 100));
}

Future<Uint8List> runFilterEngine(Map<String, dynamic> params) {
  return runStudioFilterEngine(params);
}

class StudioFilterEngineService {
  const StudioFilterEngineService();

  Future<Uint8List> process(Map<String, dynamic> params) {
    return compute(runStudioFilterEngine, params);
  }
}
