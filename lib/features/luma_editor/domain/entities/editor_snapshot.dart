class EditorSnapshot {
  final String selectedId;
  final double filterIntensity;
  final double brightness;
  final double contrast;
  final double saturation;
  final double warmth;
  final double fade;

  const EditorSnapshot({
    required this.selectedId,
    required this.filterIntensity,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.warmth,
    required this.fade,
  });

  EditorSnapshot copyWith({
    String? selectedId,
    double? filterIntensity,
    double? brightness,
    double? contrast,
    double? saturation,
    double? warmth,
    double? fade,
  }) {
    return EditorSnapshot(
      selectedId: selectedId ?? this.selectedId,
      filterIntensity: filterIntensity ?? this.filterIntensity,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      warmth: warmth ?? this.warmth,
      fade: fade ?? this.fade,
    );
  }
}
