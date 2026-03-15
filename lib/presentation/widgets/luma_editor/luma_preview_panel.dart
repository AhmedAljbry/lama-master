import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lama/core/i18n/t.dart';
import 'package:lama/core/ui/tokens.dart';
import 'package:lama/features/luma_editor/domain/entities/ai_filter_insight.dart';
import 'package:lama/features/luma_editor/domain/entities/filter_item.dart';
import 'package:lama/presentation/widgets/LumaUltimateEditorWidgets/premium_empty_state.dart';
import 'package:lama/presentation/widgets/luma_editor/luma_editor_components.dart';

class LumaPreviewPanel extends StatelessWidget {
  final GlobalKey repaintKey;
  final Uint8List? bytes;
  final List<double> matrix;
  final FilterItem selected;
  final AiFilterInsight? insight;
  final bool aiLoading;
  final Color accentColor;
  final T t;
  final bool showOriginal;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;
  final VoidCallback? onToggleCompare;
  final VoidCallback? onToggleFavorite;
  final VoidCallback onPick;
  final VoidCallback? onRunAi;
  final VoidCallback? onApplyAi;
  
  const LumaPreviewPanel({
    super.key,
    required this.repaintKey,
    required this.bytes,
    required this.matrix,
    required this.selected,
    required this.insight,
    required this.aiLoading,
    required this.accentColor,
    required this.t,
    required this.showOriginal,
    required this.onHoldStart,
    required this.onHoldEnd,
    required this.onToggleCompare,
    required this.onToggleFavorite,
    required this.onPick,
    required this.onRunAi,
    required this.onApplyAi,
  });
  
  @override
  Widget build(BuildContext context) {
    final previewSignals = [
      LumaPreviewSignal(
        icon: Icons.palette_outlined,
        title: t.of('active_look'),
        value: bytes == null ? t.of('editor_title') : selected.name,
        color: accentColor,
      ),
      LumaPreviewSignal(
        icon: aiLoading
            ? Icons.hourglass_top_rounded
            : Icons.auto_awesome_rounded,
        title: t.of('ai_tab'),
        value: aiLoading
            ? t.of('loading')
            : insight?.suggestedName ?? t.of('run_ai'),
        color: AppTokens.primary,
      ),
      LumaPreviewSignal(
        icon: insight != null ? Icons.landscape_rounded : Icons.compare_rounded,
        title: insight != null ? t.of('scene') : t.of('compare'),
        value: insight != null ? insight!.sceneLabel : t.of('compare_hold'),
        color: insight != null ? AppTokens.info : AppTokens.warning,
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(colors: [
          Colors.white.withValues(alpha: .05),
          accentColor.withValues(alpha: .18),
          Colors.white.withValues(alpha: .03),
        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: accentColor.withValues(alpha: .28)),
        boxShadow: [
          BoxShadow(
              color: accentColor.withValues(alpha: .10),
              blurRadius: 28,
              spreadRadius: 1)
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          LayoutBuilder(builder: (context, c) {
            final compact = c.maxWidth < 620;
            final badges = Wrap(spacing: 8, runSpacing: 8, children: [
              LumaTag(
                  icon: Icons.auto_awesome_rounded,
                  label: bytes == null ? t.of('editor_title') : selected.name,
                  color: accentColor),
              LumaTag(
                  icon: Icons.visibility_rounded,
                  label: t.of('live_preview'),
                  color: AppTokens.info),
              LumaTag(
                  icon: aiLoading
                      ? Icons.hourglass_top_rounded
                      : Icons.bolt_rounded,
                  label: aiLoading
                      ? t.of('loading')
                      : insight != null
                          ? t.of('ai_ready')
                          : t.of('ai_tab'),
                  color: AppTokens.primary),
            ]);
            final actions = Wrap(spacing: 8, runSpacing: 8, children: [
              LumaTinyIcon(
                  icon: Icons.compare_rounded,
                  active: showOriginal,
                  color: AppTokens.primary,
                  onTap: onToggleCompare),
              LumaTinyIcon(
                  icon: selected.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  active: selected.isFavorite,
                  color: AppTokens.warning,
                  onTap: onToggleFavorite),
              if (bytes != null)
                LumaCapsuleButton(
                    icon: Icons.play_circle_fill_rounded,
                    label: t.of('run_ai'),
                    color: AppTokens.primary,
                    onTap: onRunAi),
            ]);
            if (compact) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    badges,
                    const SizedBox(height: 12),
                    actions,
                  ]);
            }
            return Row(children: [
              Expanded(child: badges),
              const SizedBox(width: 8),
              actions,
            ]);
          }),
          if (bytes != null) ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 720 ? 3 : 1;
                final itemWidth = columns == 1
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 20) / columns;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final item in previewSignals)
                      SizedBox(width: itemWidth, child: item),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: bytes == null
                  ? PremiumEmptyState(
                      primaryColor: AppTokens.primary,
                      surfaceColor: AppTokens.surface,
                      textColor: AppTokens.text,
                      text2Color: AppTokens.text2,
                      t: t,
                      onPick: onPick)
                  : GestureDetector(
                      onLongPressStart: (_) => onHoldStart(),
                      onLongPressEnd: (_) => onHoldEnd(),
                      child: RepaintBoundary(
                        key: repaintKey,
                        child: Container(
                          color: Colors.black,
                          child: Stack(children: [
                            Positioned(
                                top: -50,
                                left: -12,
                                child: LumaGlowBlob(
                                    color: accentColor.withValues(alpha: .14),
                                    size: 180)),
                            Positioned(
                                bottom: -80,
                                right: -20,
                                child: LumaGlowBlob(
                                    color:
                                        AppTokens.info.withValues(alpha: .12),
                                    size: 220)),
                            Positioned.fill(
                                child: DecoratedBox(
                                    decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                            colors: [
                                  accentColor.withValues(alpha: .16),
                                  Colors.transparent,
                                  AppTokens.info.withValues(alpha: .10),
                                ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight)))),
                            Positioned.fill(
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: showOriginal
                                      ? Image.memory(bytes!,
                                          key: const ValueKey('o'),
                                          fit: BoxFit.contain,
                                          gaplessPlayback: true)
                                      : ColorFiltered(
                                          key: const ValueKey('f'),
                                          colorFilter:
                                              ColorFilter.matrix(matrix),
                                          child: Image.memory(bytes!,
                                              fit: BoxFit.contain,
                                              gaplessPlayback: true)),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 14,
                              bottom: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: Colors.white10)),
                                child: Text(
                                    showOriginal
                                        ? t.of('compare')
                                        : t.of('compare_hold'),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                            if (insight != null)
                              Positioned(
                                top: 14,
                                left: 14,
                                child: Container(
                                  constraints:
                                      const BoxConstraints(maxWidth: 240),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                          color: accentColor.withValues(
                                              alpha: .30))),
                                  child: Text(insight!.headline,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: accentColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900)),
                                ),
                              ),
                            if (insight != null)
                              Positioned(
                                top: 14,
                                right: 14,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    LumaOverlayPill(
                                      label:
                                          '${t.of('scene')}: ${insight!.sceneLabel}',
                                      color: AppTokens.info,
                                    ),
                                    const SizedBox(height: 8),
                                    LumaOverlayPill(
                                      label:
                                          '${t.of('mood')}: ${insight!.moodLabel}',
                                      color: AppTokens.warning,
                                    ),
                                  ],
                                ),
                              ),
                            Positioned(
                              right: 14,
                              bottom: 14,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (bytes != null)
                                    LumaCapsuleButton(
                                        icon: Icons.play_circle_fill_rounded,
                                        label: t.of('run_ai'),
                                        color: AppTokens.primary,
                                        onTap: onRunAi),
                                  const SizedBox(width: 8),
                                  if (bytes != null)
                                    LumaCapsuleButton(
                                        icon: Icons.auto_fix_high_rounded,
                                        label: t.of('ai_apply'),
                                        color: accentColor,
                                        onTap: onApplyAi),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
            ),
          ),
        ]),
      ),
    );
  }
}

class LumaPreviewSignal extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const LumaPreviewSignal({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: .18)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTokens.text2,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTokens.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w900)),
                  ]),
            ),
          ],
        ),
      );
}

class LumaOverlayPill extends StatelessWidget {
  final String label;
  final Color color;

  const LumaOverlayPill({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: .28)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w800)),
      );
}
