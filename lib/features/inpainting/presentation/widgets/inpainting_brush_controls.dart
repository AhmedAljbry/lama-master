import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/i18n/t.dart';
import 'inpainting_studio_chrome.dart';

enum InpaintingControlsLayout { sideDock, bottomDock }

class InpaintingBrushControls extends StatelessWidget {
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
        : const BorderRadius.vertical(top: Radius.circular(30));
    final accent =
        isEraser ? InpaintingStudioTheme.rose : InpaintingStudioTheme.mint;
    final compact = !_isSideDock;
    final showWorkflowCard = _isSideDock;

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
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 18,
              compact ? 14 : 18,
              compact ? 16 : 18,
              compact ? 28 : 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isSideDock) ...[
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                StudioSectionLabel(
                  title: t.of('tools'),
                  subtitle: hasMask
                      ? t.of('editor_tip_precision')
                      : t.of('editor_tip_run'),
                ),
                const SizedBox(height: 14),
                if (showWorkflowCard) ...[
                  _PanelCard(
                    title: t.of('quick_actions'),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _WorkflowChip(
                          icon: Icons.photo_rounded,
                          label: t.of('workflow_upload'),
                          accent: InpaintingStudioTheme.cyan,
                          active: true,
                        ),
                        _WorkflowChip(
                          icon: hasMask
                              ? Icons.check_circle_rounded
                              : Icons.gesture_rounded,
                          label: hasMask
                              ? t.of('editor_mask_ready')
                              : t.of('workflow_mask'),
                          accent: hasMask
                              ? InpaintingStudioTheme.mint
                              : InpaintingStudioTheme.amber,
                          active: true,
                        ),
                        _WorkflowChip(
                          icon: Icons.auto_fix_high_rounded,
                          label: t.of('workflow_render'),
                          accent: InpaintingStudioTheme.violet,
                          active: hasMask,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _PanelCard(
                  title: t.of('tools'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ModeButton(
                              label: t.of('brush'),
                              icon: Icons.brush_rounded,
                              active: !isEraser,
                              accent: InpaintingStudioTheme.mint,
                              onTap: onBrushMode,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ModeButton(
                              label: t.of('eraser'),
                              icon: Icons.auto_fix_off_rounded,
                              active: isEraser,
                              accent: InpaintingStudioTheme.rose,
                              onTap: onEraserMode,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniActionButton(
                              label: t.of('undo'),
                              icon: Icons.undo_rounded,
                              enabled: canUndo,
                              onTap: onUndo,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MiniActionButton(
                              label: t.of('redo'),
                              icon: Icons.redo_rounded,
                              enabled: canRedo,
                              onTap: onRedo,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MiniActionButton(
                              label: t.of('clear'),
                              icon: Icons.delete_outline_rounded,
                              enabled: hasMask,
                              onTap: onClear,
                              accent: InpaintingStudioTheme.danger,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _PanelCard(
                  title: t.of('brush_size'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _InfoPill(
                            icon: isEraser
                                ? Icons.auto_fix_off_rounded
                                : Icons.brush_rounded,
                            label: '${brushPx.round()} px',
                            accent: accent,
                          ),
                          const SizedBox(width: 10),
                          _InfoPill(
                            icon: Icons.gesture_rounded,
                            label: '$strokeCount',
                            accent: InpaintingStudioTheme.violet,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          activeTrackColor: accent,
                          inactiveTrackColor:
                              Colors.white.withValues(alpha: 0.12),
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                          overlayShape: SliderComponentShape.noOverlay,
                        ),
                        child: Slider(
                          value: brushPx.clamp(8.0, 120.0),
                          min: 8,
                          max: 120,
                          onChanged: onBrushSizeChanged,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [12.0, 20.0, 32.0, 48.0, 72.0, 96.0]
                            .map(
                              (preset) => _PresetChip(
                                label: '${preset.toInt()}',
                                selected: (brushPx - preset).abs() < 6,
                                onTap: () => onBrushSizeChanged(preset),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _PanelCard(
                  title: t.of('preview_tools'),
                  child: Column(
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
                        enabled: true,
                        selected: maskVisible,
                        onTap: onToggleMaskVisibility,
                      ),
                      const SizedBox(height: 10),
                      _ToggleTile(
                        label: t.of('compare'),
                        subtitle: t.of('original_label'),
                        icon: compareEnabled
                            ? Icons.compare_rounded
                            : Icons.image_search_rounded,
                        accent: InpaintingStudioTheme.violet,
                        enabled: true,
                        selected: compareEnabled,
                        onTap: onToggleCompare,
                      ),
                      const SizedBox(height: 10),
                      _ToggleTile(
                        label: t.of('editor_workspace_fit'),
                        subtitle:
                            'x${currentZoom.toStringAsFixed(currentZoom < 2 ? 1 : 2)}',
                        icon: Icons.center_focus_strong_rounded,
                        accent: InpaintingStudioTheme.amber,
                        enabled: true,
                        selected: false,
                        onTap: onResetViewport,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _PanelCard(
                  title: t.of('magic'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.zoom_in_map_rounded,
                              size: 18,
                              color: InpaintingStudioTheme.cyan,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                hasMask
                                    ? t.of('editor_tip_precision')
                                    : t.of('draw_first'),
                                style: const TextStyle(
                                  color: InpaintingStudioTheme.textPrimary,
                                  fontSize: 12.5,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: StudioSecondaryButton(
                              onPressed: onResetWorkspace,
                              icon: Icons.restart_alt_rounded,
                              label: t.of('reset'),
                              accent: InpaintingStudioTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StudioPrimaryButton(
                              onPressed: hasMask ? onMagic : null,
                              icon: Icons.auto_fix_high_rounded,
                              label: t.of('magic'),
                            ),
                          ),
                        ],
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

class _PanelCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _PanelCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: InpaintingStudioTheme.surfaceStrong.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: InpaintingStudioTheme.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _WorkflowChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool active;

  const _WorkflowChip({
    required this.icon,
    required this.label,
    required this.accent,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active
            ? accent.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active
              ? accent.withValues(alpha: 0.24)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: active ? accent : InpaintingStudioTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: active ? accent : InpaintingStudioTheme.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: active
              ? accent.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active
                ? accent.withValues(alpha: 0.26)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: active ? accent : InpaintingStudioTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active ? accent : InpaintingStudioTheme.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final Color accent;

  const _MiniActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.accent = InpaintingStudioTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: 11.5,
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

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 8),
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

class _ToggleTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool enabled;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.enabled,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: InpaintingStudioTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: InpaintingStudioTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 46,
                height: 28,
                padding: const EdgeInsets.all(3),
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
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? accent
                          : InpaintingStudioTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? InpaintingStudioTheme.mint.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? InpaintingStudioTheme.mint.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? InpaintingStudioTheme.mint
                : InpaintingStudioTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
