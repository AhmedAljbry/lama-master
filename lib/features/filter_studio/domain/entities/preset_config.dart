import 'package:flutter/material.dart';

class PresetConfig {
  final String name;
  final IconData icon;
  final double contrast;
  final double saturation;
  final double exposure;
  final double brightness;
  final double warmth;
  final double tint;
  final double blur;
  final double glitch;
  final double grain;
  final bool ghost;
  final bool colorPop;
  final double aura;
  final Color? auraColor;
  final double scanlines;
  final Color? colorOverlay;
  final bool replaceBackground;
  final bool showDateStamp;
  final bool cinemaMode;
  final bool polaroidFrame;
  final double vignette;
  final int lightLeakIndex;
  final double prismOverlay;
  final double dustOverlay;

  const PresetConfig({
    required this.name,
    required this.icon,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.exposure = 0.0,
    this.brightness = 0.0,
    this.warmth = 0.0,
    this.tint = 0.0,
    this.blur = 0.0,
    this.glitch = 0.0,
    this.grain = 0.0,
    this.ghost = false,
    this.colorPop = false,
    this.aura = 0.0,
    this.auraColor,
    this.scanlines = 0.0,
    this.colorOverlay,
    this.replaceBackground = false,
    this.showDateStamp = false,
    this.cinemaMode = false,
    this.polaroidFrame = false,
    this.vignette = 0.0,
    this.lightLeakIndex = 0,
    this.prismOverlay = 0.0,
    this.dustOverlay = 0.0,
  });
}
