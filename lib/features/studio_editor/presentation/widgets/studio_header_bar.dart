import 'package:flutter/material.dart';

import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/core/ui/AppTokens.dart';

class StudioHeaderBar extends StatelessWidget {
  final VoidCallback onToggleLocale;
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
    required this.onToggleLocale,
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
        final isCompact = constraints.maxWidth < 760;
        final actions = _HeaderActions(
          canUndo: canUndo,
          canRedo: canRedo,
          hasResult: hasResult,
          onUndo: onUndo,
          onRedo: onRedo,
          onToggleLocale: onToggleLocale,
          onShare: onShare,
          onSave: onSave,
          l10n: l10n,
          compact: isCompact,
        );

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? AppTokens.s14 : AppTokens.s18,
            vertical: AppTokens.s14,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                AppTokens.surface.withValues(alpha: 0.98),
                Color.lerp(AppTokens.surface, AppTokens.card2, 0.5) ??
                    AppTokens.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r24),
            border: Border.all(color: AppTokens.border.withValues(alpha: 0.85)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _HeaderIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: onBack,
                    tooltip: l10n.get('btn_back'),
                  ),
                  const SizedBox(width: AppTokens.s14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _BrandBlock(l10n: l10n),
                      ],
                    ),
                  ),
                  if (!isCompact) ...<Widget>[
                    const SizedBox(width: AppTokens.s16),
                    Flexible(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: actions,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (isCompact) ...<Widget>[
                const SizedBox(height: AppTokens.s14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: actions,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BrandBlock extends StatelessWidget {
  final AppL10n l10n;

  const _BrandBlock({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: AppTokens.primaryGradient,
            borderRadius: BorderRadius.circular(AppTokens.r12),
            boxShadow: AppTokens.primaryGlow(0.18),
          ),
          child: const Icon(
            Icons.auto_fix_high_rounded,
            color: Colors.black,
            size: 20,
          ),
        ),
        const SizedBox(width: AppTokens.s12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTokens.primaryGradient.createShader(bounds),
              child: Text(
                l10n.get('app_title').toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2.2,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.get('workspace_label'),
              style: AppTokens.caption.copyWith(
                color: AppTokens.text2,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderActions extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final bool hasResult;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onToggleLocale;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final AppL10n l10n;
  final bool compact;

  const _HeaderActions({
    required this.canUndo,
    required this.canRedo,
    required this.hasResult,
    required this.onUndo,
    required this.onRedo,
    required this.onToggleLocale,
    required this.onShare,
    required this.onSave,
    required this.l10n,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTokens.s8,
      runSpacing: AppTokens.s8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _HeaderIconButton(
          icon: Icons.undo_rounded,
          onTap: canUndo ? onUndo : null,
          tooltip: l10n.get('btn_undo'),
        ),
        _HeaderIconButton(
          icon: Icons.redo_rounded,
          onTap: canRedo ? onRedo : null,
          tooltip: l10n.get('btn_redo'),
        ),
        _LocalePill(
          label: l10n.get('lang_switch'),
          onTap: onToggleLocale,
        ),
        if (hasResult) ...<Widget>[
          _ActionButton(
            icon: Icons.share_rounded,
            label: l10n.get('btn_share'),
            onTap: onShare,
            compact: compact,
          ),
          _ActionButton(
            icon: Icons.download_rounded,
            label: l10n.get('btn_save'),
            onTap: onSave,
            compact: compact,
            primary: true,
          ),
        ],
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: enabled ? AppTokens.card2 : AppTokens.card,
            borderRadius: BorderRadius.circular(AppTokens.r12),
            border: Border.all(
              color: enabled
                  ? AppTokens.border
                  : AppTokens.border.withValues(alpha: 0.45),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? AppTokens.text
                : AppTokens.text2.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _LocalePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LocalePill({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s12,
          vertical: AppTokens.s10,
        ),
        decoration: BoxDecoration(
          color: AppTokens.card,
          borderRadius: BorderRadius.circular(AppTokens.r12),
          border: Border.all(color: AppTokens.border),
        ),
        child: Text(
          label,
          style: AppTokens.caption.copyWith(
            color: AppTokens.text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;
  final bool primary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.compact,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppTokens.s12 : AppTokens.s16,
          vertical: AppTokens.s10,
        ),
        decoration: BoxDecoration(
          gradient: primary ? AppTokens.primaryGradient : null,
          color: primary ? null : AppTokens.card2,
          borderRadius: BorderRadius.circular(AppTokens.r12),
          border: Border.all(
            color: primary ? Colors.transparent : AppTokens.border,
          ),
          boxShadow: primary ? AppTokens.primaryGlow(0.18) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 16,
              color: primary ? Colors.black : AppTokens.text,
            ),
            if (!compact) ...<Widget>[
              const SizedBox(width: AppTokens.s8),
              Text(
                label,
                style: TextStyle(
                  color: primary ? Colors.black : AppTokens.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

