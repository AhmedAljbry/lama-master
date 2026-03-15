class AiFilterInsight {
  final String headline;
  final String summary;
  final String sceneLabel;
  final String moodLabel;
  final String suggestedName;
  final List<String> recommendedFilterIds;
  final double intensity;
  final double brightness;
  final double contrast;
  final double saturation;
  final double warmth;
  final double fade;

  const AiFilterInsight({
    required this.headline,
    required this.summary,
    required this.sceneLabel,
    required this.moodLabel,
    required this.suggestedName,
    required this.recommendedFilterIds,
    required this.intensity,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.warmth,
    required this.fade,
  });

  AiFilterInsight copyWith({
    String? headline,
    String? summary,
    String? sceneLabel,
    String? moodLabel,
    String? suggestedName,
    List<String>? recommendedFilterIds,
    double? intensity,
    double? brightness,
    double? contrast,
    double? saturation,
    double? warmth,
    double? fade,
  }) {
    return AiFilterInsight(
      headline: headline ?? this.headline,
      summary: summary ?? this.summary,
      sceneLabel: sceneLabel ?? this.sceneLabel,
      moodLabel: moodLabel ?? this.moodLabel,
      suggestedName: suggestedName ?? this.suggestedName,
      recommendedFilterIds: recommendedFilterIds ?? this.recommendedFilterIds,
      intensity: intensity ?? this.intensity,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      warmth: warmth ?? this.warmth,
      fade: fade ?? this.fade,
    );
  }
}
