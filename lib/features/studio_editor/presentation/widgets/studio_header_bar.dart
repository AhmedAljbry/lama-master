import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lama/core/i18n/locale_controller.dart';
import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/core/ui/AppTokens.dart';

class StudioHeaderBar extends StatelessWidget {
  final VoidCallback onBack;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final bool hasResult;
  final String statusLabel;
  final String styleLabel;
  final bool hasTarget;
  final bool hasReference;
  final bool useAI;

  const StudioHeaderBar({
    super.key,
    required this.onBack,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onSave,
    required this.onShare,
    required this.hasResult,
    required this.statusLabel,
    required this.styleLabel,
    required this.hasTarget,
    required this.hasReference,
    required this.useAI,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;

        return Container(
          height: 56,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? AppTokens.s10 : AppTokens.s14,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppTokens.surface.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(AppTokens.r20),
            border: Border.all(color: AppTokens.border.withValues(alpha: 0.45)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              // ── Back Button ──────────────────────────────
              _HeaderIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack,
                tooltip: l10n.get('btn_back'),
              ),

              // ── Brand / Title ───────────────────────────
              const SizedBox(width: AppTokens.s8),
              _TitleBlock(
                  isCompact: isCompact,
                  l10n: l10n,
                  statusLabel: statusLabel,
                  hasResult: hasResult),
              const Spacer(),

              // ── Undo / Redo — grouped micro-pill ────────
              _UndoRedoGroup(
                canUndo: canUndo,
                canRedo: canRedo,
                onUndo: onUndo,
                onRedo: onRedo,
                l10n: l10n,
              ),

              // ── Locale Toggle (hide on very compact) ────
              if (!isCompact) ...<Widget>[
                const SizedBox(width: AppTokens.s6),
                _LocalePill(
                  label: l10n.get('lang_switch'),
                  onTap: () =>
                      context.read<LocaleController>().toggleLocale(),
                ),
              ],

              // ── Save / Share (only when result ready) ───
              if (hasResult) ...<Widget>[
                const SizedBox(width: AppTokens.s6),
                _HeaderIconButton(
                  icon: Icons.ios_share_rounded,
                  onTap: onShare,
                  tooltip: l10n.get('btn_share'),
                  size: 18,
                ),
                const SizedBox(width: AppTokens.s6),
                _SaveButton(
                  label: l10n.get('btn_save'),
                  onTap: onSave,
                  compact: isCompact,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Title/Brand Block
// ─────────────────────────────────────────────────────────────
class _TitleBlock extends StatelessWidget {
  final bool isCompact;
  final AppL10n l10n;
  final String statusLabel;
  final bool hasResult;

  const _TitleBlock({
    required this.isCompact,
    required this.l10n,
    required this.statusLabel,
    required this.hasResult,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Brand icon with result glow
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: AppTokens.primaryGradient,
            borderRadius: BorderRadius.circular(AppTokens.r10),
            boxShadow: hasResult ? AppTokens.primaryGlow(0.26) : null,
          ),
          child: const Icon(
            Icons.auto_fix_high_rounded,
            color: Colors.black,
            size: 17,
          ),
        ),
        if (!isCompact) ...<Widget>[
          const SizedBox(width: AppTokens.s8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                l10n.get('app_title').toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTokens.text,
                  letterSpacing: 1.4,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                statusLabel,
                style: AppTokens.caption.copyWith(
                  color: AppTokens.text2,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Undo / Redo grouped micro-pill
// ─────────────────────────────────────────────────────────────
class _UndoRedoGroup extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final AppL10n l10n;

  const _UndoRedoGroup({
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTokens.rFull),
        border: Border.all(color: AppTokens.border.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _HeaderIconButton(
            icon: Icons.undo_rounded,
            onTap: canUndo ? onUndo : null,
            tooltip: l10n.get('btn_undo'),
            size: 17,
          ),
          Container(
            width: 1,
            height: 16,
            color: AppTokens.border.withValues(alpha: 0.5),
          ),
          _HeaderIconButton(
            icon: Icons.redo_rounded,
            onTap: canRedo ? onRedo : null,
            tooltip: l10n.get('btn_redo'),
            size: 17,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Header Icon Button
// ─────────────────────────────────────────────────────────────
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final double size;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: enabled
                ? AppTokens.card.withValues(alpha: 0.45)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTokens.r10),
          ),
          child: Icon(
            icon,
            size: size,
            color: enabled
                ? AppTokens.text
                : AppTokens.text2.withValues(alpha: 0.28),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Locale Pill
// ─────────────────────────────────────────────────────────────
class _LocalePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LocalePill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.rFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppTokens.card,
          borderRadius: BorderRadius.circular(AppTokens.rFull),
          border: Border.all(color: AppTokens.border.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: AppTokens.caption.copyWith(
            color: AppTokens.text,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Save CTA Button
// ─────────────────────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool compact;

  const _SaveButton({
    required this.label,
    required this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppTokens.s8 : AppTokens.s14,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          gradient: AppTokens.primaryGradient,
          borderRadius: BorderRadius.circular(AppTokens.r10),
          boxShadow: AppTokens.primaryGlow(0.18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.save_alt_rounded, size: 15, color: Colors.black),
            if (!compact) ...<Widget>[
              const SizedBox(width: AppTokens.s6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
