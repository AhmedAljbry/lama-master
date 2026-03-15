import 'dart:io';

import 'package:flutter/material.dart';

import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/core/ui/AppTokens.dart';

class EmptyWorkspaceState extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final String subtitle;

  const EmptyWorkspaceState({
    super.key,
    required this.onTap,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTokens.card2,
                    border: Border.all(color: AppTokens.border, width: 2),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppTokens.primary.withValues(alpha: 0.16),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 46,
                    color: AppTokens.primary,
                  ),
                ),
                Flexible(child: const SizedBox(height: AppTokens.s24)),
                Text(
                  label,
                  style: AppTokens.headingM.copyWith(
                    color: AppTokens.text,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Flexible(child: const SizedBox(height: AppTokens.s12)),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTokens.bodyM.copyWith(
                    color: AppTokens.text2,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReferenceThumbnail extends StatelessWidget {
  final String refPath;

  const ReferenceThumbnail({super.key, required this.refPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: AppTokens.info, width: 2.2),
        boxShadow: AppTokens.primaryGlow(0.16),
        image: DecorationImage(
          image: FileImage(File(refPath)),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: AppTokens.s6,
            left: AppTokens.s6,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s8,
                vertical: AppTokens.s4,
              ),
              decoration: BoxDecoration(
                color: AppTokens.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(AppTokens.rFull),
              ),
              child: Text(
                'REF',
                style: AppTokens.caption.copyWith(
                  color: AppTokens.info,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FloatingContextToolbar extends StatelessWidget {
  final bool isComparing;
  final ValueChanged<bool> onCompareToggle;
  final VoidCallback onCompareToggleEnd;
  final VoidCallback onTapFullScreen;
  final AppL10n l10n;
  final bool isDesktop;

  const FloatingContextToolbar({
    super.key,
    required this.isComparing,
    required this.onCompareToggle,
    required this.onCompareToggleEnd,
    required this.onTapFullScreen,
    required this.l10n,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTokens.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(AppTokens.rFull),
        border: Border.all(color: AppTokens.border.withValues(alpha: 0.55)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GestureDetector(
            onTapDown: (_) => onCompareToggle(true),
            onTapUp: (_) => onCompareToggleEnd(),
            onTapCancel: onCompareToggleEnd,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isComparing
                    ? AppTokens.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTokens.rFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.compare_rounded,
                    size: 18,
                    color: isComparing ? AppTokens.primary : AppTokens.text,
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Text(
                    isComparing
                        ? l10n.get('original_label')
                        : l10n.get('compare_hold'),
                    style: AppTokens.caption.copyWith(
                      color: isComparing ? AppTokens.primary : AppTokens.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 20,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: AppTokens.s12),
            color: AppTokens.border,
          ),
          Tooltip(
            message: l10n.get('fullscreen_label'),
            child: InkWell(
              onTap: onTapFullScreen,
              borderRadius: BorderRadius.circular(AppTokens.rFull),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.fullscreen_rounded,
                      size: 20,
                      color: AppTokens.text,
                    ),
                    if (isDesktop) ...<Widget>[
                      const SizedBox(width: AppTokens.s8),
                      Text(
                        l10n.get('fullscreen_label'),
                        style: AppTokens.caption.copyWith(
                          color: AppTokens.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WorkspaceBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const WorkspaceBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class WorkspaceGuidanceCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const WorkspaceGuidanceCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s14),
      decoration: BoxDecoration(
        color: AppTokens.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppTokens.r18),
        border: Border.all(color: accent.withValues(alpha: 0.34)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppTokens.r12),
            ),
            child: Icon(icon, color: accent, size: 20),
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
                  subtitle,
                  style: AppTokens.caption.copyWith(
                    color: AppTokens.text2,
                    height: 1.45,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...<Widget>[
                  const SizedBox(height: AppTokens.s10),
                  InkWell(
                    onTap: onAction,
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.s12,
                        vertical: AppTokens.s10,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppTokens.r12),
                        border:
                            Border.all(color: accent.withValues(alpha: 0.24)),
                      ),
                      child: Text(
                        actionLabel!,
                        style: AppTokens.caption.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  final double spacing;

  GridPainter({required this.color, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.spacing != spacing;
  }
}
