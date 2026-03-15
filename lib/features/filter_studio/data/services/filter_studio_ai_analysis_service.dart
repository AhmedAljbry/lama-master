import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:lama/features/filter_studio/domain/entities/app_preset.dart';
import 'package:lama/features/filter_studio/domain/entities/filter_params.dart';
import 'package:lama/features/filter_studio/domain/entities/filter_studio_ai_insight.dart';

class FilterStudioAiAnalysisService {
  const FilterStudioAiAnalysisService();

  Future<FilterStudioAiInsight> generateInsight(
    Uint8List bytes,
    String languageCode,
  ) async {
    final result = await compute(_analyzeFilterStudioInsight, <String, Object>{
      'bytes': bytes,
      'languageCode': languageCode,
    });

    return FilterStudioAiInsight(
      headline: result['headline']! as String,
      summary: result['summary']! as String,
      sceneLabel: result['sceneLabel']! as String,
      moodLabel: result['moodLabel']! as String,
      lightingLabel: result['lightingLabel']! as String,
      recommendedPreset: AppPreset.values.byName(
        result['recommendedPreset']! as String,
      ),
      alternatePresets: (result['alternatePresets']! as List<Object>)
          .cast<String>()
          .map(AppPreset.values.byName)
          .toList(),
      confidence: result['confidence']! as double,
      subjectFocus: result['subjectFocus']! as double,
      colorEnergy: result['colorEnergy']! as double,
      dynamicRange: result['dynamicRange']! as double,
      recipe: _recipeFromMap(
        result['recipe']! as Map<Object?, Object?>,
      ),
    );
  }

  FilterParams _recipeFromMap(Map<Object?, Object?> map) {
    return FilterParams(
      contrast: map['contrast']! as double,
      saturation: map['saturation']! as double,
      exposure: map['exposure']! as double,
      brightness: map['brightness']! as double,
      warmth: map['warmth']! as double,
      tint: map['tint']! as double,
      blur: map['blur']! as double,
      aura: map['aura']! as double,
      auraColor: Color(map['auraColor']! as int),
      grain: map['grain']! as double,
      scanlines: map['scanlines']! as double,
      glitch: map['glitch']! as double,
      ghost: map['ghost']! as bool,
      colorPop: map['colorPop']! as bool,
      overlayColor: map['overlayColor'] == null
          ? null
          : Color(map['overlayColor']! as int),
      replaceBackground: map['replaceBackground']! as bool,
      showDateStamp: map['showDateStamp']! as bool,
      cinemaMode: map['cinemaMode']! as bool,
      polaroidFrame: map['polaroidFrame']! as bool,
      vignette: map['vignette']! as double,
      lightLeakIndex: map['lightLeakIndex']! as int,
      prismOverlay: map['prismOverlay']! as double,
      dustOverlay: map['dustOverlay']! as double,
    );
  }
}

Map<String, Object> _analyzeFilterStudioInsight(Map<String, Object> input) {
  final bytes = input['bytes']! as Uint8List;
  final languageCode = input['languageCode']! as String;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw Exception('decodeImage failed');
  }

  final resized = img.copyResize(decoded, width: 192);
  final width = resized.width;
  final height = resized.height;
  final centerLeft = width * 0.28;
  final centerRight = width * 0.72;
  final centerTop = height * 0.22;
  final centerBottom = height * 0.78;

  var sumY = 0.0;
  var sumY2 = 0.0;
  var sumSat = 0.0;
  var sumWarm = 0.0;
  var vividPixels = 0;
  var darkPixels = 0;
  var brightPixels = 0;
  var count = 0;

  var centerY = 0.0;
  var centerSat = 0.0;
  var centerCount = 0;
  var edgeEnergy = 0.0;
  var centerEdgeEnergy = 0.0;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixel = resized.getPixel(x, y);
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
      count++;

      if (sat > 0.48) {
        vividPixels++;
      }
      if (luma < 58) {
        darkPixels++;
      }
      if (luma > 208) {
        brightPixels++;
      }

      final isCenter = x >= centerLeft &&
          x <= centerRight &&
          y >= centerTop &&
          y <= centerBottom;
      if (isCenter) {
        centerY += luma;
        centerSat += sat;
        centerCount++;
      }

      if (x > 0 && y > 0) {
        final left = resized.getPixel(x - 1, y);
        final top = resized.getPixel(x, y - 1);
        final edge = ((red - left.r).abs() +
                (green - left.g).abs() +
                (blue - left.b).abs() +
                (red - top.r).abs() +
                (green - top.g).abs() +
                (blue - top.b).abs()) /
            6.0;
        edgeEnergy += edge;
        if (isCenter) {
          centerEdgeEnergy += edge;
        }
      }
    }
  }

  final meanY = count == 0 ? 128.0 : sumY / count;
  final variance = count == 0 ? 0.0 : (sumY2 / count) - (meanY * meanY);
  final stdY = variance <= 0 ? 0.0 : math.sqrt(variance);
  final meanSat = count == 0 ? 0.0 : sumSat / count;
  final warmBias = count == 0 ? 0.0 : sumWarm / count;
  final vividRatio = count == 0 ? 0.0 : vividPixels / count;
  final darkRatio = count == 0 ? 0.0 : darkPixels / count;
  final brightRatio = count == 0 ? 0.0 : brightPixels / count;
  final meanCenterY = centerCount == 0 ? meanY : centerY / centerCount;
  final meanCenterSat = centerCount == 0 ? meanSat : centerSat / centerCount;
  final edgeScore = count == 0 ? 0.0 : edgeEnergy / count;
  final centerEdgeScore =
      centerCount == 0 ? edgeScore : centerEdgeEnergy / centerCount;

  final subjectFocus =
      (((centerEdgeScore / math.max(edgeScore, 0.001)) * 0.58) +
              ((meanCenterSat / math.max(meanSat, 0.05)) * 0.42))
          .clamp(0.0, 1.0)
          .toDouble();
  final colorEnergy =
      ((meanSat * 0.74) + (vividRatio * 0.26)).clamp(0.0, 1.0).toDouble();
  final dynamicRange = (stdY / 72.0).clamp(0.0, 1.0).toDouble();
  final confidence = (0.56 +
          (subjectFocus * 0.14) +
          (colorEnergy * 0.14) +
          (dynamicRange * 0.16))
      .clamp(0.55, 0.97)
      .toDouble();

  final isArabic = languageCode == 'ar';
  final isLowLight = meanY < 96 || darkRatio > 0.32;
  final isHighKey = meanY > 176 || brightRatio > 0.26;
  final isVivid = colorEnergy > 0.34;
  final isWarm = warmBias > 0.08;
  final isCool = warmBias < -0.07;
  final isDramatic = dynamicRange > 0.68;
  final isPortraitLike = subjectFocus > 0.72 && meanCenterY > meanY * 0.92;

  late String sceneLabel;
  late String moodLabel;
  late String lightingLabel;
  late String headline;
  late String summary;
  late AppPreset recommendedPreset;
  late List<AppPreset> alternatePresets;
  late Map<String, Object?> recipe;

  if (isLowLight && isDramatic) {
    sceneLabel = isArabic ? 'ليلي سينمائي' : 'Night cinematic';
    moodLabel = isArabic ? 'درامي' : 'Dramatic';
    lightingLabel = isArabic ? 'إضاءة منخفضة' : 'Low light';
    headline = isArabic
        ? 'اللقطة تحتاج معالجة سينمائية تحافظ على التفاصيل داخل الظلال'
        : 'This frame wants a cinematic recovery that keeps shadow detail alive';
    summary = isArabic
        ? 'وجهة Pro Studio رصدت تباينًا قويًا مع إضاءة منخفضة، لذلك الاتجاه الأفضل هو Cinematic مع عمق إضافي، Grain محسوب، ولمسة سينمائية واضحة.'
        : 'Pro Studio detected strong contrast inside a dark frame, so the best direction is a cinematic grade with added depth, measured grain, and clearer screen presence.';
    recommendedPreset = AppPreset.cinematic;
    alternatePresets = const [
      AppPreset.noir,
      AppPreset.street,
      AppPreset.chrome,
    ];
    recipe = _recipeMap(
      contrast: 1.16,
      saturation: 1.02,
      exposure: 0.10,
      brightness: 0.06,
      warmth: isWarm ? 0.06 : -0.02,
      blur: 0.2,
      aura: 0.0,
      grain: 0.14,
      scanlines: 0.06,
      glitch: 0.0,
      colorPop: false,
      ghost: false,
      vignette: 0.22,
      cinemaMode: true,
      lightLeakIndex: 0,
      dustOverlay: 0.10,
    );
  } else if (isPortraitLike && isWarm) {
    sceneLabel = isArabic ? 'بورتريه' : 'Portrait';
    moodLabel = isArabic ? 'دافئ فاخر' : 'Warm premium';
    lightingLabel = isArabic ? 'ضوء ناعم' : 'Soft light';
    headline = isArabic
        ? 'المشهد مناسب لمعالجة بورتريه ناعمة مع هالة حديثة'
        : 'The scene is ideal for a soft portrait treatment with a modern halo';
    summary = isArabic
        ? 'التركيز في المنتصف واضح، ودرجات اللون تميل للدفء، لذلك أوصي بـ Halo لنتيجة معاصرة، مع فصل لطيف للخلفية وتوهج محسوب.'
        : 'Center focus is strong and the palette already leans warm, so Halo is recommended for a contemporary portrait finish with gentle separation and controlled glow.';
    recommendedPreset = AppPreset.halo;
    alternatePresets = const [
      AppPreset.warm,
      AppPreset.editorial,
      AppPreset.dreamy,
    ];
    recipe = _recipeMap(
      contrast: 1.08,
      saturation: 1.10,
      exposure: 0.04,
      brightness: 0.02,
      warmth: 0.14,
      tint: 0.02,
      blur: 3.2,
      aura: 0.42,
      auraColor: const Color(0xFFFFC46B),
      grain: 0.05,
      scanlines: 0.0,
      glitch: 0.0,
      colorPop: false,
      ghost: false,
      overlayColor: const Color(0x14FFB06B),
      vignette: 0.12,
      lightLeakIndex: 1,
      prismOverlay: 0.08,
      dustOverlay: 0.02,
    );
  } else if (isVivid && isCool) {
    sceneLabel = isArabic ? 'حضري نابض' : 'Urban vivid';
    moodLabel = isArabic ? 'مستقبلي' : 'Futuristic';
    lightingLabel = isArabic ? 'نيون بارد' : 'Cool neon';
    headline = isArabic
        ? 'الألوان جاهزة لمعالجة جريئة بطابع Vaporwave وCyber'
        : 'The palette is ready for a bold Vaporwave-to-Cyber direction';
    summary = isArabic
        ? 'الصورة مشبعة ومائلة للبرودة، وهذا يجعلها ممتازة لمظهر حديث يجمع بين الإضاءة الوردية والسماوية مع Glitch خفيف.'
        : 'The frame is already saturated and cool-toned, which makes it ideal for a modern look that blends pink-cyan light with subtle glitch energy.';
    recommendedPreset = AppPreset.vaporwave;
    alternatePresets = const [
      AppPreset.cyber,
      AppPreset.neon,
      AppPreset.chrome,
    ];
    recipe = _recipeMap(
      contrast: 1.14,
      saturation: 1.20,
      exposure: 0.02,
      brightness: 0.00,
      warmth: -0.08,
      tint: 0.08,
      blur: 1.8,
      aura: 0.36,
      auraColor: const Color(0xFFFF58C9),
      grain: 0.06,
      scanlines: 0.08,
      glitch: 1.10,
      colorPop: false,
      ghost: false,
      overlayColor: const Color(0x1600D7FF),
      vignette: 0.10,
      lightLeakIndex: 2,
      prismOverlay: 0.24,
    );
  } else if (isHighKey && !isDramatic) {
    sceneLabel = isArabic ? 'نظيف إعلاني' : 'Clean editorial';
    moodLabel = isArabic ? 'مرتب' : 'Polished';
    lightingLabel = isArabic ? 'هاي كي' : 'High key';
    headline = isArabic
        ? 'هذه اللقطة ممتازة لمعالجة Editorial نظيفة وراقية'
        : 'This frame is a great fit for a clean and elevated editorial grade';
    summary = isArabic
        ? 'الإضاءة مرتفعة ومتوازنة نسبيًا، لذلك الأفضل الحفاظ على النقاء مع Contrast رشيق وألوان مضبوطة بدون مبالغة.'
        : 'The frame is bright and fairly balanced, so the best move is to preserve its cleanliness with refined contrast and restrained color styling.';
    recommendedPreset = AppPreset.editorial;
    alternatePresets = const [
      AppPreset.chrome,
      AppPreset.halo,
      AppPreset.cinematic,
      AppPreset.original,
    ];
    recipe = _recipeMap(
      contrast: 1.08,
      saturation: 1.04,
      exposure: -0.02,
      brightness: -0.01,
      warmth: isWarm ? 0.04 : 0.0,
      blur: 0.0,
      aura: 0.0,
      grain: 0.03,
      scanlines: 0.0,
      glitch: 0.0,
      colorPop: false,
      ghost: false,
      vignette: 0.06,
      lightLeakIndex: 0,
      prismOverlay: 0.04,
    );
  } else if (isVivid && isDramatic) {
    sceneLabel = isArabic ? 'شارع إبداعي' : 'Creative street';
    moodLabel = isArabic ? 'حاد' : 'Punchy';
    lightingLabel = isArabic ? 'مختلط' : 'Mixed light';
    headline = isArabic
        ? 'الاتجاه الأنسب هنا هو Street مع لمسة حدة وطبقات ضوئية'
        : 'The best direction here is Street with more edge and layered light';
    summary = isArabic
        ? 'الصورة تحمل طاقة لونية وحركة واضحة، لذلك أوصي بـ Street ليبرز التفاصيل ويعطي طابعًا عصريًا مناسبًا للسوشال والمشاهد الحضرية.'
        : 'The image already carries color energy and visible motion, so Street is recommended to push detail and give it a modern, social-first urban look.';
    recommendedPreset = AppPreset.street;
    alternatePresets = const [
      AppPreset.cinematic,
      AppPreset.chrome,
      AppPreset.cyber,
      AppPreset.vintage,
    ];
    recipe = _recipeMap(
      contrast: 1.18,
      saturation: 1.12,
      exposure: 0.02,
      brightness: 0.01,
      warmth: isWarm ? 0.04 : -0.02,
      blur: 0.6,
      aura: 0.12,
      auraColor: const Color(0xFF88F7FF),
      grain: 0.14,
      scanlines: 0.18,
      glitch: 0.30,
      colorPop: false,
      ghost: false,
      overlayColor: const Color(0x0DFFFFFF),
      vignette: 0.18,
      cinemaMode: true,
      lightLeakIndex: 1,
      prismOverlay: 0.10,
      dustOverlay: 0.08,
    );
  } else {
    sceneLabel = isArabic ? 'متوازن' : 'Balanced';
    moodLabel = isArabic ? 'معاصر' : 'Modern';
    lightingLabel = isArabic
        ? (meanCenterY > meanY ? 'مركزي' : 'طبيعي')
        : (meanCenterY > meanY ? 'Center-lit' : 'Natural');
    headline = isArabic
        ? 'أفضل معالجة هنا هي Chrome نظيفة مع مساحة للتخصيص'
        : 'Chrome is the cleanest starting point here with room to customize';
    summary = isArabic
        ? 'المشهد متوازن، لذلك أقترح قاعدة حديثة ومرنة تمنحك وضوحًا ولمسة برو بدون أن تقيدك في أسلوب واحد.'
        : 'The frame is versatile, so a modern and flexible Chrome base will give you clarity and a premium look without locking you into one style.';
    recommendedPreset = AppPreset.chrome;
    alternatePresets = const [
      AppPreset.editorial,
      AppPreset.cinematic,
      AppPreset.dreamy,
      AppPreset.warm,
    ];
    recipe = _recipeMap(
      contrast: 1.12,
      saturation: 1.08,
      exposure: 0.02,
      brightness: 0.00,
      warmth: warmBias.clamp(-0.05, 0.08).toDouble(),
      blur: 0.0,
      aura: 0.0,
      grain: 0.04,
      scanlines: 0.0,
      glitch: 0.0,
      colorPop: false,
      ghost: false,
      vignette: 0.08,
      lightLeakIndex: 0,
      prismOverlay: 0.03,
      dustOverlay: 0.02,
    );
  }

  final alternates = <AppPreset>{
    recommendedPreset,
    ...alternatePresets,
  }.toList();

  return <String, Object>{
    'headline': headline,
    'summary': summary,
    'sceneLabel': sceneLabel,
    'moodLabel': moodLabel,
    'lightingLabel': lightingLabel,
    'recommendedPreset': recommendedPreset.name,
    'alternatePresets': alternates.map((preset) => preset.name).toList(),
    'confidence': confidence,
    'subjectFocus': subjectFocus,
    'colorEnergy': colorEnergy,
    'dynamicRange': dynamicRange,
    'recipe': recipe,
  };
}

int _encodeColor(Color color) {
  int channel(double value) => (value * 255).round().clamp(0, 255);

  return (channel(color.a) << 24) |
      (channel(color.r) << 16) |
      (channel(color.g) << 8) |
      channel(color.b);
}

Map<String, Object?> _recipeMap({
  required double contrast,
  required double saturation,
  required double exposure,
  required double brightness,
  required double warmth,
  double tint = 0.0,
  double blur = 0.0,
  double aura = 0.0,
  Color auraColor = Colors.white,
  double grain = 0.0,
  double scanlines = 0.0,
  double glitch = 0.0,
  bool ghost = false,
  bool colorPop = false,
  Color? overlayColor,
  bool replaceBackground = false,
  bool showDateStamp = false,
  bool cinemaMode = false,
  bool polaroidFrame = false,
  double vignette = 0.0,
  int lightLeakIndex = 0,
  double prismOverlay = 0.0,
  double dustOverlay = 0.0,
}) {
  return {
    'contrast': contrast,
    'saturation': saturation,
    'exposure': exposure,
    'brightness': brightness,
    'warmth': warmth,
    'tint': tint,
    'blur': blur,
    'aura': aura,
    'auraColor': _encodeColor(auraColor),
    'grain': grain,
    'scanlines': scanlines,
    'glitch': glitch,
    'ghost': ghost,
    'colorPop': colorPop,
    'overlayColor': overlayColor == null ? null : _encodeColor(overlayColor),
    'replaceBackground': replaceBackground,
    'showDateStamp': showDateStamp,
    'cinemaMode': cinemaMode,
    'polaroidFrame': polaroidFrame,
    'vignette': vignette,
    'lightLeakIndex': lightLeakIndex,
    'prismOverlay': prismOverlay,
    'dustOverlay': dustOverlay,
  };
}
