import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lama/core/ui/AppTokens.dart';

// ─────────────────────────────────────────────────────────────
// Workflow Progress Strip — top of tool panel
// ─────────────────────────────────────────────────────────────
class WorkflowProgressStrip extends StatelessWidget {
  final bool sourceReady;
  final bool styleSelected;
  final bool refineActive;

  const WorkflowProgressStrip({
    super.key,
    required this.sourceReady,
    required this.styleSelected,
    required this.refineActive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _StripStep(label: 'Photos', icon: Icons.photo_library_rounded,
            isDone: sourceReady, number: '①'),
        _StripConnector(filled: sourceReady),
        _StripStep(label: 'Style', icon: Icons.auto_awesome_motion_rounded,
            isDone: styleSelected, number: '②'),
        _StripConnector(filled: styleSelected),
        _StripStep(label: 'Apply', icon: Icons.auto_awesome_rounded,
            isDone: refineActive, number: '③'),
      ],
    );
  }
}

class _StripStep extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDone;
  final String number;
  const _StripStep({
    required this.label,
    required this.icon,
    required this.isDone,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone ? AppTokens.success : AppTokens.text2;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isDone
                ? AppTokens.success.withValues(alpha: 0.16)
                : AppTokens.card2,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone
                  ? AppTokens.success.withValues(alpha: 0.5)
                  : AppTokens.border.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Center(
            child: isDone
                ? Icon(Icons.check_rounded, size: 15, color: AppTokens.success)
                : Text(
                    number,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isDone ? AppTokens.success : AppTokens.text2,
            fontWeight: isDone ? FontWeight.w800 : FontWeight.w500,
            fontSize: 9,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _StripConnector extends StatelessWidget {
  final bool filled;
  const _StripConnector({required this.filled});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          height: 2,
          decoration: BoxDecoration(
            color: filled
                ? AppTokens.success.withValues(alpha: 0.5)
                : AppTokens.border.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppTokens.rFull),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTokens.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
              child: Icon(icon, size: 14, color: AppTokens.primary),
            ),
            const SizedBox(width: AppTokens.s10),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: AppTokens.caption.copyWith(
                  color: AppTokens.text,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: AppTokens.s6),
          Text(
            subtitle!,
            style: AppTokens.caption.copyWith(
              color: AppTokens.text2.withValues(alpha: 0.85),
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Source Picker Card — horizontal row layout
// ─────────────────────────────────────────────────────────────
class SourcePickerCard extends StatelessWidget {
  final String label;
  final String? statusLabel;
  final bool isReady;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const SourcePickerCard({
    super.key,
    required this.label,
    required this.isReady,
    required this.icon,
    required this.color,
    required this.onTap,
    this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppTokens.r16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(
          vertical: AppTokens.s14,
          horizontal: AppTokens.s16,
        ),
        decoration: BoxDecoration(
          color: isReady ? color.withValues(alpha: 0.1) : AppTokens.card,
          borderRadius: BorderRadius.circular(AppTokens.r16),
          border: Border.all(
            color: isReady ? color.withValues(alpha: 0.48) : AppTokens.border,
            width: isReady ? 1.5 : 1.0,
          ),
          boxShadow: isReady
              ? <BoxShadow>[
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isReady ? color.withValues(alpha: 0.18) : AppTokens.card2,
              ),
              child: Icon(
                icon,
                color: isReady ? color : AppTokens.text2,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label,
                    style: AppTokens.labelBold.copyWith(
                      color: isReady ? color : AppTokens.text,
                      fontSize: 13,
                    ),
                  ),
                  if (statusLabel != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      statusLabel!,
                      style: AppTokens.caption.copyWith(
                        color: isReady
                            ? color.withValues(alpha: 0.85)
                            : AppTokens.text2,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isReady
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              color: isReady ? color : AppTokens.text2.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AI Mode Toggle Card
// ─────────────────────────────────────────────────────────────
class AiModeToggleCard extends StatelessWidget {
  final bool useAI;
  final ValueChanged<bool>? onToggle;
  final String label;
  final String subLabel;

  const AiModeToggleCard({
    super.key,
    required this.useAI,
    required this.onToggle,
    required this.label,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s14,
        vertical: AppTokens.s12,
      ),
      decoration: BoxDecoration(
        color: useAI
            ? AppTokens.primary.withValues(alpha: 0.09)
            : AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(
          color: useAI
              ? AppTokens.primary.withValues(alpha: 0.4)
              : AppTokens.border,
          width: useAI ? 1.5 : 1.0,
        ),
        boxShadow: useAI
            ? <BoxShadow>[
                BoxShadow(
                  color: AppTokens.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: useAI
                  ? AppTokens.primary.withValues(alpha: 0.18)
                  : AppTokens.card2,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology_alt_rounded,
              color: useAI ? AppTokens.primary : AppTokens.text2,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: AppTokens.labelBold.copyWith(
                    color: useAI ? AppTokens.primary : AppTokens.text,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subLabel,
                  style: AppTokens.caption.copyWith(
                    color: AppTokens.text2,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Switch(
            value: useAI,
            activeColor: AppTokens.primary,
            onChanged: onToggle,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Manual Mask Card
// ─────────────────────────────────────────────────────────────
class ManualMaskCard extends StatelessWidget {
  final bool isReady;
  final bool isLocked;
  final VoidCallback onTap;
  final String title;
  final String lockedLabel;
  final String readyLabel;
  final String idleLabel;

  const ManualMaskCard({
    super.key,
    required this.isReady,
    required this.isLocked,
    required this.onTap,
    required this.title,
    required this.lockedLabel,
    required this.readyLabel,
    required this.idleLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isReady ? AppTokens.warning : AppTokens.text2;
    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(AppTokens.r16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(AppTokens.s14),
        decoration: BoxDecoration(
          color: isLocked
              ? AppTokens.card.withValues(alpha: 0.5)
              : AppTokens.card,
          borderRadius: BorderRadius.circular(AppTokens.r16),
          border: Border.all(
            color: isReady
                ? AppTokens.warning.withValues(alpha: 0.4)
                : AppTokens.border.withValues(alpha: isLocked ? 0.4 : 1.0),
          ),
        ),
        child: Row(
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isLocked
                    ? AppTokens.card2.withValues(alpha: 0.5)
                    : color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLocked ? Icons.lock_rounded : Icons.brush_rounded,
                color:
                    isLocked ? AppTokens.text2.withValues(alpha: 0.5) : color,
                size: 18,
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTokens.labelBold.copyWith(
                      color: isLocked
                          ? AppTokens.text2.withValues(alpha: 0.60)
                          : AppTokens.text,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLocked
                        ? lockedLabel
                        : (isReady ? readyLabel : idleLabel),
                    style: AppTokens.caption.copyWith(
                      color: isLocked
                          ? AppTokens.text2.withValues(alpha: 0.50)
                          : AppTokens.text2,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (!isLocked && !isReady)
              Icon(Icons.chevron_right_rounded,
                  color: AppTokens.text2, size: 20),
            if (isReady)
              Icon(Icons.check_circle_rounded,
                  color: AppTokens.warning, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Enterprise Apply Button — premium gradient CTA with pulse shimmer
// ─────────────────────────────────────────────────────────────
class EnterpriseApplyBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isReady;
  final bool isBusy;
  final VoidCallback onTap;

  const EnterpriseApplyBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.isReady,
    required this.onTap,
    this.isBusy = false,
  });

  @override
  State<EnterpriseApplyBtn> createState() => _EnterpriseApplyBtnState();
}

class _EnterpriseApplyBtnState extends State<EnterpriseApplyBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _glowAnim = Tween<double>(begin: 0.18, end: 0.38).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(covariant EnterpriseApplyBtn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isReady != widget.isReady ||
        oldWidget.isBusy != widget.isBusy) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.isReady && !widget.isBusy) {
      _glowCtrl.repeat(reverse: true);
    } else {
      _glowCtrl.stop();
      _glowCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.isReady && !widget.isBusy;

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return GestureDetector(
          onTap: enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            height: 56,
            decoration: BoxDecoration(
              gradient: enabled ? AppTokens.primaryGradient : null,
              color: enabled ? null : AppTokens.card2,
              borderRadius: BorderRadius.circular(AppTokens.r16),
              boxShadow: enabled
                  ? <BoxShadow>[
                      BoxShadow(
                        color: AppTokens.primary
                            .withValues(alpha: _glowAnim.value),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
              border: enabled
                  ? null
                  : Border.all(
                      color: AppTokens.border.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: widget.isBusy
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: AppTokens.text,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          widget.icon,
                          color: enabled ? Colors.black : AppTokens.text2,
                          size: 20,
                        ),
                        const SizedBox(width: AppTokens.s8),
                        Text(
                          widget.label.toUpperCase(),
                          style: TextStyle(
                            color:
                                enabled ? Colors.black : AppTokens.text2,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Ergonomic Inline Slider (used in refine scrollable list)
// ─────────────────────────────────────────────────────────────
class ErgonomicSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final IconData icon;

  const ErgonomicSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ((value - min) / (max - min) * 100).clamp(0, 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.s10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 15, color: AppTokens.text2),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  label,
                  style: AppTokens.labelBold.copyWith(
                    color: AppTokens.text,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                ),
                child: Text(
                  '$progress%',
                  style: AppTokens.caption.copyWith(
                    color: AppTokens.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3.5,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppTokens.primary,
              inactiveTrackColor: AppTokens.border,
              thumbColor: AppTokens.primary,
              overlayColor: AppTokens.primary.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
              onChangeEnd: (_) => HapticFeedback.selectionClick(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Inspector Hero Card
// ─────────────────────────────────────────────────────────────
class InspectorHeroCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget? trailing;

  const InspectorHeroCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            accent.withValues(alpha: 0.16),
            AppTokens.card2.withValues(alpha: 0.96),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTokens.r20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppTokens.r14),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      eyebrow.toUpperCase(),
                      style: AppTokens.caption.copyWith(
                        color: accent,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: AppTokens.headingM.copyWith(
                        color: AppTokens.text,
                        height: 1.2,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: AppTokens.s12),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Text(
            subtitle,
            style: AppTokens.bodyM.copyWith(
              color: AppTokens.text2,
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Workflow Status Card
// ─────────────────────────────────────────────────────────────
class WorkflowStatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<WorkflowStatusItem> steps;

  const WorkflowStatusCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s14),
      decoration: BoxDecoration(
        color: AppTokens.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppTokens.r18),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title,
              style: AppTokens.labelBold.copyWith(color: AppTokens.text)),
          const SizedBox(height: AppTokens.s4),
          Text(
            subtitle,
            style:
                AppTokens.caption.copyWith(color: AppTokens.text2, height: 1.4),
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: steps
                .map((s) => _WorkflowStepChip(item: s))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class WorkflowStatusItem {
  final String label;
  final IconData icon;
  final bool ready;

  const WorkflowStatusItem({
    required this.label,
    required this.icon,
    required this.ready,
  });
}

class _WorkflowStepChip extends StatelessWidget {
  final WorkflowStatusItem item;
  const _WorkflowStepChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final Color color = item.ready ? AppTokens.success : AppTokens.text2;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s10, vertical: AppTokens.s8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: item.ready ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppTokens.rFull),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(item.icon, size: 11, color: color),
          const SizedBox(width: AppTokens.s6),
          Text(
            item.label,
            style: AppTokens.caption
                .copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Status Info Pill
// ─────────────────────────────────────────────────────────────
class StatusInfoPill extends StatelessWidget {
  final String label;
  final Color color;

  const StatusInfoPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s10, vertical: AppTokens.s7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTokens.rFull),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: AppTokens.caption
            .copyWith(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Inspector Hint Card
// ─────────────────────────────────────────────────────────────
class InspectorHintCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String description;

  const InspectorHintCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s14),
      decoration: BoxDecoration(
        color: AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTokens.r10),
            ),
            child: Icon(icon, color: accent, size: 17),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: AppTokens.labelBold
                        .copyWith(color: AppTokens.text, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTokens.caption
                      .copyWith(color: AppTokens.text2, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Style Spotlight Card
// ─────────────────────────────────────────────────────────────
class StyleSpotlightCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const StyleSpotlightCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[accent.withValues(alpha: 0.14), AppTokens.card2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTokens.r20),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTokens.r14),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTokens.labelBold
                      .copyWith(color: AppTokens.text, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTokens.caption
                      .copyWith(color: AppTokens.text2, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Style Option Card — filmstrip / grid variant
// ─────────────────────────────────────────────────────────────
class StyleOptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const StyleOptionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = AppTokens.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: <Color>[
                    accent.withValues(alpha: 0.2),
                    accent.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppTokens.card,
          borderRadius: BorderRadius.circular(AppTokens.r16),
          border: Border.all(
            color:
                isSelected ? accent.withValues(alpha: 0.55) : AppTokens.border,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 14,
                    spreadRadius: 0,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha: 0.2)
                    : AppTokens.card2,
                borderRadius: BorderRadius.circular(AppTokens.r14),
              ),
              child: Icon(
                icon,
                color: isSelected ? accent : AppTokens.text2,
                size: 22,
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? accent : AppTokens.text,
                  fontWeight:
                      isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ),
            if (isSelected) ...<Widget>[
              const SizedBox(height: 5),
              Container(
                width: 22,
                height: 3,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(AppTokens.rFull),
                ),
              ),
              const SizedBox(height: 2),
            ],
          ],
        ),
      ),
    );
  }
}
