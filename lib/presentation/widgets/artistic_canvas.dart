import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lama/features/filter_studio/presentation/services/filter_studio_mask_policy.dart';

import '../../domain/filter_params.dart';
import 'package:lama/ProFilterStudio1.dart'; // فقط لأن عندك painters هنا (ScanlinePainter/AdvancedGrainPainter)

class ArtisticCanvas extends StatelessWidget {
  final File imageFile;
  final ui.Image? personMask;
  final FilterParams params;
  final bool showOriginal;

  const ArtisticCanvas({
    super.key,
    required this.imageFile,
    required this.personMask,
    required this.params,
    this.showOriginal = false,
  });

  // ==========================================================
  // Tone + Color: contrast/saturation + exposure/brightness + warmth/tint
  // ==========================================================
  List<double> _composeMatrix(FilterParams p) {
    // exposure -1..1 => translate ~ 255*0.35
    final exp = (p.exposure.clamp(-1.0, 1.0)) * 255.0 * 0.35;
    // brightness -0.5..0.5 => translate ~ 255
    final bri = (p.brightness.clamp(-0.5, 0.5)) * 255.0;

    // contrast 0.5..1.5
    final c = p.contrast.clamp(0.5, 1.5);
    final t = (1.0 - c) * 128.0;

    // warmth/tint
    final w = p.warmth.clamp(-1.0, 1.0) * 18.0; // red/blue bias
    final ti = p.tint.clamp(-1.0, 1.0) * 18.0; // green bias

    // saturation 0..2
    final s = p.saturation.clamp(0.0, 2.0);
    const lumR = 0.2126, lumG = 0.7152, lumB = 0.0722;
    final sr = (1 - s) * lumR;
    final sg = (1 - s) * lumG;
    final sb = (1 - s) * lumB;

    final sat = <double>[
      sr + s,
      sg,
      sb,
      0,
      0,
      sr,
      sg + s,
      sb,
      0,
      0,
      sr,
      sg,
      sb + s,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];

    // base: contrast + translate
    final base = <double>[
      c,
      0,
      0,
      0,
      t + exp + bri + w,
      0,
      c,
      0,
      0,
      t + exp + bri + ti,
      0,
      0,
      c,
      0,
      t + exp + bri - w,
      0,
      0,
      0,
      1,
      0,
    ];

    return _mulColorMatrix(sat, base);
  }

  // Multiply 4x5 matrices
  List<double> _mulColorMatrix(List<double> a, List<double> b) {
    final out = List<double>.filled(20, 0);
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 5; c++) {
        out[r * 5 + c] = a[r * 5 + 0] * b[0 * 5 + c] +
            a[r * 5 + 1] * b[1 * 5 + c] +
            a[r * 5 + 2] * b[2 * 5 + c] +
            a[r * 5 + 3] * b[3 * 5 + c] +
            (c == 4 ? a[r * 5 + 4] : 0);
      }
    }
    return out;
  }

  // ==========================================================
  // Glitch stack (same behavior)
  // ==========================================================
  Widget _buildGlitchStack() {
    final offset = params.glitch * 5.0;
    return Stack(
      children: [
        Transform.translate(
          offset: Offset(-offset, 0),
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.red, BlendMode.modulate),
            child: Image.file(imageFile, fit: BoxFit.contain),
          ),
        ),
        Transform.translate(
          offset: Offset(offset, 0),
          child: ColorFiltered(
            colorFilter:
                const ColorFilter.mode(Colors.blue, BlendMode.modulate),
            child: Image.file(imageFile, fit: BoxFit.contain),
          ),
        ),
        Image.file(imageFile, fit: BoxFit.contain),
      ],
    );
  }

  // ==========================================================
  // Mask shader helper
  // ==========================================================
  Shader _maskShader(ui.Image mask, Rect rect) {
    return ImageShader(
      mask,
      TileMode.clamp,
      TileMode.clamp,
      Matrix4.identity()
          .scaled(rect.width / mask.width, rect.height / mask.height)
          .storage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveParams = showOriginal ? const FilterParams() : params;
    final hasPersonMask = personMask != null;
    final usesSubjectMask = shouldUseSubjectMask(
      effectiveParams,
      hasPersonMask: hasPersonMask,
    );
    final replacesBackground = shouldReplaceBackground(
      effectiveParams,
      hasPersonMask: hasPersonMask,
    );
    return Container(
      padding: effectiveParams.polaroidFrame
          ? const EdgeInsets.fromLTRB(20, 20, 20, 80)
          : EdgeInsets.zero,
      color: effectiveParams.polaroidFrame
          ? const Color(0xFFF0F0F0)
          : Colors.transparent,
      child: ClipRect(
        // ✅ هنا Tone الحقيقي (بدل _calculateColorMatrix القديمة)
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix(_composeMatrix(effectiveParams)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // =============================
              // Background
              // =============================
              if (replacesBackground)
                Positioned.fill(child: Container(color: Colors.black))
              else
                ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: effectiveParams.blur,
                    sigmaY: effectiveParams.blur,
                  ),
                  child: ColorFiltered(
                    colorFilter: effectiveParams.colorPop
                        ? const ColorFilter.mode(
                            Colors.grey, BlendMode.saturation)
                        : ColorFilter.mode(
                            effectiveParams.overlayColor ?? Colors.transparent,
                            BlendMode.srcOver,
                          ),
                    child: effectiveParams.glitch > 0
                        ? _buildGlitchStack()
                        : Image.file(imageFile, fit: BoxFit.contain),
                  ),
                ),

              // =============================
              // Aura
              // =============================
              if (effectiveParams.aura > 0)
                Positioned.fill(
                  child: usesSubjectMask && personMask != null
                      ? ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                            sigmaX: 20 * effectiveParams.aura,
                            sigmaY: 20 * effectiveParams.aura,
                          ),
                          child: ShaderMask(
                            shaderCallback: (rect) =>
                                _maskShader(personMask!, rect),
                            blendMode: BlendMode.src,
                            child: Container(
                              color: effectiveParams.auraColor
                                  .withValues(alpha: effectiveParams.aura),
                            ),
                          ),
                        )
                      : IgnorePointer(
                          child: Opacity(
                            opacity:
                                (0.12 + (effectiveParams.aura * 0.32)).clamp(
                              0.0,
                              0.42,
                            ),
                            child: ImageFiltered(
                              imageFilter: ui.ImageFilter.blur(
                                sigmaX: 10 + (18 * effectiveParams.aura),
                                sigmaY: 10 + (18 * effectiveParams.aura),
                              ),
                              child: ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  effectiveParams.auraColor.withValues(
                                    alpha: 0.18 + (effectiveParams.aura * 0.14),
                                  ),
                                  BlendMode.screen,
                                ),
                                child: Image.file(
                                  imageFile,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),

              // =============================
              // Ghost
              // =============================
              if (effectiveParams.ghost &&
                  usesSubjectMask &&
                  personMask != null)
                Positioned.fill(
                  child: Transform.translate(
                    offset: const Offset(30, 0),
                    child: Transform.scale(
                      scale: 1.1,
                      child: Opacity(
                        opacity: 0.5,
                        child: ShaderMask(
                          shaderCallback: (rect) =>
                              _maskShader(personMask!, rect),
                          blendMode: BlendMode.dstIn,
                          child: Image.file(imageFile, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                ),

              // =============================
              // Foreground (person only)
              // =============================
              if (usesSubjectMask && personMask != null)
                ShaderMask(
                  shaderCallback: (rect) => _maskShader(personMask!, rect),
                  blendMode: BlendMode.dstIn,
                  child: effectiveParams.glitch > 0
                      ? _buildGlitchStack()
                      : Image.file(imageFile, fit: BoxFit.contain),
                ),

              // =============================
              // Scanlines
              // =============================
              if (effectiveParams.scanlines > 0)
                Positioned.fill(
                  child: CustomPaint(
                    painter: ScanlinePainter(
                      intensity: effectiveParams.scanlines,
                    ),
                  ),
                ),

              // =============================
              // Light leaks
              // =============================
              if (effectiveParams.lightLeakIndex != 0)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: effectiveParams.lightLeakIndex == 1
                            ? [
                                Colors.orange.withOpacity(0.4),
                                Colors.transparent
                              ]
                            : [
                                Colors.blue.withOpacity(0.4),
                                Colors.transparent
                              ],
                        begin: effectiveParams.lightLeakIndex == 1
                            ? Alignment.centerLeft
                            : Alignment.topCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                ),

              // =============================
              // Prism overlay
              // =============================
              if (effectiveParams.prismOverlay > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: (0.18 + (effectiveParams.prismOverlay * 0.42))
                          .clamp(0.0, 0.58),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0x66FF8AE2),
                              const Color(0x4427E4FF),
                              const Color(0x33FFF3B0),
                              Colors.transparent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: const [0.0, 0.38, 0.72, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // =============================
              // Vignette (strength)
              // =============================
              if (effectiveParams.vignette > 0)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(effectiveParams.vignette),
                        ],
                        stops: [
                          (0.28 + (effectiveParams.vignetteSize * 0.55))
                              .clamp(0.2, 0.88),
                          1.0,
                        ],
                      ),
                    ),
                  ),
                ),

              // =============================
              // Grain
              // =============================
              if (effectiveParams.grain > 0)
                Positioned.fill(
                  child: CustomPaint(
                    painter: AdvancedGrainPainter(
                      intensity: effectiveParams.grain,
                    ),
                  ),
                ),

              // =============================
              // Dust overlay
              // =============================
              if (effectiveParams.dustOverlay > 0)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DustOverlayPainter(
                      intensity: effectiveParams.dustOverlay,
                    ),
                  ),
                ),

              // =============================
              // Cinema bars
              // =============================
              if (effectiveParams.cinemaMode) ...[
                const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: ColoredBox(color: Colors.black)),
                const Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: ColoredBox(color: Colors.black)),
              ],

              // =============================
              // Date stamp
              // =============================
              if (effectiveParams.showDateStamp)
                Positioned(
                  bottom: effectiveParams.cinemaMode ? 50 : 20,
                  right: 20,
                  child: Text(
                    "'98  1  24",
                    style: TextStyle(
                      color: const Color(0xFFFF8C00),
                      fontFamily: Platform.isIOS ? "Courier" : "Monospace",
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: const [
                        Shadow(
                            color: Colors.black,
                            blurRadius: 2,
                            offset: Offset(1, 1)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DustOverlayPainter extends CustomPainter {
  final double intensity;

  const _DustOverlayPainter({
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dustCount = (30 + (intensity * 160)).round().clamp(24, 220);
    final random = math.Random(42);
    final speckPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);

    for (var i = 0; i < dustCount; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = 0.4 + (random.nextDouble() * (1.2 + (intensity * 2.8)));
      final alpha = 0.05 + (random.nextDouble() * intensity * 0.36);
      speckPaint.color = Colors.white.withOpacity(alpha.clamp(0.02, 0.28));
      canvas.drawCircle(Offset(dx, dy), radius, speckPaint);
    }

    final streakPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

    final streakCount = (2 + (intensity * 18)).round();
    for (var i = 0; i < streakCount; i++) {
      final start = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final end = Offset(
        (start.dx + (random.nextDouble() * 42) - 21).clamp(0.0, size.width),
        (start.dy + (random.nextDouble() * 42) - 21).clamp(0.0, size.height),
      );
      streakPaint
        ..strokeWidth = 0.6 + (random.nextDouble() * 1.6)
        ..color = Colors.white.withOpacity(
          (0.02 + (random.nextDouble() * intensity * 0.16)).clamp(0.01, 0.14),
        );
      canvas.drawLine(start, end, streakPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DustOverlayPainter oldDelegate) {
    return oldDelegate.intensity != intensity;
  }
}
