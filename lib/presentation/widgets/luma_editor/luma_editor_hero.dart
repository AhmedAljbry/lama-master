import 'package:flutter/material.dart';
import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/core/ui/tokens.dart';
import 'package:lama/features/luma_editor/domain/entities/ai_filter_insight.dart';
import 'package:lama/presentation/widgets/luma_editor/luma_editor_components.dart';

// ─────────────────────────────────────────────────────────────────────────────
// New panel tab values for the redesigned editor.
// The enum is extended but old values (ai, filters) remain for compatibility.
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// LumaCompactFilterInfo — replaces the tall LumaEditorHero.
// Shows a one-line "current filter + AI status" row above the tabs.
// ─────────────────────────────────────────────────────────────────────────────

class LumaCompactFilterInfo extends StatelessWidget {
  final AppL10n l10n;
  final Color accentColor;
  final bool aiLoading;
  final bool autoAi;
  final String currentLook;
  final bool hasInsight;
  final VoidCallback onRunAi;
  final VoidCallback? onApplyAi;
  final VoidCallback onToggleAutoAi;

  const LumaCompactFilterInfo({
    super.key,
    required this.l10n,
    required this.accentColor,
    required this.aiLoading,
    required this.autoAi,
    required this.currentLook,
    required this.hasInsight,
    required this.onRunAi,
    required this.onApplyAi,
    required this.onToggleAutoAi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: .14)),
      ),
      child: Row(children: [
        // Filter dot
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        // Filter name
        Expanded(
          child: Text(
            currentLook,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: AppTokens.text,
                fontSize: 13,
                fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 8),
        // AI status badge
        _AiBadge(
          aiLoading: aiLoading,
          hasInsight: hasInsight,
          l10n: l10n,
          color: aiLoading
              ? AppTokens.info
              : hasInsight
                  ? AppTokens.primary
                  : AppTokens.text3,
        ),
        const SizedBox(width: 6),
        // Run AI button
        _SmallIconBtn(
          icon: aiLoading
              ? Icons.hourglass_top_rounded
              : Icons.play_circle_fill_rounded,
          color: AppTokens.primary,
          active: !aiLoading,
          onTap: aiLoading ? null : onRunAi,
          tooltip: l10n.get('run_ai'),
        ),
        // Apply AI button
        if (hasInsight) ...[
          const SizedBox(width: 4),
          _SmallIconBtn(
            icon: Icons.auto_fix_high_rounded,
            color: accentColor,
            active: true,
            onTap: onApplyAi,
            tooltip: l10n.get('ai_apply'),
          ),
        ],
        const SizedBox(width: 4),
        // AutoAI toggle
        _SmallIconBtn(
          icon: autoAi ? Icons.bolt_rounded : Icons.bolt_outlined,
          color: autoAi ? AppTokens.primary : AppTokens.text3,
          active: autoAi,
          onTap: onToggleAutoAi,
          tooltip: l10n.get('auto_ai'),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LumaEditorHero — KEPT for backward compat, but simplified.
// New code should use LumaCompactFilterInfo instead.
// ─────────────────────────────────────────────────────────────────────────────

class LumaEditorHero extends StatelessWidget {
  final AppL10n l10n;
  final Color accentColor;
  final bool aiLoading;
  final bool autoAi;
  final String currentLook;
  final AiFilterInsight? insight;
  final VoidCallback onRunAi;
  final VoidCallback? onApplyAi;
  final VoidCallback onToggleAutoAi;

  const LumaEditorHero({
    super.key,
    required this.l10n,
    required this.accentColor,
    required this.aiLoading,
    required this.autoAi,
    required this.currentLook,
    required this.insight,
    required this.onRunAi,
    required this.onApplyAi,
    required this.onToggleAutoAi,
  });

  @override
  Widget build(BuildContext context) => LumaCompactFilterInfo(
        l10n: l10n,
        accentColor: accentColor,
        aiLoading: aiLoading,
        autoAi: autoAi,
        currentLook: currentLook,
        hasInsight: insight != null,
        onRunAi: onRunAi,
        onApplyAi: onApplyAi,
        onToggleAutoAi: onToggleAutoAi,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// LumaPanelTabs — updated labels (Adjust / Presets / Tools / AI)
// Tab bar styling unchanged; tab order adjusted.
// ─────────────────────────────────────────────────────────────────────────────

class LumaPanelTabs extends StatelessWidget {
  final AppL10n l10n;
  final LumaPanelTab activeTab;
  final Color accentColor;
  final bool hasInsight;
  final ValueChanged<LumaPanelTab> onSelect;

  const LumaPanelTabs({
    super.key,
    required this.l10n,
    required this.activeTab,
    required this.accentColor,
    required this.hasInsight,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // Redesigned tab order: Adjust first (most common), then Filters=Presets,
    // then Tools, then AI (power user)
    final items = [
      (LumaPanelTab.adjust, Icons.tune_rounded, l10n.get('adjust')),
      (LumaPanelTab.filters, Icons.palette_outlined, l10n.get('filters')),
      (LumaPanelTab.tools, Icons.widgets_outlined, l10n.get('tools')),
      (LumaPanelTab.ai, Icons.auto_awesome_rounded, l10n.get('ai_tab')),
    ];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .03),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: LumaPanelTabChip(
                  icon: item.$2,
                  label: item.$3,
                  active: activeTab == item.$1,
                  accentColor: item.$1 == LumaPanelTab.ai
                      ? AppTokens.primary
                      : accentColor,
                  showBadge:
                      hasInsight && item.$1 == LumaPanelTab.ai,
                  onTap: () => onSelect(item.$1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LumaPanelTabChip — unchanged styling
// ─────────────────────────────────────────────────────────────────────────────

class LumaPanelTabChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color accentColor;
  final bool showBadge;
  final VoidCallback onTap;

  const LumaPanelTabChip({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.accentColor,
    required this.showBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = active ? accentColor : AppTokens.text2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: AppTokens.normal,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: active
                ? [
                    accentColor.withValues(alpha: .20),
                    accentColor.withValues(alpha: .08),
                  ]
                : [
                    Colors.white.withValues(alpha: .04),
                    Colors.white.withValues(alpha: .02),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? accentColor.withValues(alpha: .34)
                : Colors.white.withValues(alpha: .08),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: .12),
                    blurRadius: 14,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 16, color: effectiveColor),
                if (showBadge)
                  PositionedDirectional(
                    end: -4,
                    top: -4,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTokens.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: effectiveColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────────────────────

class _AiBadge extends StatelessWidget {
  final bool aiLoading;
  final bool hasInsight;
  final AppL10n l10n;
  final Color color;
  const _AiBadge(
      {required this.aiLoading,
      required this.hasInsight,
      required this.l10n,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: .26)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            aiLoading
                ? Icons.hourglass_top_rounded
                : hasInsight
                    ? Icons.bolt_rounded
                    : Icons.bolt_outlined,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            aiLoading
                ? l10n.get('ai_status_loading_short')
                : hasInsight
                    ? l10n.get('ai_status_ready_short')
                    : l10n.get('ai_status_idle_short'),
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ]),
      );
}

class _SmallIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback? onTap;
  final String tooltip;
  const _SmallIconBtn(
      {required this.icon,
      required this.color,
      required this.active,
      required this.onTap,
      required this.tooltip});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: active
                  ? color.withValues(alpha: .14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 16, color: active ? color : AppTokens.text3),
          ),
        ),
      );
}
