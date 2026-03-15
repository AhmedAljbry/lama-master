/*
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';

/// ============================================================
/// STYLE THEFT PRO++ V9 ULTIMATE - FULL ENGINE NO OMISSIONS
/// ============================================================

class TheftConfig {
  final double strength;
  final double skinProtect;
  final double lumaTransfer;
  final double colorTransfer;
  final double contrastBoost;
  final double vignette;
  final double grain;

  // الأوضاع السحرية
  final bool isCinematic;
  final bool isColorTheft;
  final bool isLightTheft;
  final bool isStyleTheft;
  final bool isThemeTheft;

  // التأثيرات الإضافية
  final bool isColorSplash;
  final bool isHDR;
  final bool isCyberpunk;
  final bool isSepia;

  const TheftConfig({
    this.strength = 1.0, this.skinProtect = 0.85, this.lumaTransfer = 0.3,
    this.colorTransfer = 1.0, this.contrastBoost = 1.15, this.vignette = 0.3, this.grain = 0.1,
    this.isCinematic = false, this.isColorTheft = false, this.isLightTheft = false,
    this.isStyleTheft = false, this.isThemeTheft = false,
    this.isColorSplash = false, this.isHDR = false, this.isCyberpunk = false, this.isSepia = false,
  });
}

class TheftSignature {
  final List<int> histY;
  final double meanCb, meanCr;
  final double stdCb, stdCr;
  const TheftSignature({required this.histY, required this.meanCb, required this.meanCr, required this.stdCb, required this.stdCr});
}

int _clamp255(num v) => v < 0 ? 0 : (v > 255 ? 255 : v.toInt());

int _fastHash(int x, int y) {
  int n = x * 374761393 + y * 668265263;
  n = (n ^ (n >> 13)) * 1274126177;
  return (n ^ (n >> 16)) & 255;
}

void _rgbToYCbCr(int r, int g, int b, List<int> out) {
  out[0] = _clamp255(0.299 * r + 0.587 * g + 0.114 * b);
  out[1] = _clamp255(128 - 0.168736 * r - 0.331264 * g + 0.5 * b);
  out[2] = _clamp255(128 + 0.5 * r - 0.418688 * g - 0.081312 * b);
}

void _yCbCrToRgb(int y, int cb, int cr, List<int> out) {
  final yy = y.toDouble(), cbf = cb - 128.0, crf = cr - 128.0;
  out[0] = _clamp255(yy + 1.402 * crf);
  out[1] = _clamp255(yy - 0.344136 * cbf - 0.714136 * crf);
  out[2] = _clamp255(yy + 1.772 * cbf);
}

double _getSkinWeightImproved(int r, int g, int b) {
  if (r > 60 && g > 30 && b > 15 && r > g && r > b) {
    int diff = r - math.max(g, b);
    if (diff > 10) return (diff / 100.0).clamp(0.0, 1.0);
  }
  return 0.0;
}

List<double> _cdfFromHist(List<int> hist) {
  final total = hist.fold<int>(0, (a, b) => a + b);
  if (total == 0) return List.filled(256, 0.0);
  final cdf = List<double>.filled(256, 0.0);
  int cum = 0;
  for (int i = 0; i < 256; i++) { cum += hist[i]; cdf[i] = cum / total; }
  return cdf;
}

List<int> _lutFromCdfs(List<double> src, List<double> ref) {
  final lut = List<int>.filled(256, 0);
  int j = 0;
  for (int i = 0; i < 256; i++) { while (j < 255 && ref[j] < src[i]) j++; lut[i] = j; }
  return lut;
}

/// 🖥️ المراقب الذكي يفحص البيانات المحولة
img.Image safeLoadImageMonitor(Uint8List bytes, String sourceName) {
  print("\n==================================================");
  print("🔎 [MONITOR]: جاري فحص بيانات الصورة: $sourceName");
  try {
    if (bytes.isEmpty) {
      print("❌ [TERMINAL ERROR]: البيانات فارغة (0 Bytes)!");
      throw "البيانات فارغة.";
    }
    final image = img.decodeImage(bytes);
    if (image == null) {
      print("❌ [TERMINAL ERROR]: فشل فك التشفير!");
      throw "صيغة غير مدعومة أو ملف تالف.";
    }
    print("✅ [MONITOR]: الصورة سليمة ومجهزة بنجاح! الأبعاد: ${image.width}x${image.height}");
    print("==================================================\n");
    return image;
  } catch (e) {
    print("💥 [FATAL ERROR]: $e");
    print("==================================================\n");
    throw Exception(e.toString());
  }
}

/// 🤖 الذكاء الاصطناعي لفصل الشخص
Future<img.Image?> generateAiMask(String imagePath) async {
  print("🤖 [AI]: جاري تشغيل محرك ML Kit لعزل الشخص...");
  try {
    final inputImage = InputImage.fromFilePath(imagePath);
    final segmenter = SelfieSegmenter(mode: SegmenterMode.single, enableRawSizeMask: true);
    final mask = await segmenter.processImage(inputImage);
    segmenter.close();

    if (mask == null) {
      print("⚠️ [AI]: لم يتم العثور على شخص واضح.");
      return null;
    }

    final width = mask.width;
    final height = mask.height;
    final confidences = mask.confidences;
    final aiMaskImage = img.Image(width: width, height: height);

    int index = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int colorValue = (confidences[index] * 255).toInt();
        aiMaskImage.setPixelRgba(x, y, colorValue, colorValue, colorValue, 255);
        index++;
      }
    }
    print("✅ [AI]: تم توليد القناع بنجاح.");
    return aiMaskImage;
  } catch (e) {
    print("❌ [AI ERROR]: $e");
    return null;
  }
}

TheftSignature analyzeUnifiedStyle(img.Image ref) {
  final small = img.copyResize(ref, width: 400);
  final histY = List.filled(256, 0);
  double sumCb = 0, sumCr = 0;
  final ycc = List.filled(3, 0);
  final pixels = small.width * small.height;

  for (final p in small) {
    _rgbToYCbCr(p.r.toInt(), p.g.toInt(), p.b.toInt(), ycc);
    histY[ycc[0]]++;
    sumCb += ycc[1]; sumCr += ycc[2];
  }
  final meanCb = sumCb / pixels, meanCr = sumCr / pixels;
  double varCb = 0, varCr = 0;
  for (final p in small) {
    _rgbToYCbCr(p.r.toInt(), p.g.toInt(), p.b.toInt(), ycc);
    varCb += math.pow(ycc[1] - meanCb, 2);
    varCr += math.pow(ycc[2] - meanCr, 2);
  }
  return TheftSignature(histY: histY, meanCb: meanCb, meanCr: meanCr, stdCb: math.sqrt(varCb / pixels), stdCr: math.sqrt(varCr / pixels));
}

/// 🎨 المحرك الخارق V9
img.Image applyStudioStyle({required img.Image target, required TheftSignature sig, img.Image? maskImage, img.Image? aiMaskImage, TheftConfig cfg = const TheftConfig()}) {
  final small = img.copyResize(target, width: 400);
  final histY = List.filled(256, 0);
  final ycc = List.filled(3, 0);
  double sumCb = 0, sumCr = 0;
  final pixels = small.width * small.height;

  for (final p in small) {
    _rgbToYCbCr(p.r.toInt(), p.g.toInt(), p.b.toInt(), ycc);
    histY[ycc[0]]++; sumCb += ycc[1]; sumCr += ycc[2];
  }

  final targetMeanCb = sumCb / pixels, targetMeanCr = sumCr / pixels;
  double varCb = 0, varCr = 0;
  for (final p in small) {
    _rgbToYCbCr(p.r.toInt(), p.g.toInt(), p.b.toInt(), ycc);
    varCb += math.pow(ycc[1] - targetMeanCb, 2); varCr += math.pow(ycc[2] - targetMeanCr, 2);
  }
  final targetStdCb = math.sqrt(varCb / pixels), targetStdCr = math.sqrt(varCr / pixels);
  final lutY = _lutFromCdfs(_cdfFromHist(histY), _cdfFromHist(sig.histY));

  final out = target.clone();
  final w = out.width, h = out.height;
  final cx = w / 2, cy = h / 2, maxDist = math.sqrt(cx * cx + cy * cy);
  final rgb = List.filled(3, 0);

  // تجهيز الأقنعة (تطابق الحجم)
  img.Image? resizedMask;
  if (maskImage != null) resizedMask = img.copyResize(maskImage, width: w, height: h);

  img.Image? resizedAiMask;
  if (aiMaskImage != null) resizedAiMask = img.copyResize(aiMaskImage, width: w, height: h);

  // 🎛️ معالجة الأوضاع السحرية الأساسية
  double activeLumaTransfer = cfg.lumaTransfer;
  double activeColorTransfer = cfg.colorTransfer;

  if (cfg.isColorTheft) { activeLumaTransfer = 0.0; activeColorTransfer = 1.2; }
  if (cfg.isLightTheft) { activeLumaTransfer = 1.0; activeColorTransfer = 0.0; }
  if (cfg.isStyleTheft) { activeLumaTransfer = 1.0; activeColorTransfer = 1.2; }
  if (cfg.isThemeTheft) { activeLumaTransfer = 0.2; activeColorTransfer = 0.8; }

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final p = out.getPixel(x, y);
      final or = p.r.toInt(), og = p.g.toInt(), ob = p.b.toInt();

      // حساب قوة الحماية بناءً على القناع اليدوي أو الذكاء الاصطناعي أو لون البشرة كخيار أخير
      double protectWeight = 0.0;
      if (resizedMask != null) {
        protectWeight = resizedMask.getPixelSafe(x, y).r / 255.0;
      } else if (resizedAiMask != null) {
        protectWeight = resizedAiMask.getPixelSafe(x, y).r / 255.0;
      } else {
        protectWeight = _getSkinWeightImproved(or, og, ob);
      }
      protectWeight *= cfg.skinProtect;

      _rgbToYCbCr(or, og, ob, ycc);
      int origY = ycc[0], cb = ycc[1], cr = ycc[2];

      // 1. معالجة الإضاءة (Luma) + HDR
      int currentY = origY;
      if (cfg.isHDR) currentY = (currentY < 128) ? currentY + (128 - currentY) ~/ 3 : currentY - (currentY - 128) ~/ 4;

      int targetLight = lutY[currentY];
      int newY = _clamp255((currentY * (1.0 - activeLumaTransfer)) + (targetLight * activeLumaTransfer));

      double yNorm = newY / 255.0;
      double contrastY = yNorm < 0.5 ? 2.0 * yNorm * yNorm : 1.0 - 2.0 * (1.0 - yNorm) * (1.0 - yNorm);
      newY = _clamp255((newY * (1.0 - (cfg.contrastBoost - 1.0))) + ((contrastY * 255.0) * (cfg.contrastBoost - 1.0)));

      // 2. معالجة الألوان (Chroma)
      double newCb = cb.toDouble(), newCr = cr.toDouble();

      if (cfg.isCyberpunk && protectWeight < 0.5) {
        // نيون خلفية
        newCb = 180.0;
        newCr = 200.0;
      } else if (cfg.isSepia) {
        // سيبيا كلاسيكية
        newCb = 110.0;
        newCr = 150.0;
      } else {
        // النقل الرياضي الذكي
        if (targetStdCb > 0 && targetStdCr > 0) {
          newCb = ((cb - targetMeanCb) * (sig.stdCb / targetStdCb)) + sig.meanCb;
          newCr = ((cr - targetMeanCr) * (sig.stdCr / targetStdCr)) + sig.meanCr;
        }
        newCb = cb + (newCb - cb) * activeColorTransfer;
        newCr = cr + (newCr - cr) * activeColorTransfer;
      }

      // 🎬 الوضع السينمائي الدقيق (Split Toning)
      if (cfg.isCinematic && protectWeight < 0.6) {
        if (newY > 128) {
          newCb -= 10; // هايلايت دافئ
          newCr += 15;
        } else {
          newCb += 20; // ظلال باردة
          newCr -= 5;
        }
      }

      // 🎭 سبلاش لوني
      if (cfg.isColorSplash) {
        newCb = newCb * protectWeight + 128.0 * (1.0 - protectWeight);
        newCr = newCr * protectWeight + 128.0 * (1.0 - protectWeight);
      }

      _yCbCrToRgb(newY, newCb.round(), newCr.round(), rgb);
      int finalR = rgb[0], finalG = rgb[1], finalB = rgb[2];

      // 3. التعتيم والمزاج
      if (cfg.vignette > 0) {
        double dist = math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
        double vFactor = (1.0 - ((dist / maxDist) * cfg.vignette)).clamp(0.0, 1.0);
        vFactor = (vFactor + (protectWeight * cfg.vignette * 0.5)).clamp(0.0, 1.0);
        finalR = (finalR * vFactor).toInt(); finalG = (finalG * vFactor).toInt(); finalB = (finalB * vFactor).toInt();
      }
      if (cfg.grain > 0) {
        int noise = (((_fastHash(x, y) - 128) / 128.0) * (cfg.grain * 50)).toInt();
        finalR = _clamp255(finalR + noise); finalG = _clamp255(finalG + noise); finalB = _clamp255(finalB + noise);
      }

      // الدمج مع الأصل بناءً على حماية الشخص
      double finalStrength = cfg.strength * (1.0 - protectWeight);
      out.setPixelRgba(x, y,
          _clamp255(or + (finalR - or) * finalStrength),
          _clamp255(og + (finalG - og) * finalStrength),
          _clamp255(ob + (finalB - ob) * finalStrength),
          p.a.toInt()
      );
    }
  }
  return out;
}*/
