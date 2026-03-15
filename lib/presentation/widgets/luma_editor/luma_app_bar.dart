import 'package:flutter/material.dart';
import 'package:lama/core/i18n/t.dart';
import 'package:lama/core/ui/tokens.dart';
import 'package:lama/presentation/widgets/luma_editor/luma_editor_components.dart';

class LumaAppBar extends StatelessWidget {
  final T t;
  final bool hasImage;
  final bool saving;
  final bool aiLoading;
  final bool autoAi;
  final bool hasInsight;
  final String? currentLook;
  final VoidCallback onToggleLang;
  final VoidCallback onToggleAutoAi;
  final VoidCallback onPick;
  final VoidCallback? onRunAi;
  final VoidCallback? onSave;

  const LumaAppBar({
    super.key,
    required this.t,
    required this.hasImage,
    required this.saving,
    required this.aiLoading,
    required this.autoAi,
    required this.hasInsight,
    required this.currentLook,
    required this.onToggleLang,
    required this.onToggleAutoAi,
    required this.onPick,
    required this.onRunAi,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = aiLoading
        ? t.of('ai_loading')
        : hasInsight
            ? t.of('ai_ready')
            : t.of('ai_idle');
    final statusColor = aiLoading
        ? AppTokens.info
        : hasInsight
            ? AppTokens.primary
            : AppTokens.warning;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(colors: [
            Colors.white.withValues(alpha: .06),
            AppTokens.surface.withValues(alpha: .94),
            AppTokens.info.withValues(alpha: .08)
          ], begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: Colors.white.withValues(alpha: .08))),
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxWidth < 820;
          final intro =
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                const Text('Luma Color',
                    style: TextStyle(
                        color: AppTokens.text,
                        fontSize: 28,
                        fontWeight: FontWeight.w900)),
                LumaTag(
                    icon: aiLoading
                        ? Icons.hourglass_top_rounded
                        : hasInsight
                            ? Icons.bolt_rounded
                            : Icons.motion_photos_pause_rounded,
                    label: hasInsight ? t.of('ai_ready_short') : t.of('ai_tab'),
                    color: statusColor),
              ],
            ),
            const SizedBox(height: 6),
            Text(t.of('luma_desc'),
                style: const TextStyle(color: AppTokens.text2, fontSize: 13)),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              LumaTag(
                  icon: Icons.auto_awesome_rounded,
                  label: t.of('control_center'),
                  color: AppTokens.primary),
              LumaTag(
                  icon: Icons.visibility_rounded,
                  label: t.of('live_preview'),
                  color: AppTokens.info),
              if (currentLook != null)
                LumaTag(
                    icon: Icons.palette_outlined,
                    label: currentLook!,
                    color: AppTokens.warning),
              if (autoAi)
                LumaTag(
                    icon: Icons.bolt_rounded,
                    label: t.of('auto_ai'),
                    color: AppTokens.primary),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: statusColor.withValues(alpha: .18)),
              ),
              child: Row(
                children: [
                  Icon(Icons.insights_rounded, color: statusColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(statusText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTokens.text2,
                            fontSize: 12,
                            height: 1.45)),
                  ),
                ],
              ),
            ),
          ]);
          
          final actions = Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              LumaHeaderButton(
                  icon: Icons.translate_rounded,
                  label: t.langLabel,
                  onTap: onToggleLang),
              LumaHeaderButton(
                  icon: autoAi ? Icons.bolt_rounded : Icons.bolt_outlined,
                  label: t.of('auto_ai'),
                  onTap: onToggleAutoAi,
                  active: autoAi),
              LumaHeaderButton(
                  icon: Icons.photo_library_rounded,
                  label: t.of('tap_to_open'),
                  onTap: onPick),
              LumaHeaderButton(
                  icon: aiLoading
                      ? Icons.hourglass_top_rounded
                      : Icons.play_circle_fill_rounded,
                  label: t.of('run_ai'),
                  onTap: onRunAi,
                  active: hasImage),
              LumaHeaderButton(
                  icon: saving
                      ? Icons.hourglass_top_rounded
                      : Icons.save_alt_rounded,
                  label: t.of('save'),
                  onTap: onSave,
                  active: onSave != null,
                  filled: true),
            ],
          );
          
          if (compact) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  intro,
                  const SizedBox(height: 16),
                  actions,
                ]);
          }
          return Row(children: [
            Expanded(child: intro),
            const SizedBox(width: 16),
            ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: actions),
          ]);
        },
      ),
    );
  }
}

class LumaHeaderButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final bool active;
  final bool filled;
  
  const LumaHeaderButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
    this.active = false,
    this.filled = false
  });
  
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: label == null ? 12 : 14, vertical: 11),
          decoration: BoxDecoration(
              color: filled
                  ? (onTap != null ? AppTokens.primary : AppTokens.card)
                  : active
                      ? AppTokens.primary.withValues(alpha: .14)
                      : Colors.white.withValues(alpha: .05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: filled
                      ? AppTokens.primary
                          .withValues(alpha: onTap != null ? 0 : .18)
                      : active
                          ? AppTokens.primary.withValues(alpha: .45)
                          : Colors.white10)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                size: 18,
                color: onTap == null
                    ? AppTokens.text3
                    : filled
                        ? Colors.black
                        : active
                            ? AppTokens.primary
                            : AppTokens.text),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(label!,
                  style: TextStyle(
                      color: onTap == null
                          ? AppTokens.text3
                          : filled
                              ? Colors.black
                              : AppTokens.text,
                      fontSize: 11,
                      fontWeight: FontWeight.w800))
            ]
          ]),
        ),
      );
}
