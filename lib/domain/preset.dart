class Preset {
  final String name;
  final List<double> matrix;
  final int indicatorColor;

  final double intensity;
  final double brightness, contrast, saturation, warmth, fade;

  Preset({
    required this.name,
    required this.matrix,
    required this.indicatorColor,
    required this.intensity,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.warmth,
    required this.fade,
  });

  Map<String, dynamic> toJson() => {
    "name": name,
    "matrix": matrix,
    "indicatorColor": indicatorColor,
    "intensity": intensity,
    "brightness": brightness,
    "contrast": contrast,
    "saturation": saturation,
    "warmth": warmth,
    "fade": fade,
  };

  static Preset fromJson(Map<String, dynamic> j) => Preset(
    name: j["name"],
    matrix: (j["matrix"] as List).map((e) => (e as num).toDouble()).toList(),
    indicatorColor: j["indicatorColor"],
    intensity: (j["intensity"] as num).toDouble(),
    brightness: (j["brightness"] as num).toDouble(),
    contrast: (j["contrast"] as num).toDouble(),
    saturation: (j["saturation"] as num).toDouble(),
    warmth: (j["warmth"] as num).toDouble(),
    fade: (j["fade"] as num).toDouble(),
  );
}