import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lama/core/ui/AppTokens.dart';

class CustomTabBar extends StatelessWidget {
  final TabController controller;

  const CustomTabBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      indicatorColor: AppTokens.primary,
      indicatorWeight: 3,
      labelColor: AppTokens.primary,
      unselectedLabelColor: AppTokens.text2,
      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      tabs: const <Tab>[
        Tab(
          text: 'Setup',
          iconMargin: EdgeInsets.only(bottom: 4),
          icon: Icon(Icons.settings_suggest_rounded, size: 20),
        ),
        Tab(
          text: 'Theme',
          iconMargin: EdgeInsets.only(bottom: 4),
          icon: Icon(Icons.style_rounded, size: 20),
        ),
        Tab(
          text: 'Adjust',
          iconMargin: EdgeInsets.only(bottom: 4),
          icon: Icon(Icons.tune_rounded, size: 20),
        ),
      ],
    );
  }
}

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
            Icon(icon, size: 16, color: AppTokens.text2),
            const SizedBox(width: AppTokens.s8),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: AppTokens.caption.copyWith(
                  color: AppTokens.text2,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w900,
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
              color: AppTokens.text2.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

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
          vertical: AppTokens.s18,
          horizontal: AppTokens.s12,
        ),
        decoration: BoxDecoration(
          color: isReady ? color.withValues(alpha: 0.12) : AppTokens.card,
          borderRadius: BorderRadius.circular(AppTokens.r16),
          border: Border.all(
            color: isReady ? color.withValues(alpha: 0.5) : AppTokens.border,
            width: isReady ? 1.5 : 1.0,
          ),
          boxShadow: isReady
              ? <BoxShadow>[
                  BoxShadow(
                    color: color.withValues(alpha: 0.12),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(AppTokens.s10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isReady ? color.withValues(alpha: 0.2) : AppTokens.card2,
              ),
              child: Icon(
                icon,
                color: isReady ? color : AppTokens.text2,
                size: 24,
              ),
            ),
            const SizedBox(height: AppTokens.s12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTokens.labelBold.copyWith(
                color: isReady ? color : AppTokens.text,
              ),
            ),
            if (statusLabel != null) ...<Widget>[
              const SizedBox(height: AppTokens.s6),
              Text(
                statusLabel!,
                textAlign: TextAlign.center,
                style: AppTokens.caption.copyWith(
                  color: isReady ? color : AppTokens.text2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s14,
        vertical: AppTokens.s12,
      ),
      decoration: BoxDecoration(
        color:
            useAI ? AppTokens.primary.withValues(alpha: 0.1) : AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(
          color: useAI
              ? AppTokens.primary.withValues(alpha: 0.4)
              : AppTokens.border,
        ),
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
          Switch(
            value: useAI,
            activeColor: AppTokens.primary,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}

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
    final color = isReady ? AppTokens.warning : AppTokens.text2;
    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(AppTokens.r16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(AppTokens.s14),
        decoration: BoxDecoration(
          color: isLocked
              ? AppTokens.card.withValues(alpha: 0.55)
              : AppTokens.card,
          borderRadius: BorderRadius.circular(AppTokens.r16),
          border: Border.all(
            color: isReady
                ? AppTokens.warning.withValues(alpha: 0.45)
                : AppTokens.border,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isLocked
                    ? AppTokens.card2.withValues(alpha: 0.6)
                    : color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLocked ? Icons.lock_rounded : Icons.brush_rounded,
                color:
                    isLocked ? AppTokens.text2.withValues(alpha: 0.6) : color,
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
                          ? AppTokens.text2.withValues(alpha: 0.65)
                          : AppTokens.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLocked ? lockedLabel : (isReady ? readyLabel : idleLabel),
                    style: AppTokens.caption.copyWith(
                      color: isLocked
                          ? AppTokens.text2.withValues(alpha: 0.55)
                          : AppTokens.text2,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (!isLocked && !isReady)
              Icon(Icons.chevron_right_rounded, color: AppTokens.text2),
            if (isReady)
              Icon(Icons.check_circle_rounded, color: AppTokens.warning),
          ],
        ),
      ),
    );
  }
}

class EnterpriseApplyBtn extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final enabled = isReady && !isBusy;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: enabled ? AppTokens.primaryGradient : null,
          color: enabled ? null : AppTokens.card2,
          borderRadius: BorderRadius.circular(AppTokens.r16),
          boxShadow: enabled ? AppTokens.primaryGlow(0.26) : null,
          border: enabled ? null : Border.all(color: AppTokens.border),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s16,
          vertical: AppTokens.s14,
        ),
        child: Center(
          child: isBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppTokens.text,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      icon,
                      color: enabled ? Colors.black : AppTokens.text2,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        color: enabled ? Colors.black : AppTokens.text2,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

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
      margin: const EdgeInsets.only(bottom: AppTokens.s12),
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s12,
        AppTokens.s12,
        AppTokens.s12,
        AppTokens.s4,
      ),
      decoration: BoxDecoration(
        color: AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: AppTokens.text2),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  label,
                  style: AppTokens.labelBold.copyWith(
                    color: AppTokens.text,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                ),
                child: Text(
                  '$progress%',
                  style: AppTokens.caption.copyWith(
                    color: AppTokens.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: AppTokens.primary,
              inactiveTrackColor: AppTokens.border,
              thumbColor: AppTokens.primary,
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
            accent.withValues(alpha: 0.18),
            AppTokens.card2.withValues(alpha: 0.96),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTokens.r20),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppTokens.r14),
                ),
                child: Icon(icon, color: accent),
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
          Text(
            title,
            style: AppTokens.labelBold.copyWith(color: AppTokens.text),
          ),
          const SizedBox(height: AppTokens.s4),
          Text(
            subtitle,
            style: AppTokens.caption.copyWith(
              color: AppTokens.text2,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children:
                steps.map((step) => _WorkflowStepChip(item: step)).toList(),
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
    final color = item.ready ? AppTokens.success : AppTokens.text2;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s10,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: item.ready ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppTokens.rFull),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(item.icon, size: 12, color: color),
          const SizedBox(width: AppTokens.s6),
          Text(
            item.label,
            style: AppTokens.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusInfoPill extends StatelessWidget {
  final String label;
  final Color color;

  const StatusInfoPill({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s10,
        vertical: AppTokens.s7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTokens.rFull),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: AppTokens.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

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
        borderRadius: BorderRadius.circular(AppTokens.r18),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTokens.r12),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTokens.labelBold.copyWith(color: AppTokens.text),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTokens.caption.copyWith(
                    color: AppTokens.text2,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
          colors: <Color>[
            accent.withValues(alpha: 0.14),
            AppTokens.card2,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTokens.r20),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppTokens.r14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTokens.headingM.copyWith(color: AppTokens.text),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTokens.caption.copyWith(
                    color: AppTokens.text2,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s12,
          vertical: AppTokens.s12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTokens.info.withValues(alpha: 0.12)
              : AppTokens.card.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(AppTokens.r14),
          border: Border.all(
            color: isSelected ? AppTokens.info : AppTokens.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTokens.info.withValues(alpha: 0.14)
                    : AppTokens.card2,
                borderRadius: BorderRadius.circular(AppTokens.r12),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? AppTokens.info : AppTokens.text2,
              ),
            ),
            const SizedBox(width: AppTokens.s10),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTokens.caption.copyWith(
                  color: isSelected ? AppTokens.info : AppTokens.text,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
