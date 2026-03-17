import 'dart:io';

import 'package:flutter/material.dart';

import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/core/ui/AppTokens.dart';

// ─────────────────────────────────────────────────────────────
// Empty Workspace State — 3-step onboarding with animated prompt
// ─────────────────────────────────────────────────────────────
class EmptyWorkspaceState extends StatefulWidget {
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
  State<EmptyWorkspaceState> createState() => _EmptyWorkspaceStateState();
}

class _EmptyWorkspaceStateState extends State<EmptyWorkspaceState>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.93, end: 1.07).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) => Transform.scale(
                    scale: _pulseAnim.value,
                    child: child,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      // Outer glow ring
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTokens.primary.withValues(alpha: 0.12),
                            width: 1,
                          ),
                        ),
                      ),
                      // Inner circle
                      Container(
                        width: 98,
                        height: 98,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTokens.card2,
                          border: Border.all(
                            color: AppTokens.primary.withValues(alpha: 0.28),
                            width: 1.5,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppTokens.primary.withValues(alpha: 0.16),
                              blurRadius: 36,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 42,
                          color: AppTokens.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.s20),
                Text(
                  widget.label,
                  style: AppTokens.headingM.copyWith(
                    color: AppTokens.text,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTokens.s8),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: AppTokens.bodyM.copyWith(
                    color: AppTokens.text2,
                    height: 1.55,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppTokens.s20),
                // ── 3-step workflow mini-guide ──────────────
                Container(
                  padding: const EdgeInsets.all(AppTokens.s14),
                  decoration: BoxDecoration(
                    color: AppTokens.card.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(AppTokens.r16),
                    border: Border.all(
                      color: AppTokens.border.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      _WorkflowMiniStep(
                        number: '①',
                        label: 'Pick your photo & a reference',
                        isDone: false,
                      ),
                      const _StepConnector(),
                      _WorkflowMiniStep(
                        number: '②',
                        label: 'Choose a style or preset',
                        isDone: false,
                      ),
                      const _StepConnector(),
                      _WorkflowMiniStep(
                        number: '③',
                        label: 'Apply AI & save your result',
                        isDone: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.s20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s20,
                    vertical: AppTokens.s12,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTokens.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTokens.rFull),
                    boxShadow: AppTokens.primaryGlow(0.18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.upload_rounded,
                          color: Colors.black, size: 16),
                      const SizedBox(width: AppTokens.s8),
                      const Text(
                        'Tap to select photo',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
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

class _WorkflowMiniStep extends StatelessWidget {
  final String number;
  final String label;
  final bool isDone;
  const _WorkflowMiniStep({
    required this.number,
    required this.label,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isDone
                ? AppTokens.success.withValues(alpha: 0.18)
                : AppTokens.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone
                  ? AppTokens.success.withValues(alpha: 0.4)
                  : AppTokens.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Center(
            child: Text(
              isDone ? '✓' : number,
              style: TextStyle(
                color: isDone ? AppTokens.success : AppTokens.primary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTokens.s10),
        Expanded(
          child: Text(
            label,
            style: AppTokens.caption.copyWith(
              color: isDone ? AppTokens.success : AppTokens.text2,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 3, bottom: 3),
      child: Container(
        width: 2,
        height: 12,
        decoration: BoxDecoration(
          color: AppTokens.border.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppTokens.rFull),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Reference Thumbnail — corner badge on canvas
// ─────────────────────────────────────────────────────────────
class ReferenceThumbnail extends StatelessWidget {
  final String refPath;

  const ReferenceThumbnail({super.key, required this.refPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.r14),
        border: Border.all(color: AppTokens.info, width: 2.0),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTokens.info.withValues(alpha: 0.28),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
        image: DecorationImage(
          image: FileImage(File(refPath)),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: <Widget>[
          // Top-right corner REF badge
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppTokens.info.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
              child: Text(
                AppL10n.of(context).get('ref_short'),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Floating Context Toolbar — frosted pill on canvas
// ─────────────────────────────────────────────────────────────
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: AppTokens.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppTokens.rFull),
        border: Border.all(color: AppTokens.border.withValues(alpha: 0.5)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Compare hold button — fills on active
          GestureDetector(
            onTapDown: (_) => onCompareToggle(true),
            onTapUp: (_) => onCompareToggleEnd(),
            onTapCancel: onCompareToggleEnd,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isComparing
                    ? AppTokens.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTokens.rFull),
                border: isComparing
                    ? Border.all(
                        color: AppTokens.primary.withValues(alpha: 0.4),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.compare_rounded,
                    size: 16,
                    color: isComparing ? AppTokens.primary : AppTokens.text,
                  ),
                  const SizedBox(width: AppTokens.s6),
                  Text(
                    isComparing
                        ? l10n.get('original_label')
                        : l10n.get('compare_hold'),
                    style: AppTokens.caption.copyWith(
                      color: isComparing ? AppTokens.primary : AppTokens.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 18,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: AppTokens.s8),
            color: AppTokens.border.withValues(alpha: 0.6),
          ),
          // Fullscreen button
          Tooltip(
            message: l10n.get('fullscreen_label'),
            child: InkWell(
              onTap: onTapFullScreen,
              borderRadius: BorderRadius.circular(AppTokens.rFull),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.fullscreen_rounded,
                        size: 18, color: AppTokens.text),
                    if (isDesktop) ...<Widget>[
                      const SizedBox(width: AppTokens.s6),
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

// ─────────────────────────────────────────────────────────────
// Workspace Badge
// ─────────────────────────────────────────────────────────────
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTokens.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: color.withValues(alpha: 0.48)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 5),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Workspace Guidance Card — contextual helper overlay
// ─────────────────────────────────────────────────────────────
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
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppTokens.r10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: AppTokens.s10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: AppTokens.labelBold.copyWith(
                    color: AppTokens.text,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTokens.caption.copyWith(
                    color: AppTokens.text2,
                    height: 1.4,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(width: AppTokens.s8),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s10,
                  vertical: AppTokens.s8,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppTokens.r10),
                  border: Border.all(color: accent.withValues(alpha: 0.28)),
                ),
                child: Text(
                  actionLabel!,
                  style: AppTokens.caption.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Grid Painter — subtle canvas background
// ─────────────────────────────────────────────────────────────
class GridPainter extends CustomPainter {
  final Color color;
  final double spacing;

  GridPainter({required this.color, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

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
