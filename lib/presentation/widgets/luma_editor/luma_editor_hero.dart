import 'package:flutter/material.dart';
import 'package:lama/core/i18n/t.dart';
import 'package:lama/core/ui/tokens.dart';
import 'package:lama/features/luma_editor/domain/entities/ai_filter_insight.dart';
import 'package:lama/presentation/widgets/luma_editor/luma_editor_components.dart';

class LumaEditorHero extends StatelessWidget {
  final T t;
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
    required this.t,
    required this.accentColor,
    required this.aiLoading,
    required this.autoAi,
    required this.currentLook,
    required this.insight,
    required this.onRunAi,
    required this.onApplyAi,
    required this.onToggleAutoAi
  });

  @override
  Widget build(BuildContext context) {
    final title =
        aiLoading ? t.of('ai_loading') : insight?.headline ?? t.of('ai_idle');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(colors: [
            accentColor.withValues(alpha: .20),
            AppTokens.card.withValues(alpha: .94),
            Colors.white.withValues(alpha: .04)
          ], begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: accentColor.withValues(alpha: .24))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [accentColor, AppTokens.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.black, size: 22)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(t.of('control_center'),
                    style: const TextStyle(
                        color: AppTokens.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(currentLook,
                    style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ])),
          _HeroHeaderButton(
              icon: autoAi ? Icons.bolt_rounded : Icons.bolt_outlined,
              label: t.of('auto_ai'),
              onTap: onToggleAutoAi,
              active: autoAi),
        ]),
        const SizedBox(height: 14),
        Text(title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppTokens.text,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                height: 1.35)),
        const SizedBox(height: 8),
        Text(insight?.summary ?? t.of('ai_assistant'),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppTokens.text2, fontSize: 12, height: 1.55)),
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, children: [
          LumaCapsuleButton(
              icon: Icons.play_circle_fill_rounded,
              label: t.of('run_ai'),
              color: AppTokens.primary,
              onTap: onRunAi),
          LumaCapsuleButton(
              icon: Icons.auto_fix_high_rounded,
              label: t.of('ai_apply'),
              color: accentColor,
              onTap: onApplyAi),
        ]),
      ]),
    );
  }
}

class LumaPanelTabs extends StatelessWidget {
  final T t;
  final LumaPanelTab activeTab;
  final Color accentColor;
  final bool hasInsight;
  final ValueChanged<LumaPanelTab> onSelect;

  const LumaPanelTabs({
    super.key,
    required this.t,
    required this.activeTab,
    required this.accentColor,
    required this.hasInsight,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (LumaPanelTab.ai, Icons.auto_awesome_rounded, t.of('ai_tab')),
      (LumaPanelTab.filters, Icons.palette_outlined, t.of('filters')),
      (LumaPanelTab.adjust, Icons.tune_rounded, t.of('adjust')),
      (LumaPanelTab.tools, Icons.widgets_outlined, t.of('tools')),
    ];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: LumaPanelTabChip(
                  icon: item.$2,
                  label: item.$3,
                  active: activeTab == item.$1,
                  accentColor:
                      item.$1 == LumaPanelTab.ai ? AppTokens.primary : accentColor,
                  showBadge: hasInsight && item.$1 == LumaPanelTab.ai,
                  onTap: () => onSelect(item.$1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: AppTokens.normal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active
                ? accentColor.withValues(alpha: .34)
                : Colors.white.withValues(alpha: .10),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: .12),
                    blurRadius: 18,
                    spreadRadius: 1,
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
                Icon(icon, size: 17, color: effectiveColor),
                if (showBadge)
                  PositionedDirectional(
                    end: -4,
                    top: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTokens.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: effectiveColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeaderButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final bool active;
  
  const _HeroHeaderButton({
    required this.icon,
    required this.onTap,
    this.label,
    this.active = false,
  });
  
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: label == null ? 12 : 14, vertical: 11),
          decoration: BoxDecoration(
              color: active
                  ? AppTokens.primary.withValues(alpha: .14)
                  : Colors.white.withValues(alpha: .05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: active
                      ? AppTokens.primary.withValues(alpha: .45)
                      : Colors.white10)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                size: 18,
                color: onTap == null
                    ? AppTokens.text3
                    : active
                        ? AppTokens.primary
                        : AppTokens.text),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(label!,
                  style: TextStyle(
                      color: onTap == null
                          ? AppTokens.text3
                          : AppTokens.text,
                      fontSize: 11,
                      fontWeight: FontWeight.w800))
            ]
          ]),
        ),
      );
}
