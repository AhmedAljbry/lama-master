import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:lama/core/ui/AppL10n.dart';

import '../../../core/ui/AppTokens.dart';


class CinematicProcessingOverlay extends StatefulWidget {
  const CinematicProcessingOverlay({Key? key}) : super(key: key);

  @override
  State<CinematicProcessingOverlay> createState() => _CinematicProcessingOverlayState();
}

class _CinematicProcessingOverlayState extends State<CinematicProcessingOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _scan;
  late final AnimationController _pulse;
  late final Animation<double>   _scanAnim;
  late final Animation<double>   _pulseAnim;

  int    _phraseIdx = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scan  = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

    _scanAnim  = Tween<double>(begin: -1.0, end: 1.0).animate(CurvedAnimation(parent: _scan,  curve: Curves.easeInOut));
    _pulseAnim = Tween<double>(begin: 0.7,  end: 1.0).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

    _timer = Timer.periodic(const Duration(milliseconds: 1300), (_) {
      if (!mounted) return;
      final l10n = AppL10n.of(context);
      setState(() => _phraseIdx = (_phraseIdx + 1) % l10n.processingPhrases.length);
    });
  }

  @override
  void dispose() {
    _scan.dispose();
    _pulse.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n    = AppL10n.of(context);
    final phrases = l10n.processingPhrases;

    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Stack(
        children: [
          // Scanning line
          AnimatedBuilder(
            animation: _scanAnim,
            builder: (_, __) => Align(
              alignment: Alignment(0, _scanAnim.value),
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppTokens.primary.withOpacity(0.8),
                      AppTokens.primary,
                      AppTokens.primary.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(color: AppTokens.primary, blurRadius: 18, spreadRadius: 3),
                    BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 6),
                  ],
                ),
              ),
            ),
          ),

          // Central card
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.r24),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
                  child: Container(
                    width: 240,
                    padding: const EdgeInsets.all(AppTokens.s28),
                    decoration: BoxDecoration(
                      color: AppTokens.surface.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(AppTokens.r24),
                      border: Border.all(color: AppTokens.primary.withOpacity(0.5), width: 1.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 48, height: 48,
                          child: CircularProgressIndicator(
                            color: AppTokens.primary,
                            strokeWidth: 3,
                            backgroundColor: AppTokens.primary.withOpacity(0.15),
                          ),
                        ),
                        const SizedBox(height: AppTokens.s20),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween(begin: const Offset(0, 0.2), end: Offset.zero).animate(anim),
                              child: child,
                            ),
                          ),
                          child: Text(
                            phrases[_phraseIdx],
                            key: ValueKey(_phraseIdx),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
