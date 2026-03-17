import 'package:flutter/material.dart';
import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/core/ui/tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LumaColorAppBar — slim top bar replacing the oversized card-style header.
//
// Layout (56 dp height):
//   [pick icon]  "Color"  subtitle  ···  [Reset]  [Save ✓]
// ─────────────────────────────────────────────────────────────────────────────

class LumaColorAppBar extends StatelessWidget {
  final AppL10n l10n;
  final bool hasImage;
  final bool saving;
  final String? currentFilter;
  final VoidCallback onPick;
  final VoidCallback? onReset;
  final VoidCallback? onSave;

  const LumaColorAppBar({
    super.key,
    required this.l10n,
    required this.hasImage,
    required this.saving,
    this.currentFilter,
    required this.onPick,
    this.onReset,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // ── Pick image button ──────────────────────────────────────────
          _BarIconBtn(
            icon: Icons.photo_library_outlined,
            onTap: onPick,
            tooltip: l10n.get('tap_to_open'),
          ),
          const SizedBox(width: 6),
          // ── Title + subtitle ───────────────────────────────────────────
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.get('color_title'),
                  style: const TextStyle(
                    color: AppTokens.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                if (currentFilter != null)
                  Text(
                    currentFilter!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTokens.primary.withValues(alpha: .85),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          // ── Reset ─────────────────────────────────────────────────────
          if (hasImage)
            _BarTextBtn(
              label: l10n.get('reset'),
              onTap: onReset,
              color: AppTokens.text2,
            ),
          const SizedBox(width: 6),
          // ── Save ──────────────────────────────────────────────────────
          _SaveButton(saving: saving, onTap: onSave, l10n: l10n),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legacy LumaAppBar — preserved so other callers are not broken.
// New code should use LumaColorAppBar.
// ─────────────────────────────────────────────────────────────────────────────

class LumaAppBar extends StatelessWidget {
  final AppL10n l10n;
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
    required this.l10n,
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
  Widget build(BuildContext context) => LumaColorAppBar(
        l10n: l10n,
        hasImage: hasImage,
        saving: saving,
        currentFilter: currentLook,
        onPick: onPick,
        onSave: onSave,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

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
    this.filled = false,
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
                      fontWeight: FontWeight.w800)),
            ]
          ]),
        ),
      );
}

// ── Private helpers ────────────────────────────────────────────────────────

class _BarIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _BarIconBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: .10)),
            ),
            child: Icon(icon, size: 20, color: AppTokens.text2),
          ),
        ),
      );
}

class _BarTextBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _BarTextBtn({
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

class _SaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback? onTap;
  final AppL10n l10n;

  const _SaveButton(
      {required this.saving, required this.onTap, required this.l10n});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: AppTokens.normal,
        child: FilledButton.icon(
          onPressed: saving ? null : onTap,
          icon: Icon(
            saving ? Icons.hourglass_top_rounded : Icons.check_rounded,
            size: 16,
          ),
          label: Text(
            saving ? l10n.get('loading') : l10n.get('save'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: onTap != null ? AppTokens.primary : AppTokens.card,
            foregroundColor: onTap != null ? Colors.black : AppTokens.text3,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            minimumSize: const Size(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
}
