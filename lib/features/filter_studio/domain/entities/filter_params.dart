import 'package:flutter/material.dart';

class FilterParams {
  static const Object _unset = Object();

  final int selectedTabIndex;
  final double contrast;
  final double saturation;
  final bool subjectMaskEnabled;
  final bool replaceBackground;
  final double exposure;
  final double brightness;
  final double warmth;
  final double tint;
  final double highlights;
  final double shadows;
  final double clarity;
  final double dehaze;
  final double sharpen;
  final double vignetteSize;
  final double blur;
  final double aura;
  final Color auraColor;
  final double grain;
  final double scanlines;
  final double glitch;
  final bool ghost;
  final bool colorPop;
  final Color? overlayColor;
  final bool showDateStamp;
  final bool cinemaMode;
  final bool polaroidFrame;
  final double vignette;
  final int lightLeakIndex;
  final double prismOverlay;
  final double dustOverlay;

  const FilterParams({
    this.selectedTabIndex = 0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.subjectMaskEnabled = false,
    this.replaceBackground = false,
    this.exposure = 0.0,
    this.brightness = 0.0,
    this.warmth = 0.0,
    this.tint = 0.0,
    this.highlights = 0.0,
    this.shadows = 0.0,
    this.clarity = 0.0,
    this.dehaze = 0.0,
    this.sharpen = 0.0,
    this.vignetteSize = 0.5,
    this.blur = 0.0,
    this.aura = 0.0,
    this.auraColor = Colors.white,
    this.grain = 0.0,
    this.scanlines = 0.0,
    this.glitch = 0.0,
    this.ghost = false,
    this.colorPop = false,
    this.overlayColor,
    this.showDateStamp = false,
    this.cinemaMode = false,
    this.polaroidFrame = false,
    this.vignette = 0.0,
    this.lightLeakIndex = 0,
    this.prismOverlay = 0.0,
    this.dustOverlay = 0.0,
  });

  FilterParams copyWith({
    int? selectedTabIndex,
    double? contrast,
    double? saturation,
    bool? subjectMaskEnabled,
    bool? replaceBackground,
    double? exposure,
    double? brightness,
    double? warmth,
    double? tint,
    double? highlights,
    double? shadows,
    double? clarity,
    double? dehaze,
    double? sharpen,
    double? vignetteSize,
    double? blur,
    double? aura,
    Color? auraColor,
    double? grain,
    double? scanlines,
    double? glitch,
    bool? ghost,
    bool? colorPop,
    Object? overlayColor = _unset,
    bool? showDateStamp,
    bool? cinemaMode,
    bool? polaroidFrame,
    double? vignette,
    int? lightLeakIndex,
    double? prismOverlay,
    double? dustOverlay,
  }) {
    return FilterParams(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      subjectMaskEnabled: subjectMaskEnabled ?? this.subjectMaskEnabled,
      replaceBackground: replaceBackground ?? this.replaceBackground,
      exposure: exposure ?? this.exposure,
      brightness: brightness ?? this.brightness,
      warmth: warmth ?? this.warmth,
      tint: tint ?? this.tint,
      highlights: highlights ?? this.highlights,
      shadows: shadows ?? this.shadows,
      clarity: clarity ?? this.clarity,
      dehaze: dehaze ?? this.dehaze,
      sharpen: sharpen ?? this.sharpen,
      vignetteSize: vignetteSize ?? this.vignetteSize,
      blur: blur ?? this.blur,
      aura: aura ?? this.aura,
      auraColor: auraColor ?? this.auraColor,
      grain: grain ?? this.grain,
      scanlines: scanlines ?? this.scanlines,
      glitch: glitch ?? this.glitch,
      ghost: ghost ?? this.ghost,
      colorPop: colorPop ?? this.colorPop,
      overlayColor: identical(overlayColor, _unset)
          ? this.overlayColor
          : overlayColor as Color?,
      showDateStamp: showDateStamp ?? this.showDateStamp,
      cinemaMode: cinemaMode ?? this.cinemaMode,
      polaroidFrame: polaroidFrame ?? this.polaroidFrame,
      vignette: vignette ?? this.vignette,
      lightLeakIndex: lightLeakIndex ?? this.lightLeakIndex,
      prismOverlay: prismOverlay ?? this.prismOverlay,
      dustOverlay: dustOverlay ?? this.dustOverlay,
    );
  }
}
