class TheftConfig {
  final double strength;
  final double skinProtect;
  final double lumaTransfer;
  final double colorTransfer;
  final double contrastBoost;
  final double vignette;
  final double grain;
  final bool isCinematic;
  final bool isColorTheft;
  final bool isLightTheft;
  final bool isStyleTheft;
  final bool isThemeTheft;
  final bool isColorSplash;
  final bool isHDR;
  final bool isCyberpunk;
  final bool isSepia;

  const TheftConfig({
    this.strength = 1.0,
    this.skinProtect = 0.85,
    this.lumaTransfer = 0.3,
    this.colorTransfer = 1.0,
    this.contrastBoost = 1.15,
    this.vignette = 0.3,
    this.grain = 0.1,
    this.isCinematic = false,
    this.isColorTheft = false,
    this.isLightTheft = false,
    this.isStyleTheft = false,
    this.isThemeTheft = false,
    this.isColorSplash = false,
    this.isHDR = false,
    this.isCyberpunk = false,
    this.isSepia = false,
  });

  Map<String, dynamic> toMap() => {
        'strength': strength,
        'skinProtect': skinProtect,
        'lumaTransfer': lumaTransfer,
        'colorTransfer': colorTransfer,
        'contrastBoost': contrastBoost,
        'vignette': vignette,
        'grain': grain,
        'isCinematic': isCinematic,
        'isColorTheft': isColorTheft,
        'isLightTheft': isLightTheft,
        'isStyleTheft': isStyleTheft,
        'isThemeTheft': isThemeTheft,
        'isColorSplash': isColorSplash,
        'isHDR': isHDR,
        'isCyberpunk': isCyberpunk,
        'isSepia': isSepia,
      };

  factory TheftConfig.fromMap(Map<String, dynamic> map) => TheftConfig(
        strength: (map['strength'] as num?)?.toDouble() ?? 1.0,
        skinProtect: (map['skinProtect'] as num?)?.toDouble() ?? 0.85,
        lumaTransfer: (map['lumaTransfer'] as num?)?.toDouble() ?? 0.3,
        colorTransfer: (map['colorTransfer'] as num?)?.toDouble() ?? 1.0,
        contrastBoost: (map['contrastBoost'] as num?)?.toDouble() ?? 1.15,
        vignette: (map['vignette'] as num?)?.toDouble() ?? 0.3,
        grain: (map['grain'] as num?)?.toDouble() ?? 0.1,
        isCinematic: map['isCinematic'] as bool? ?? false,
        isColorTheft: map['isColorTheft'] as bool? ?? false,
        isLightTheft: map['isLightTheft'] as bool? ?? false,
        isStyleTheft: map['isStyleTheft'] as bool? ?? false,
        isThemeTheft: map['isThemeTheft'] as bool? ?? false,
        isColorSplash: map['isColorSplash'] as bool? ?? false,
        isHDR: map['isHDR'] as bool? ?? false,
        isCyberpunk: map['isCyberpunk'] as bool? ?? false,
        isSepia: map['isSepia'] as bool? ?? false,
      );
}

class TheftSignature {
  final List<int> histY;
  final double meanCb;
  final double meanCr;
  final double stdCb;
  final double stdCr;

  const TheftSignature({
    required this.histY,
    required this.meanCb,
    required this.meanCr,
    required this.stdCb,
    required this.stdCr,
  });
}
