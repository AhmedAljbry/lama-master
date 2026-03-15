import 'package:flutter/material.dart';

import 'inpainting_studio_chrome.dart';

class InpaintingEditorToolbar extends StatelessWidget {
  final String title;
  final String subtitle;
  final String statusLabel;
  final bool hasMask;
  final bool compareEnabled;
  final bool canUndo;
  final bool canRedo;
  final bool compact;
  final VoidCallback onBack;
  final VoidCallback onHelp;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final VoidCallback onToggleCompare;
  final String undoLabel;
  final String redoLabel;
  final String clearLabel;
  final String compareLabel;
  final String compareActiveLabel;

  const InpaintingEditorToolbar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.hasMask,
    required this.compareEnabled,
    required this.canUndo,
    required this.canRedo,
    required this.compact,
    required this.onBack,
    required this.onHelp,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onToggleCompare,
    required this.undoLabel,
    required this.redoLabel,
    required this.clearLabel,
    required this.compareLabel,
    required this.compareActiveLabel,
  });

  @override
  Widget build(BuildContext context) {
    final statusAccent = compareEnabled
        ? InpaintingStudioTheme.cyan
        : hasMask
            ? InpaintingStudioTheme.mint
            : InpaintingStudioTheme.amber;
    final shouldShowStatus = !compact || compareEnabled || hasMask;

    return StudioGlassPanel(
      radius: 30,
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 16,
        compact ? 12 : 14,
        compact ? 12 : 16,
        compact ? 12 : 14,
      ),
      fillColor: InpaintingStudioTheme.surfaceSoft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ToolbarIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack,
              ),
              SizedBox(width: compact ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: InpaintingStudioTheme.textPrimary,
                        fontSize: compact ? 17 : 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: InpaintingStudioTheme.textSecondary,
                        fontSize: compact ? 12 : 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (shouldShowStatus) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: StudioPill(
                    icon: compareEnabled
                        ? Icons.compare_rounded
                        : hasMask
                            ? Icons.check_circle_rounded
                            : Icons.gesture_rounded,
                    label: compareEnabled ? compareActiveLabel : statusLabel,
                    accent: statusAccent,
                    filled: compareEnabled || hasMask,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              _ToolbarIconButton(
                icon: Icons.help_outline_rounded,
                onTap: onHelp,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ToolbarActionChip(
                icon: Icons.undo_rounded,
                label: undoLabel,
                onTap: canUndo ? onUndo : null,
                accent: InpaintingStudioTheme.textPrimary,
              ),
              _ToolbarActionChip(
                icon: Icons.redo_rounded,
                label: redoLabel,
                onTap: canRedo ? onRedo : null,
                accent: InpaintingStudioTheme.textPrimary,
              ),
              _ToolbarActionChip(
                icon: Icons.delete_outline_rounded,
                label: clearLabel,
                onTap: hasMask ? onClear : null,
                accent: InpaintingStudioTheme.danger,
              ),
              _ToolbarActionChip(
                icon: compareEnabled
                    ? Icons.visibility_rounded
                    : Icons.compare_rounded,
                label: compareLabel,
                onTap: onToggleCompare,
                accent: InpaintingStudioTheme.cyan,
                selected: compareEnabled,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ToolbarIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(
          icon,
          size: 20,
          color: InpaintingStudioTheme.textPrimary,
        ),
      ),
    );
  }
}

class _ToolbarActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color accent;
  final bool selected;

  const _ToolbarActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.accent,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final background = selected
        ? accent.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.05);
    final borderColor = selected
        ? accent.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.08);

    return Opacity(
      opacity: enabled ? 1 : 0.38,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? accent : InpaintingStudioTheme.textPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? accent : InpaintingStudioTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
