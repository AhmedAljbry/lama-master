import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/ui/AppL10n.dart';
import '../../../../core/i18n/t.dart';
import 'inpainting_studio_chrome.dart';

enum InpaintingControlsLayout { sideDock, bottomDock }

class InpaintingBrushControls extends StatelessWidget {
  final AppL10n l10n;
  final T t;
  final InpaintingControlsLayout layout;
  final bool isEraser;
  final bool hasMask;
  final bool canUndo;
  final bool canRedo;
  final bool maskVisible;
  final bool compareEnabled;
  final double brushPx;
  final double currentZoom;
  final int strokeCount;
  final VoidCallback onBrushMode;
  final VoidCallback onEraserMode;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final VoidCallback onResetWorkspace;
  final VoidCallback onResetViewport;
  final VoidCallback onMagic;
  final VoidCallback onToggleMaskVisibility;
  final VoidCallback onToggleCompare;
  final ValueChanged<double> onBrushSizeChanged;

  const InpaintingBrushControls({
    super.key,
    required this.l10n,
    required this.t,
    required this.layout,
    required this.isEraser,
    required this.hasMask,
    required this.canUndo,
    required this.canRedo,
    required this.maskVisible,
    required this.compareEnabled,
    required this.brushPx,
    required this.currentZoom,
    required this.strokeCount,
    required this.onBrushMode,
    required this.onEraserMode,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onResetWorkspace,
    required this.onResetViewport,
    required this.onMagic,
    required this.onToggleMaskVisibility,
    required this.onToggleCompare,
    required this.onBrushSizeChanged,
  });

  bool get _isSideDock => layout == InpaintingControlsLayout.sideDock;

  @override
  Widget build(BuildContext context) {
    final radius = _isSideDock
        ? BorderRadius.circular(32)
        : BorderRadius.vertical(top: Radius.circular(30));
    final accent =
        isEraser ? InpaintingStudioTheme.rose : InpaintingStudioTheme.mint;
    final compact = !_isSideDock;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: InpaintingStudioTheme.surfaceSoft,
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              // ── Drag handle (bottom dock only) ──────────────────
              if (!_isSideDock) ...[
                Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 4),
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],

              // ── Scrollable content ──────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 14 : 18,
                    compact ? 8 : 16,
                    compact ? 14 : 18,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 1. Tool toggle ─────────────────────────
                      _SectionHeader(label: l10n.get('tools')),
                      SizedBox(height: 8),
                      _BrushEraseToggle(
                        isEraser: isEraser,
                        brushLabel: l10n.get('brush'),
                        eraserLabel: l10n.get('eraser'),
                        onBrushMode: onBrushMode,
                        onEraserMode: onEraserMode,
                      ),
                      SizedBox(height: 10),

                      // ── 2. Quick actions ───────────────────────
                      _QuickActionsRow(
                        canUndo: canUndo,
                        canRedo: canRedo,
                        hasMask: hasMask,
                        undoLabel: l10n.get('undo'),
                        redoLabel: l10n.get('redo'),
                        clearLabel: l10n.get('clear'),
                        onUndo: onUndo,
                        onRedo: onRedo,
                        onClear: onClear,
                      ),
                      SizedBox(height: 14),

                      // ── 3. Brush size ──────────────────────────
                      _SectionHeader(label: l10n.get('brush_size')),
                      SizedBox(height: 8),
                      _BrushSizePanel(
                        brushPx: brushPx,
                        strokeCount: strokeCount,
                        isEraser: isEraser,
                        accent: accent,
                        onBrushSizeChanged: onBrushSizeChanged,
                      ),
                      SizedBox(height: 14),

                      // ── 4. Advanced (collapsible) ───────────────
                      _AdvancedSection(
                        maskVisible: maskVisible,
                        compareEnabled: compareEnabled,
                        currentZoom: currentZoom,
                        hasMask: hasMask,
                        l10n: l10n,
                        t: t,
                        onToggleMaskVisibility: onToggleMaskVisibility,
                        onToggleCompare: onToggleCompare,
                        onResetViewport: onResetViewport,
                      ),
                      SizedBox(height: 14),
                    ],
                  ),
                ),
              ),

              // ── Pinned CTA row (always visible, no scroll) ──────
              _PinnedCtaRow(
                hasMask: hasMask,
                resetLabel: l10n.get('reset'),
                magicLabel: l10n.get('magic'),
                onReset: onResetWorkspace,
                onMagic: onMagic,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Section header
// ═════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: InpaintingStudioTheme.textMuted,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.9,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 1. Brush / Erase toggle (full-width segmented control)
// ═════════════════════════════════════════════════════════════════════════════

class _BrushEraseToggle extends StatelessWidget {
  final bool isEraser;
  final String brushLabel;
  final String eraserLabel;
  final VoidCallback onBrushMode;
  final VoidCallback onEraserMode;

  const _BrushEraseToggle({
    required this.isEraser,
    required this.brushLabel,
    required this.eraserLabel,
    required this.onBrushMode,
    required this.onEraserMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          _ToggleSegment(
            icon: Icons.brush_rounded,
            label: brushLabel,
            active: !isEraser,
            accent: InpaintingStudioTheme.mint,
            onTap: onBrushMode,
            leftRadius: true,
            rightRadius: false,
          ),
          Container(width: 1, color: Colors.white.withValues(alpha: 0.07)),
          _ToggleSegment(
            icon: Icons.auto_fix_off_rounded,
            label: eraserLabel,
            active: isEraser,
            accent: InpaintingStudioTheme.rose,
            onTap: onEraserMode,
            leftRadius: false,
            rightRadius: true,
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;
  final bool leftRadius;
  final bool rightRadius;

  const _ToggleSegment({
    required this.icon,
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
    required this.leftRadius,
    required this.rightRadius,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.horizontal(
      left: leftRadius ? const Radius.circular(20) : Radius.zero,
      right: rightRadius ? const Radius.circular(20) : Radius.zero,
    );

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: br,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: active ? accent.withValues(alpha: 0.16) : Colors.transparent,
            borderRadius: br,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: active ? accent : InpaintingStudioTheme.textSecondary,
              ),
              SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: active ? accent : InpaintingStudioTheme.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 2. Quick actions: Undo · Redo · Clear
// ═════════════════════════════════════════════════════════════════════════════

class _QuickActionsRow extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final bool hasMask;
  final String undoLabel;
  final String redoLabel;
  final String clearLabel;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;

  const _QuickActionsRow({
    required this.canUndo,
    required this.canRedo,
    required this.hasMask,
    required this.undoLabel,
    required this.redoLabel,
    required this.clearLabel,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickButton(
            icon: Icons.undo_rounded,
            label: undoLabel,
            enabled: canUndo,
            onTap: onUndo,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _QuickButton(
            icon: Icons.redo_rounded,
            label: redoLabel,
            enabled: canRedo,
            onTap: onRedo,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _QuickButton(
            icon: Icons.delete_outline_rounded,
            label: clearLabel,
            enabled: hasMask,
            onTap: onClear,
            accent: InpaintingStudioTheme.danger,
          ),
        ),
      ],
    );
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final Color accent;

  const _QuickButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.accent = InpaintingStudioTheme.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.32,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: accent),
              SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 3. Brush size slider + presets
// ═════════════════════════════════════════════════════════════════════════════

class _BrushSizePanel extends StatelessWidget {
  final double brushPx;
  final int strokeCount;
  final bool isEraser;
  final Color accent;
  final ValueChanged<double> onBrushSizeChanged;

  const _BrushSizePanel({
    required this.brushPx,
    required this.strokeCount,
    required this.isEraser,
    required this.accent,
    required this.onBrushSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Size label + stroke count pill row
          Row(
            children: [
              _InfoChip(
                icon: isEraser
                    ? Icons.auto_fix_off_rounded
                    : Icons.brush_rounded,
                label: '${brushPx.round()} px',
                accent: accent,
              ),
              SizedBox(width: 8),
              _InfoChip(
                icon: Icons.gesture_rounded,
                label: '$strokeCount',
                accent: InpaintingStudioTheme.violet,
              ),
            ],
          ),
          SizedBox(height: 12),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: accent,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: brushPx.clamp(8.0, 120.0),
              min: 8,
              max: 120,
              onChanged: onBrushSizeChanged,
            ),
          ),
          SizedBox(height: 8),

          // Preset chips
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [12.0, 20.0, 32.0, 48.0, 72.0, 96.0].map((preset) {
              final selected = (brushPx - preset).abs() < 6;
              return _PresetChip(
                label: '${preset.toInt()}',
                selected: selected,
                accent: accent,
                onTap: () => onBrushSizeChanged(preset),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 4. Advanced section (collapsible)
// ═════════════════════════════════════════════════════════════════════════════

class _AdvancedSection extends StatelessWidget {
  final bool maskVisible;
  final bool compareEnabled;
  final double currentZoom;
  final bool hasMask;
  final AppL10n l10n;
  final T t;
  final VoidCallback onToggleMaskVisibility;
  final VoidCallback onToggleCompare;
  final VoidCallback onResetViewport;

  const _AdvancedSection({
    required this.maskVisible,
    required this.compareEnabled,
    required this.currentZoom,
    required this.hasMask,
    required this.l10n,
    required this.t,
    required this.onToggleMaskVisibility,
    required this.onToggleCompare,
    required this.onResetViewport,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: InpaintingStudioTheme.surfaceStrong.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding:
              EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: InpaintingStudioTheme.cyan.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 16,
              color: InpaintingStudioTheme.cyan,
            ),
          ),
          title: Text(
            l10n.get('preview_tools'),
            style: TextStyle(
              color: InpaintingStudioTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
          iconColor: InpaintingStudioTheme.textSecondary,
          collapsedIconColor: InpaintingStudioTheme.textMuted,
          children: [
            _ToggleTile(
              label: t.of('workflow_mask'),
              subtitle: maskVisible
                  ? t.of('editor_mask_ready')
                  : t.of('original_label'),
              icon: maskVisible
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              accent: InpaintingStudioTheme.cyan,
              selected: maskVisible,
              onTap: onToggleMaskVisibility,
            ),
            SizedBox(height: 10),
            _ToggleTile(
              label: t.of('compare'),
              subtitle: t.of('original_label'),
              icon: compareEnabled
                  ? Icons.compare_rounded
                  : Icons.image_search_rounded,
              accent: InpaintingStudioTheme.violet,
              selected: compareEnabled,
              onTap: onToggleCompare,
            ),
            SizedBox(height: 10),
            _ToggleTile(
              label: t.of('editor_workspace_fit'),
              subtitle:
                  'x${currentZoom.toStringAsFixed(currentZoom < 2 ? 1 : 2)}',
              icon: Icons.center_focus_strong_rounded,
              accent: InpaintingStudioTheme.amber,
              selected: false,
              onTap: onResetViewport,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 5. Pinned CTA row — Reset + Run AI Magic (never scrolls off screen)
// ═════════════════════════════════════════════════════════════════════════════

class _PinnedCtaRow extends StatelessWidget {
  final bool hasMask;
  final String resetLabel;
  final String magicLabel;
  final VoidCallback onReset;
  final VoidCallback onMagic;

  const _PinnedCtaRow({
    required this.hasMask,
    required this.resetLabel,
    required this.magicLabel,
    required this.onReset,
    required this.onMagic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 18),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Row(
        children: [
          // Reset button (secondary)
          SizedBox(
            height: 52,
            child: _OutlineIconButton(
              icon: Icons.restart_alt_rounded,
              label: resetLabel,
              onTap: onReset,
            ),
          ),
          SizedBox(width: 10),

          // Run AI Magic (primary — takes remaining space)
          Expanded(
            child: _PrimaryMagicButton(
              hasMask: hasMask,
              label: magicLabel,
              onTap: onMagic,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryMagicButton extends StatelessWidget {
  final bool hasMask;
  final String label;
  final VoidCallback onTap;

  const _PrimaryMagicButton({
    required this.hasMask,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: hasMask ? 1.0 : 0.42,
      child: InkWell(
        onTap: hasMask ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            gradient: hasMask
                ? InpaintingStudioTheme.primaryGradient
                : null,
            color: hasMask ? null : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: hasMask
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: hasMask
                ? const [
                    BoxShadow(
                      color: Color(0x326DC6B0),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_fix_high_rounded,
                size: 19,
                color: hasMask ? Colors.black : InpaintingStudioTheme.textMuted,
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color:
                      hasMask ? Colors.black : InpaintingStudioTheme.textMuted,
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: InpaintingStudioTheme.textSecondary,
            ),
            SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: InpaintingStudioTheme.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Reusable sub-widgets
// ═════════════════════════════════════════════════════════════════════════════

class _PanelCard extends StatelessWidget {
  final Widget child;

  const _PanelCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: InpaintingStudioTheme.surfaceStrong.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback? onTap;

  const _PresetChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accent : InpaintingStudioTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 16, color: accent),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: InpaintingStudioTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: InpaintingStudioTheme.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            // Toggle track
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 26,
              padding: EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? accent.withValues(alpha: 0.26)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Align(
                alignment:
                    selected ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        selected ? accent : InpaintingStudioTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Compact horizontal toolbar (used by narrow layout in editor_page.dart)
// ═════════════════════════════════════════════════════════════════════════════

/// A compact horizontal pill-bar toolbar for narrow screens.
/// Sits directly below the canvas, above the pinned Run AI row.
/// Contains: Brush | Erase toggle · size slider · mask toggle · undo.
class InpaintingCompactToolbar extends StatelessWidget {
  final bool isEraser;
  final bool maskVisible;
  final bool canUndo;
  final double brushPx;
  final VoidCallback onBrushMode;
  final VoidCallback onEraserMode;
  final VoidCallback onToggleMaskVisibility;
  final VoidCallback onUndo;
  final ValueChanged<double> onBrushSizeChanged;

  const InpaintingCompactToolbar({
    super.key,
    required this.isEraser,
    required this.maskVisible,
    required this.canUndo,
    required this.brushPx,
    required this.onBrushMode,
    required this.onEraserMode,
    required this.onToggleMaskVisibility,
    required this.onUndo,
    required this.onBrushSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        isEraser ? InpaintingStudioTheme.rose : InpaintingStudioTheme.mint;

    return StudioFloatingPillBar(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Brush / Erase micro-toggle
          _MicroToggle(
            leftIcon: Icons.brush_rounded,
            rightIcon: Icons.auto_fix_off_rounded,
            leftActive: !isEraser,
            leftAccent: InpaintingStudioTheme.mint,
            rightAccent: InpaintingStudioTheme.rose,
            onLeft: onBrushMode,
            onRight: onEraserMode,
          ),
          SizedBox(width: 10),
          // Size slider
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                activeTrackColor: accent,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: brushPx.clamp(8.0, 120.0),
                min: 8,
                max: 120,
                onChanged: onBrushSizeChanged,
              ),
            ),
          ),
          SizedBox(width: 6),
          // Mask visibility
          _CompactIconBtn(
            icon: maskVisible
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            active: maskVisible,
            accent: InpaintingStudioTheme.cyan,
            onTap: onToggleMaskVisibility,
          ),
          SizedBox(width: 6),
          // Undo
          _CompactIconBtn(
            icon: Icons.undo_rounded,
            active: false,
            accent: InpaintingStudioTheme.textSecondary,
            onTap: canUndo ? onUndo : null,
          ),
        ],
      ),
    );
  }
}

class _MicroToggle extends StatelessWidget {
  final IconData leftIcon;
  final IconData rightIcon;
  final bool leftActive;
  final Color leftAccent;
  final Color rightAccent;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const _MicroToggle({
    required this.leftIcon,
    required this.rightIcon,
    required this.leftActive,
    required this.leftAccent,
    required this.rightAccent,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    final activeAccent = leftActive ? leftAccent : rightAccent;

    return Container(
      decoration: BoxDecoration(
        color: activeAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: activeAccent.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MicroBtn(
            icon: leftIcon,
            active: leftActive,
            accent: leftAccent,
            onTap: onLeft,
            leftRadius: true,
            rightRadius: false,
          ),
          Container(
            width: 1,
            height: 28,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          _MicroBtn(
            icon: rightIcon,
            active: !leftActive,
            accent: rightAccent,
            onTap: onRight,
            leftRadius: false,
            rightRadius: true,
          ),
        ],
      ),
    );
  }
}

class _MicroBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color accent;
  final VoidCallback onTap;
  final bool leftRadius;
  final bool rightRadius;

  const _MicroBtn({
    required this.icon,
    required this.active,
    required this.accent,
    required this.onTap,
    required this.leftRadius,
    required this.rightRadius,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.horizontal(
      left: leftRadius ? const Radius.circular(14) : Radius.zero,
      right: rightRadius ? const Radius.circular(14) : Radius.zero,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: br,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(borderRadius: br),
        child: Icon(
          icon,
          size: 16,
          color:
              active ? accent : InpaintingStudioTheme.textSecondary,
        ),
      ),
    );
  }
}

class _CompactIconBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color accent;
  final VoidCallback? onTap;

  const _CompactIconBtn({
    required this.icon,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: active
                ? accent.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: active ? accent : InpaintingStudioTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
