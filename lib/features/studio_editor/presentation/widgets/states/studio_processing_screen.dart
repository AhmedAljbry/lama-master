import 'package:flutter/material.dart';
import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/core/ui/AppTokens.dart';

/// Premium AI processing screen — animated step list + orb
class StudioProcessingScreen extends StatelessWidget {
  const StudioProcessingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Stack(
      children: <Widget>[
        // Radial background glow
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.9,
                colors: <Color>[
                  AppTokens.primary.withValues(alpha: 0.07),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const _AnimatedProcessingOrb(),
              const SizedBox(height: AppTokens.s28),
              Text(
                l10n.get('editor_state_processing').toUpperCase(),
                style: const TextStyle(
                  color: AppTokens.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(height: AppTokens.s8),
              Text(
                l10n.get('apply_processing_hint'),
                style: AppTokens.bodyM.copyWith(
                  color: AppTokens.text2,
                  letterSpacing: 0.3,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.s28),
              // Animated step chips
              const _ProcessingStepList(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Animated Processing Steps
// ─────────────────────────────────────────────────────────────
class _ProcessingStepList extends StatefulWidget {
  const _ProcessingStepList();

  @override
  State<_ProcessingStepList> createState() => _ProcessingStepListState();
}

class _ProcessingStepListState extends State<_ProcessingStepList>
    with SingleTickerProviderStateMixin {
  late AnimationController _stepCtrl;
  int _activeStep = 0;

  static const List<_StepData> _steps = <_StepData>[
    _StepData(icon: Icons.face_retouching_natural_rounded, label: 'Analyzing faces…'),
    _StepData(icon: Icons.auto_awesome_motion_rounded, label: 'Applying style transfer…'),
    _StepData(icon: Icons.hdr_strong_rounded, label: 'Enhancing quality…'),
  ];

  @override
  void initState() {
    super.initState();
    _stepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
            setState(() {
              _activeStep = (_activeStep + 1) % _steps.length;
            });
            _stepCtrl.forward(from: 0);
          }
        }
      });
    _stepCtrl.forward();
  }

  @override
  void dispose() {
    _stepCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s16, vertical: AppTokens.s12),
      margin: const EdgeInsets.symmetric(horizontal: AppTokens.s32),
      decoration: BoxDecoration(
        color: AppTokens.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppTokens.r20),
        border: Border.all(color: AppTokens.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_steps.length, (i) {
          final isActive = i == _activeStep;
          final isDone = i < _activeStep;
          return _ProcessingStepRow(
            step: _steps[i],
            isActive: isActive,
            isDone: isDone,
            animation: isActive ? _stepCtrl : null,
          );
        }),
      ),
    );
  }
}

class _StepData {
  final IconData icon;
  final String label;
  const _StepData({required this.icon, required this.label});
}

class _ProcessingStepRow extends StatelessWidget {
  final _StepData step;
  final bool isActive;
  final bool isDone;
  final AnimationController? animation;

  const _ProcessingStepRow({
    required this.step,
    required this.isActive,
    required this.isDone,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isDone
        ? AppTokens.success
        : (isActive ? AppTokens.primary : AppTokens.text2.withValues(alpha: 0.4));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s6),
      child: Row(
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDone
                  ? AppTokens.success.withValues(alpha: 0.15)
                  : (isActive
                      ? AppTokens.primary.withValues(alpha: 0.15)
                      : AppTokens.card2),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone
                    ? AppTokens.success.withValues(alpha: 0.4)
                    : (isActive
                        ? AppTokens.primary.withValues(alpha: 0.4)
                        : AppTokens.border.withValues(alpha: 0.3)),
              ),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: AppTokens.success)
                  : Icon(step.icon, size: 13, color: color),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              step.label,
              style: TextStyle(
                color: color,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          if (isActive && animation != null)
            AnimatedBuilder(
              animation: animation!,
              builder: (context, _) => SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  value: animation!.value,
                  strokeWidth: 1.5,
                  color: AppTokens.primary,
                  backgroundColor: AppTokens.border.withValues(alpha: 0.3),
                ),
              ),
            )
          else if (isDone)
            const Icon(Icons.check_circle_rounded,
                size: 14, color: AppTokens.success),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Animated Processing Orb with orbit dots
// ─────────────────────────────────────────────────────────────
class _AnimatedProcessingOrb extends StatefulWidget {
  const _AnimatedProcessingOrb();

  @override
  State<_AnimatedProcessingOrb> createState() => _AnimatedProcessingOrbState();
}

class _AnimatedProcessingOrbState extends State<_AnimatedProcessingOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              // Outer pulsing ring
              Opacity(
                opacity: (1 - _controller.value).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 1.0 + (_controller.value * 0.45),
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTokens.primary.withValues(alpha: 0.18),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              // Spinning arc
              SizedBox(
                width: 100,
                height: 100,
                child: RotationTransition(
                  turns: _controller,
                  child: CircularProgressIndicator(
                    value: 0.22,
                    strokeWidth: 2.5,
                    color: AppTokens.primary,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppTokens.border.withValues(alpha: 0.3),
                  ),
                ),
              ),
              // Middle static ring
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTokens.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              // Inner orb
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTokens.primaryGradient,
                  boxShadow: AppTokens.primaryGlow(0.3),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.black,
                  size: 26,
                ),
              ),
              // Orbit dot
              Transform.rotate(
                angle: _controller.value * 2 * 3.14159,
                child: Transform.translate(
                  offset: const Offset(48, 0),
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTokens.primary,
                      boxShadow: AppTokens.primaryGlow(0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
