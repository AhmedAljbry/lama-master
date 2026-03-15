import 'dart:math' as math;
import 'package:image/image.dart' as img;

/// ============================================================
/// STYLE THEFT PRO++ V2 (CPU) - INTELLIGENT COLOR TRANSFER
/// ============================================================

enum TheftMode {
  full,
  lightOnly,
  colorOnly,
  moodOnly,
  proBlend,
}

class TheftConfig {
  final TheftMode mode;
  final double strength;
  final int analysisWidth;

  final double toneStrength;
  final double highlightProtect;
  final double shadowLift;
  final double microContrast;

  final double chromaStrength;
  final double vibrance;
  final double saturation;

  final double vignette;
  final double grain;
  final double splitStrength;

  const TheftConfig({
    this.mode = TheftMode.full,
    this.strength = 1.0,
    this.analysisWidth = 420,
    this.toneStrength = 0.95,
    this.highlightProtect = 0.80, // زيادة حماية الإضاءة
    this.shadowLift = 0.25,       // تفتيح ظلال أفضل
    this.microContrast = 0.50,    // تباين دقيق أقوى
    this.chromaStrength = 0.90,
    this.vibrance = 0.30,
    this.saturation = 0.10,
    this.vignette = 0.20,
    this.grain = 0.04,
    this.splitStrength = 0.40,
  });
}

/// البصمة الجينية للفلتر (تم إضافة الإحصائيات الذكية)
class TheftSignature {
  final List<int> histY, histCb, histCr;
  final int yP1, yP50, yP99;

  // إحصائيات النقل الذكي (Reinhard)
  final double meanY, meanCb, meanCr;
  final double stdY, stdCb, stdCr;

  const TheftSignature({
    required this.histY, required this.histCb, required this.histCr,
    required this.yP1, required this.yP50, required this.yP99,
    required this.meanY, required this.meanCb, required this.meanCr,
    required this.stdY, required this.stdCb, required this.stdCr,
  });
}

/// ---------- أدوات مساعدة ----------
int _clamp255(num v) => v < 0 ? 0 : (v > 255 ? 255 : v.toInt());
double _clamp01(double v) => v < 0.0 ? 0.0 : (v > 1.0 ? 1.0 : v);

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

// أداة جديدة: تنعيم المصفوفة لمنع تشوه الألوان
List<int> _smoothLut(List<int> lut) {
  final smoothed = List<int>.filled(256, 0);
  for (int i = 0; i < 256; i++) {
    int sum = 0;
    int count = 0;
    for (int j = math.max(0, i - 2); j <= math.min(255, i + 2); j++) {
      sum += lut[j];
      count++;
    }
    smoothed[i] = (sum / count).round();
  }
  return smoothed;
}

List<double> _cdfFromHist(List<int> hist) {
  final total = hist.fold<int>(0, (a, b) => a + b);
  if (total == 0) return List.filled(256, 0.0);
  final cdf = List<double>.filled(256, 0.0);
  int cum = 0;
  for (int i = 0; i < 256; i++) {
    cum += hist[i];
    cdf[i] = cum / total;
  }
  return cdf;
}

List<int> _lutFromCdfs(List<double> src, List<double> ref) {
  final lut = List<int>.filled(256, 0);
  int j = 0;
  for (int i = 0; i < 256; i++) {
    while (j < 255 && ref[j] < src[i]) j++;
    lut[i] = j;
  }
  return _smoothLut(lut); // تطبيق التنعيم لنتيجة احترافية
}

int _percentileFromHist(List<int> hist, double p01) {
  final total = hist.fold<int>(0, (a, b) => a + b);
  if (total <= 0) return 128;
  final target = (total * p01).round();
  int cum = 0;
  for (int i = 0; i < 256; i++) {
    cum += hist[i];
    if (cum >= target) return i;
  }
  return 255;
}

/// ------------------------------------------------------------
/// Core Processing - المعالجة الأساسية
/// ------------------------------------------------------------

// 1. تحليل الصورة المرجعية (استخراج الفلتر بذكاء)
TheftSignature analyzeReferenceProPP(img.Image ref, {TheftConfig cfg = const TheftConfig()}) {
  final small = img.copyResize(ref, width: cfg.analysisWidth);
  final histY = List.filled(256, 0), histCb = List.filled(256, 0), histCr = List.filled(256, 0);

  double sumY = 0, sumCb = 0, sumCr = 0;
  final ycc = List.filled(3, 0);
  final pixels = small.width * small.height;

  // جمع البيانات
  for (final p in small) {
    _rgbToYCbCr(p.r.toInt(), p.g.toInt(), p.b.toInt(), ycc);
    histY[ycc[0]]++; histCb[ycc[1]]++; histCr[ycc[2]]++;
    sumY += ycc[0]; sumCb += ycc[1]; sumCr += ycc[2];
  }

  // حساب المتوسطات (الذكاء الإحصائي)
  final meanY = sumY / pixels;
  final meanCb = sumCb / pixels;
  final meanCr = sumCr / pixels;

  // حساب الانحراف المعياري (قوة الألوان)
  double varY = 0, varCb = 0, varCr = 0;
  for (final p in small) {
    _rgbToYCbCr(p.r.toInt(), p.g.toInt(), p.b.toInt(), ycc);
    varY += math.pow(ycc[0] - meanY, 2);
    varCb += math.pow(ycc[1] - meanCb, 2);
    varCr += math.pow(ycc[2] - meanCr, 2);
  }

  return TheftSignature(
    histY: histY, histCb: histCb, histCr: histCr,
    yP1: _percentileFromHist(histY, 0.01),
    yP50: _percentileFromHist(histY, 0.50),
    yP99: _percentileFromHist(histY, 0.99),
    meanY: meanY, meanCb: meanCb, meanCr: meanCr,
    stdY: math.sqrt(varY / pixels),
    stdCb: math.sqrt(varCb / pixels),
    stdCr: math.sqrt(varCr / pixels),
  );
}

// 2. تطبيق الفلتر على صورتك
img.Image applyTheftProPP({required img.Image target, required TheftSignature sig, TheftConfig cfg = const TheftConfig()}) {
  if (cfg.strength <= 0) return target.clone();

  final small = img.copyResize(target, width: cfg.analysisWidth);
  final histY = List.filled(256, 0), histCb = List.filled(256, 0), histCr = List.filled(256, 0);
  final ycc = List.filled(3, 0);

  double sumY = 0, sumCb = 0, sumCr = 0;
  final pixels = small.width * small.height;

  for (final p in small) {
    _rgbToYCbCr(p.r.toInt(), p.g.toInt(), p.b.toInt(), ycc);
    histY[ycc[0]]++; histCb[ycc[1]]++; histCr[ycc[2]]++;
    sumY += ycc[0]; sumCb += ycc[1]; sumCr += ycc[2];
  }

  // إحصائيات الصورة الهدف
  final targetMeanY = sumY / pixels;
  final targetMeanCb = sumCb / pixels;
  final targetMeanCr = sumCr / pixels;

  double varY = 0, varCb = 0, varCr = 0;
  for (final p in small) {
    _rgbToYCbCr(p.r.toInt(), p.g.toInt(), p.b.toInt(), ycc);
    varY += math.pow(ycc[0] - targetMeanY, 2);
    varCb += math.pow(ycc[1] - targetMeanCb, 2);
    varCr += math.pow(ycc[2] - targetMeanCr, 2);
  }
  final targetStdY = math.sqrt(varY / pixels);
  final targetStdCb = math.sqrt(varCb / pixels);
  final targetStdCr = math.sqrt(varCr / pixels);

  final lutY = _lutFromCdfs(_cdfFromHist(histY), _cdfFromHist(sig.histY));

  final out = target.clone();
  final w = out.width, h = out.height;
  final rgb = List.filled(3, 0);

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final p = out.getPixel(x, y);
      final or = p.r.toInt(), og = p.g.toInt(), ob = p.b.toInt();

      _rgbToYCbCr(or, og, ob, ycc);
      int yy = ycc[0], cb = ycc[1], cr = ycc[2];

      // 1. تعديل الإضاءة (استخدام LUT المنعم)
      yy = lutY[yy];

      // 2. النقل اللوني الذكي (Reinhard Method) للحصول على ألوان نقية
      if (targetStdCb > 0 && targetStdCr > 0) {
        double newCb = ((cb - targetMeanCb) * (sig.stdCb / targetStdCb)) + sig.meanCb;
        double newCr = ((cr - targetMeanCr) * (sig.stdCr / targetStdCr)) + sig.meanCr;

        // دمج اللون بذكاء حسب قوة الفلتر (Chroma Strength)
        cb = _clamp255(cb + (newCb - cb) * cfg.chromaStrength);
        cr = _clamp255(cr + (newCr - cr) * cfg.chromaStrength);
      }

      // تحويل الصورة مرة أخرى إلى RGB
      _yCbCrToRgb(yy, cb, cr, rgb);

      // دمج نهائي للصورة الناتجة مع الصورة الأصلية بناءً على القوة (Strength)
      out.setPixelRgba(x, y,
          _clamp255(or + (rgb[0] - or) * cfg.strength),
          _clamp255(og + (rgb[1] - og) * cfg.strength),
          _clamp255(ob + (rgb[2] - ob) * cfg.strength),
          p.a.toInt()
      );
    }
  }

  return out;


}