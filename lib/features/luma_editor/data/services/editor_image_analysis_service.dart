import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:lama/features/luma_editor/domain/entities/ai_filter_insight.dart';
import 'package:lama/features/luma_editor/domain/entities/auto_enhance_profile.dart';

class EditorImageAnalysisService {
  const EditorImageAnalysisService();

  Future<AutoEnhanceProfile> analyzeAutoEnhance(Uint8List bytes) async {
    final result = await compute(_analyzeAutoEnhance, bytes);
    return AutoEnhanceProfile(
      brightness: result['brightness']!,
      contrast: result['contrast']!,
      saturation: result['saturation']!,
      warmth: result['warmth']!,
      fade: result['fade']!,
    );
  }

  Future<AiFilterInsight> generateCreativeInsight(
    Uint8List bytes,
    String languageCode,
  ) async {
    final result = await compute(_analyzeCreativeInsight, <String, Object>{
      'bytes': bytes,
      'languageCode': languageCode,
    });
    return AiFilterInsight(
      headline: result['headline']! as String,
      summary: result['summary']! as String,
      sceneLabel: result['sceneLabel']! as String,
      moodLabel: result['moodLabel']! as String,
      suggestedName: result['suggestedName']! as String,
      recommendedFilterIds:
          (result['recommendedFilterIds']! as List).cast<String>(),
      intensity: result['intensity']! as double,
      brightness: result['brightness']! as double,
      contrast: result['contrast']! as double,
      saturation: result['saturation']! as double,
      warmth: result['warmth']! as double,
      fade: result['fade']! as double,
    );
  }
}

Map<String, double> _analyzeAutoEnhance(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw Exception('decodeImage failed');
  }

  final small = img.copyResize(decoded, width: 256);
  var sumY = 0.0;
  var sumY2 = 0.0;
  var sumR = 0.0;
  var sumB = 0.0;
  var count = 0;

  for (var y = 0; y < small.height; y++) {
    for (var x = 0; x < small.width; x++) {
      final pixel = small.getPixel(x, y);
      final red = pixel.r.toInt();
      final green = pixel.g.toInt();
      final blue = pixel.b.toInt();
      final luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue;

      sumY += luma;
      sumY2 += luma * luma;
      sumR += red;
      sumB += blue;
      count++;
    }
  }

  final meanY = count == 0 ? 128.0 : sumY / count;
  final variance = count == 0 ? 0.0 : (sumY2 / count) - (meanY * meanY);
  final stdY = variance <= 0 ? 0.0 : math.sqrt(variance);
  final meanR = count == 0 ? 128.0 : sumR / count;
  final meanB = count == 0 ? 128.0 : sumB / count;

  return <String, double>{
    'brightness': ((132.0 - meanY) / 255.0).clamp(-0.22, 0.28),
    'contrast': ((68.0 - stdY) / 70.0).clamp(-0.10, 0.42),
    'saturation': ((72.0 - stdY) / 170.0).clamp(0.0, 0.24),
    'warmth':
        (((meanB - meanR) / 255.0).clamp(-1.0, 1.0) * 0.40).clamp(-0.28, 0.28),
    'fade': 0.035,
  };
}

Map<String, Object> _analyzeCreativeInsight(Map<String, Object> input) {
  final bytes = input['bytes']! as Uint8List;
  final languageCode = input['languageCode']! as String;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw Exception('decodeImage failed');
  }

  final small = img.copyResize(decoded, width: 192);
  var sumY = 0.0;
  var sumY2 = 0.0;
  var sumSat = 0.0;
  var sumWarm = 0.0;
  var vividPixels = 0;
  var count = 0;

  for (var y = 0; y < small.height; y++) {
    for (var x = 0; x < small.width; x++) {
      final pixel = small.getPixel(x, y);
      final red = pixel.r.toDouble();
      final green = pixel.g.toDouble();
      final blue = pixel.b.toDouble();
      final luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue;
      final maxChannel = math.max(red, math.max(green, blue));
      final minChannel = math.min(red, math.min(green, blue));
      final sat =
          maxChannel == 0 ? 0.0 : (maxChannel - minChannel) / maxChannel;

      sumY += luma;
      sumY2 += luma * luma;
      sumSat += sat;
      sumWarm += (red - blue) / 255.0;
      if (sat > 0.48) {
        vividPixels++;
      }
      count++;
    }
  }

  final meanY = count == 0 ? 128.0 : sumY / count;
  final variance = count == 0 ? 0.0 : (sumY2 / count) - (meanY * meanY);
  final stdY = variance <= 0 ? 0.0 : math.sqrt(variance);
  final meanSat = count == 0 ? 0.0 : sumSat / count;
  final warmBias = count == 0 ? 0.0 : sumWarm / count;
  final vividRatio = count == 0 ? 0.0 : vividPixels / count;

  final isLowLight = meanY < 96;
  final isHighKey = meanY > 172;
  final isVivid = meanSat > 0.34 || vividRatio > 0.18;
  final isWarm = warmBias > 0.07;
  final isMoody = stdY > 54 || (isLowLight && stdY > 40);
  final isArabic = languageCode == 'ar';

  String sceneLabel;
  String moodLabel;
  String headline;
  String summary;
  String suggestedName;
  List<String> recommendedFilterIds;
  double intensity;
  double brightness;
  double contrast;
  double saturation;
  double warmth;
  double fade;

  if (isLowLight) {
    sceneLabel = isArabic ? 'إضاءة منخفضة' : 'Low light';
    moodLabel = isMoody
        ? (isArabic ? 'سينمائي' : 'Cinematic')
        : (isArabic ? 'استعادة نظيفة' : 'Clean recovery');
    headline = isArabic
        ? 'استرجاع تفاصيل الظلال بلمسة سينمائية متوازنة'
        : 'Recover shadow detail with a film-grade finish';
    summary = isArabic
        ? 'الصورة داكنة نسبيًا، لذلك يرفع المساعد السطوع بحذر ويقود المعالجة نحو تباين سينمائي محسوب.'
        : 'The frame is dark, so the assistant lifts brightness carefully and steers the grade toward cinematic contrast.';
    suggestedName = isArabic ? 'استعادة ليلية' : 'Night Recover';
    recommendedFilterIds = const [
      'base_cinema_4',
      'pro_034',
      'pro_074',
    ];
    intensity = 0.86;
    brightness = ((118.0 - meanY) / 255.0).clamp(0.08, 0.24).toDouble();
    contrast = ((64.0 - stdY) / 90.0).clamp(0.08, 0.24).toDouble();
    saturation = (0.10 + meanSat * 0.18).clamp(0.08, 0.22).toDouble();
    warmth = isWarm ? 0.06 : -0.03;
    fade = 0.04;
  } else if (isVivid && !isWarm) {
    sceneLabel = isArabic ? 'منظر طبيعي' : 'Landscape';
    moodLabel = isArabic ? 'حيوي' : 'Vivid';
    headline = isArabic
        ? 'تعزيز فصل الألوان مع الحفاظ على عمق المشهد'
        : 'Push color separation and preserve outdoor depth';
    summary = isArabic
        ? 'الألوان قوية أصلًا، لذلك يحافظ المساعد على حيوية الصورة مع تباين متوازن ولمسة برو أبرد قليلًا.'
        : 'The palette already has strong color energy, so the assistant keeps the scene lively with balanced contrast and cooler pro looks.';
    suggestedName = isArabic ? 'أفق حيوي' : 'Vivid Horizon';
    recommendedFilterIds = const [
      'pro_026',
      'base_cinema_2',
      'pro_066',
    ];
    intensity = 0.82;
    brightness = ((130.0 - meanY) / 255.0).clamp(-0.04, 0.12).toDouble();
    contrast = ((58.0 - stdY) / 110.0).clamp(0.02, 0.18).toDouble();
    saturation = (0.14 + vividRatio * 0.20).clamp(0.10, 0.24).toDouble();
    warmth = -0.05;
    fade = 0.02;
  } else if (isWarm) {
    sceneLabel = isArabic ? 'بورتريه' : 'Portrait';
    moodLabel = isArabic ? 'دافئ' : 'Warm';
    headline = isArabic
        ? 'بناء معالجة دافئة مناسبة للبورتريه'
        : 'Shape a warm portrait-ready grade';
    summary = isArabic
        ? 'الدفء مناسب للبشرة بالفعل، لذلك يحافظ المساعد على نعومة الدرجات مع تباين خفيف يعطي الصورة مظهرًا احترافيًا.'
        : 'Skin-friendly warmth is already present, so the assistant keeps tones soft while adding just enough contrast for polish.';
    suggestedName = isArabic ? 'بورتريه دافئ' : 'Warm Portrait';
    recommendedFilterIds = const [
      'base_retro_2',
      'pro_041',
      'pro_051',
    ];
    intensity = 0.78;
    brightness = ((138.0 - meanY) / 255.0).clamp(-0.02, 0.12).toDouble();
    contrast = ((62.0 - stdY) / 120.0).clamp(0.03, 0.16).toDouble();
    saturation = (0.06 + meanSat * 0.12).clamp(0.04, 0.18).toDouble();
    warmth = 0.12;
    fade = 0.05;
  } else if (isHighKey) {
    sceneLabel = isArabic ? 'استوديو' : 'Studio';
    moodLabel = isArabic ? 'نظيف' : 'Clean';
    headline = isArabic
        ? 'الحفاظ على صورة نظيفة وفاخرة بدون حرق الإضاءة'
        : 'Keep the image premium and product-clean';
    summary = isArabic
        ? 'الإطار ساطع أصلًا، لذلك يتجنب المساعد تكسير المناطق البيضاء ويتجه إلى معالجة نظيفة ومناسبة للمنتجات.'
        : 'The frame is already bright, so the assistant avoids crushing whites and leans into crisp, minimal grading.';
    suggestedName = isArabic ? 'نقاء الاستوديو' : 'Studio Clean';
    recommendedFilterIds = const [
      'base_original',
      'pro_005',
      'pro_015',
    ];
    intensity = 0.68;
    brightness = ((150.0 - meanY) / 255.0).clamp(-0.08, 0.02).toDouble();
    contrast = ((56.0 - stdY) / 120.0).clamp(0.02, 0.12).toDouble();
    saturation = (0.03 + meanSat * 0.08).clamp(0.02, 0.12).toDouble();
    warmth = 0.0;
    fade = 0.02;
  } else {
    sceneLabel = isArabic ? 'متوازن' : 'Balanced';
    moodLabel = isMoody
        ? (isArabic ? 'مزاجي' : 'Moody')
        : (isArabic ? 'تحريري' : 'Editorial');
    headline = isArabic
        ? 'موازنة التباين واللون والعمق لإخراج فاخر'
        : 'Balance contrast, color, and depth for a premium finish';
    summary = isArabic
        ? 'الصورة في نطاق متوسط مرن، لذلك يختار المساعد معالجة مصقولة مناسبة للسوشيال والبورتريه والمنتجات.'
        : 'The image sits in a versatile middle range, so the assistant chooses a polished grade that works for social, portraits, and products.';
    suggestedName = isArabic ? 'تدفق تحريري' : 'Editorial Flow';
    recommendedFilterIds = const [
      'base_cinema_3',
      'pro_032',
      'pro_072',
    ];
    intensity = 0.8;
    brightness = ((134.0 - meanY) / 255.0).clamp(-0.03, 0.10).toDouble();
    contrast = ((60.0 - stdY) / 110.0).clamp(0.04, 0.18).toDouble();
    saturation = (0.05 + meanSat * 0.10).clamp(0.04, 0.18).toDouble();
    warmth = warmBias.clamp(-0.08, 0.08).toDouble();
    fade = 0.03;
  }

  return <String, Object>{
    'headline': headline,
    'summary': summary,
    'sceneLabel': sceneLabel,
    'moodLabel': moodLabel,
    'suggestedName': suggestedName,
    'recommendedFilterIds': recommendedFilterIds,
    'intensity': intensity,
    'brightness': brightness,
    'contrast': contrast,
    'saturation': saturation,
    'warmth': warmth,
    'fade': fade,
  };
}
