import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/core/ui/tokens.dart';
import 'package:lama/features/luma_editor/domain/entities/ai_filter_insight.dart';
import 'package:lama/features/luma_editor/domain/entities/filter_item.dart';
import 'package:lama/presentation/widgets/LumaUltimateEditorWidgets/premium_empty_state.dart';
import 'package:lama/presentation/widgets/luma_editor/luma_editor_components.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LumaPreviewPanel — clean, full-canvas image preview.
//
// Changes from original:
//   • Removed badge row (Active Look / AI / Compare tags) above the image
//   • Removed LumaPreviewSignal stat tiles — those details live in the panel
//   • Image now fills the container for maximum editing real-estate
//   • Kept: RepaintBoundary, ColorFiltered, hold-compare GestureDetector,
//           AI insight pills, empty-state picker, Run AI / Apply AI overlays
// ─────────────────────────────────────────────────────────────────────────────

class LumaPreviewPanel extends StatelessWidget {
  final GlobalKey repaintKey;
  final Uint8List? bytes;
  final List<double> matrix;
  final FilterItem selected;
  final AiFilterInsight? insight;
  final bool aiLoading;
  final Color accentColor;
  final AppL10n l10n;
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
    required this.l10n,
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: Colors.black,
        border: Border.all(
            color: accentColor.withValues(alpha: .20), width: 1),
        boxShadow: [
          BoxShadow(
              color: accentColor.withValues(alpha: .08),
              blurRadius: 24,
              spreadRadius: 0),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: bytes == null
            ? PremiumEmptyState(
                primaryColor: AppTokens.primary,
                surfaceColor: AppTokens.surface,
                textColor: AppTokens.text,
                text2Color: AppTokens.text2,
                l10n: l10n,
                onPick: onPick)
            : GestureDetector(
                onLongPressStart: (_) => onHoldStart(),
                onLongPressEnd: (_) => onHoldEnd(),
                child: RepaintBoundary(
                  key: repaintKey,
                  child: Container(
                    color: Colors.black,
                    child: Stack(children: [
                      // subtle ambient glow
                      Positioned(
                          top: -50,
                          left: -12,
                          child: LumaGlowBlob(
                              color: accentColor.withValues(alpha: .10),
                              size: 180)),
                      Positioned(
                          bottom: -80,
                          right: -20,
                          child: LumaGlowBlob(
                              color: AppTokens.info.withValues(alpha: .08),
                              size: 220)),

                      // ── Main image ──────────────────────────────────────
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

                      // ── Compare label (bottom-left) ─────────────────────
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: AnimatedOpacity(
                          opacity: showOriginal ? 1 : 0.55,
                          duration: AppTokens.fast,
                          child: _OverlayPill(
                            label: showOriginal
                                ? l10n.get('compare')
                                : l10n.get('compare_hold'),
                            color: showOriginal
                                ? AppTokens.primary
                                : Colors.white54,
                          ),
                        ),
                      ),

                      // ── AI insight headline (top-left) ──────────────────
                      if (insight != null)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: 220),
                            child: _OverlayPill(
                              label: insight!.headline,
                              color: accentColor,
                            ),
                          ),
                        ),

                      // ── AI scene / mood (top-right) ─────────────────────
                      if (insight != null)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              LumaOverlayPill(
                                label:
                                    '${l10n.get('scene')}: ${insight!.sceneLabel}',
                                color: AppTokens.info,
                              ),
                              const SizedBox(height: 6),
                              LumaOverlayPill(
                                label:
                                    '${l10n.get('mood')}: ${insight!.moodLabel}',
                                color: AppTokens.warning,
                              ),
                            ],
                          ),
                        ),

                      // ── Action pills (bottom-right) ─────────────────────
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Favorite toggle
                            _CircleIconBtn(
                              icon: selected.isFavorite
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: selected.isFavorite
                                  ? AppTokens.warning
                                  : Colors.white54,
                              onTap: onToggleFavorite,
                            ),
                            const SizedBox(width: 6),
                            // Apply AI
                            if (insight != null)
                              LumaCapsuleButton(
                                  icon: Icons.auto_fix_high_rounded,
                                  label: l10n.get('ai_apply'),
                                  color: accentColor,
                                  onTap: onApplyAi),
                          ],
                        ),
                      ),

                      // ── AI loading indicator ────────────────────────────
                      if (aiLoading)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: .28),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppTokens.primary,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Re-exported helpers (kept for other callers)
// ─────────────────────────────────────────────────────────────────────────────

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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: .28)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────────────────────

class _OverlayPill extends StatelessWidget {
  final String label;
  final Color color;
  const _OverlayPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800)),
      );
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _CircleIconBtn(
      {required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: .40)),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      );
}
