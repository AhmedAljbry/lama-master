// processing_overlay.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lama/core/ui/AppTokens.dart';
import 'package:lama/core/ui/app_theme.dart';



// ─── Model ────────────────────────────────────────────────────────
class ProcessingStep {
  final String label;
  final double progress; // 0.0 – 1.0
  const ProcessingStep({required this.label, required this.progress});
}

// ─── Overlay ──────────────────────────────────────────────────────
class ProcessingOverlay extends StatefulWidget {
  final String title;
  final String? subtitle;
  final double? progress;            // null = indeterminate
  final List<ProcessingStep> steps;
  final VoidCallback? onCancel;
  final bool visible;

  const ProcessingOverlay({
    super.key,
    required this.title,
    this.subtitle,
    this.progress,
    this.steps = const [],
    this.onCancel,
    this.visible = true,
  });

  @override
  State<ProcessingOverlay> createState() => _ProcessingOverlayState();
}

class _ProcessingOverlayState extends State<ProcessingOverlay>
    with TickerProviderStateMixin {

  late final AnimationController _spinCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _enterCtrl;
  late final Animation<double> _enterOpacity;
  late final Animation<double> _enterScale;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _enterOpacity = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _enterScale = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutBack)
        .drive(Tween(begin: 0.88, end: 1.0));
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut)
        .drive(Tween(begin: 0.7, end: 1.0));
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _pulseCtrl.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return SizedBox.shrink();

    return AnimatedBuilder(
      animation: _enterCtrl,
      builder: (_, child) =>
          Opacity(opacity: _enterOpacity.value, child: child),
      child: Stack(
        children: [
          // Blur background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(color: AppTokens.bg.withOpacity(0.75)),
            ),
          ),

          // Glow orbs
          Positioned.fill(child: _GlowOrbs(anim: _pulseCtrl)),

          // Card
          Center(
            child: AnimatedBuilder(
              animation: _enterCtrl,
              builder: (_, child) =>
                  Transform.scale(scale: _enterScale.value, child: child),
              child: Container(
                width: math.min(
                    MediaQuery.sizeOf(context).width - 48, 340),
                padding: EdgeInsets.all(AppTokens.s32),
                decoration: BoxDecoration(
                  color: AppTokens.surface,
                  borderRadius: BorderRadius.circular(AppTokens.r24),
                  border: Border.all(
                      color: AppTokens.border.withOpacity(0.3)),
                  boxShadow: AppTokens.cardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RingSpinner(ctrl: _spinCtrl, pulse: _pulse),
                    SizedBox(height: AppTokens.s24),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTokens.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      SizedBox(height: AppTokens.s8),
                      Text(
                        widget.subtitle!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTokens.text2,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                    SizedBox(height: AppTokens.s24),
                    _ProgressBar(progress: widget.progress),
                    if (widget.steps.isNotEmpty) ...[
                      SizedBox(height: AppTokens.s20),
                      ...widget.steps.map((s) => _StepRow(step: s)),
                    ],
                    if (widget.onCancel != null) ...[
                      SizedBox(height: AppTokens.s20),
                      GestureDetector(
                        onTap: widget.onCancel,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppTokens.s24, vertical: AppTokens.s12),
                          decoration: BoxDecoration(
                            border: Border.all(color: (AppTokens.text2.withOpacity(0.7))),
                            borderRadius:
                            BorderRadius.circular(AppTokens.rFull),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                                color: AppTokens.text2,
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ring Spinner ─────────────────────────────────────────────────
class _RingSpinner extends StatelessWidget {
  final AnimationController ctrl;
  final Animation<double> pulse;
  const _RingSpinner({required this.ctrl, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ctrl, pulse]),
      builder: (_, __) => SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 70 * pulse.value,
              height: 70 * pulse.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTokens.primary.withOpacity(0.07 * pulse.value),
              ),
            ),
            Transform.rotate(
              angle: ctrl.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size(70, 70),
                painter: _ArcPainter(),
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTokens.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppTokens.primary.withOpacity(0.2)),
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  color: AppTokens.primary, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppTokens.primary.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 1.5,
      false,
      Paint()
        ..shader = LinearGradient(colors: [
          AppTokens.primary,
          AppTokens.info,
          AppTokens.primary.withOpacity(0),
        ]).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Progress Bar ─────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final double? progress;
  const _ProgressBar({this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.rFull),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            backgroundColor: (AppTokens.text2.withOpacity(0.7)).withOpacity(0.2),
            valueColor:
            const AlwaysStoppedAnimation<Color>(AppTokens.primary),
          ),
        ),
        if (progress != null) ...[
          SizedBox(height: AppTokens.s8),
          Text(
            '${(progress! * 100).toInt()}%',
            style: TextStyle(
                color: (AppTokens.text2.withOpacity(0.7)),
                fontSize: 11,
                fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }
}

// ─── Step Row ─────────────────────────────────────────────────────
class _StepRow extends StatelessWidget {
  final ProcessingStep step;
  const _StepRow({required this.step});

  @override
  Widget build(BuildContext context) {
    final done   = step.progress >= 1.0;
    final active = step.progress > 0 && step.progress < 1.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTokens.s4),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: done
                  ? AppTokens.primary.withOpacity(0.2)
                  : active
                  ? AppTokens.primary.withOpacity(0.08)
                  : (AppTokens.text2.withOpacity(0.7)).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: done
                    ? AppTokens.primary
                    : active
                    ? AppTokens.primary.withOpacity(0.5)
                    : (AppTokens.text2.withOpacity(0.7)).withOpacity(0.3),
              ),
            ),
            child: done
                ? Icon(Icons.check_rounded,
                color: AppTokens.primary, size: 11)
                : active
                ? Padding(
              padding: EdgeInsets.all(3),
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: AppTokens.primary),
            )
                : null,
          ),
          SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              step.label,
              style: TextStyle(
                color: done ? AppTokens.text2 : active ? AppTokens.text : (AppTokens.text2.withOpacity(0.7)),
                fontSize: 12,
                fontWeight:
                active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (active)
            Text(
              '${(step.progress * 100).toInt()}%',
              style: TextStyle(
                  color: AppTokens.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800),
            ),
        ],
      ),
    );
  }
}

// ─── Glow Orbs ────────────────────────────────────────────────────
class _GlowOrbs extends StatelessWidget {
  final AnimationController anim;
  const _GlowOrbs({required this.anim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final v = anim.value;
        return Stack(
          children: [
            Positioned(
              top: -50 + 30 * v,
              left: -60 + 20 * v,
              child: _orb(AppTokens.primary.withOpacity(0.04), 250),
            ),
            Positioned(
              bottom: -40 + 20 * v,
              right: -50 + 25 * v,
              child: _orb(AppTokens.accent.withOpacity(0.04), 200),
            ),
          ],
        );
      },
    );
  }

  Widget _orb(Color c, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: c),
  );
}
