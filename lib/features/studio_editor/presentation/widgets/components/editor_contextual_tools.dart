import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lama/core/ui/AppTokens.dart';

enum EditorToolCategory {
  setup('Setup', Icons.settings_suggest_rounded),
  theme('Theme', Icons.style_rounded),
  adjust('Adjust', Icons.tune_rounded);

  final String label;
  final IconData icon;

  const EditorToolCategory(this.label, this.icon);
}

class StudioCategoryMenu extends StatelessWidget {
  final EditorToolCategory selectedCategory;
  final ValueChanged<EditorToolCategory> onCategorySelected;
  final bool isHorizontal;

  const StudioCategoryMenu({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.isHorizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    final items = EditorToolCategory.values
        .map(
          (category) => _CategoryMenuItem(
            category: category,
            isSelected: category == selectedCategory,
            isHorizontal: isHorizontal,
            onTap: () {
              HapticFeedback.selectionClick();
              onCategorySelected(category);
            },
          ),
        )
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        border: Border(
          top: isHorizontal
              ? BorderSide(color: AppTokens.border.withValues(alpha: 0.55))
              : BorderSide.none,
          right: !isHorizontal
              ? BorderSide(color: AppTokens.border.withValues(alpha: 0.55))
              : BorderSide.none,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isHorizontal ? AppTokens.s12 : AppTokens.s8,
        vertical: isHorizontal ? AppTokens.s10 : AppTokens.s24,
      ),
      child: isHorizontal
          ? Row(
              children: items
                  .map((item) => Expanded(child: item))
                  .toList(growable: false),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: items
                  .expand((item) => <Widget>[
                        item,
                        const SizedBox(height: AppTokens.s12),
                      ])
                  .toList()
                ..removeLast(),
            ),
    );
  }
}

class _CategoryMenuItem extends StatelessWidget {
  final EditorToolCategory category;
  final bool isSelected;
  final bool isHorizontal;
  final VoidCallback onTap;

  const _CategoryMenuItem({
    required this.category,
    required this.isSelected,
    required this.isHorizontal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isHorizontal ? AppTokens.s8 : AppTokens.s14,
          vertical: isHorizontal ? AppTokens.s12 : AppTokens.s14,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTokens.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.r14),
          border: Border.all(
            color: isSelected
                ? AppTokens.primary.withValues(alpha: 0.26)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              category.icon,
              color: isSelected ? AppTokens.primary : AppTokens.text2,
              size: isHorizontal ? 22 : 24,
            ),
            const SizedBox(height: 6),
            Text(
              category.label,
              textAlign: TextAlign.center,
              style: AppTokens.caption.copyWith(
                color: isSelected ? AppTokens.primary : AppTokens.text2,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContextualSliderOverlay extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final IconData icon;
  final ValueChanged<double> onChanged;
  final VoidCallback onClose;

  const ContextualSliderOverlay({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.icon,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ((value - min) / (max - min) * 100).clamp(0, 100).round();

    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppTokens.r20),
        border: Border.all(color: AppTokens.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(AppTokens.s8),
                decoration: BoxDecoration(
                  color: AppTokens.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                ),
                child: Icon(icon, color: AppTokens.gold, size: 18),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: AppTokens.labelBold.copyWith(
                        color: AppTokens.text,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$progress%',
                      style: AppTokens.caption.copyWith(
                        color: AppTokens.gold,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTokens.text2),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s10),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
              activeTrackColor: AppTokens.gold,
              inactiveTrackColor: AppTokens.bg,
              thumbColor: AppTokens.text,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
              onChangeEnd: (_) => HapticFeedback.selectionClick(),
            ),
          ),
          Row(
            children: <Widget>[
              Text(
                min.toStringAsFixed(1),
                style: AppTokens.caption.copyWith(color: AppTokens.text2),
              ),
              const Spacer(),
              Text(
                max.toStringAsFixed(1),
                style: AppTokens.caption.copyWith(color: AppTokens.text2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdjustToolButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool hasModifications;
  final bool isSelected;
  final VoidCallback? onTap;

  const AdjustToolButton({
    super.key,
    required this.label,
    required this.icon,
    this.hasModifications = false,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final accent = isSelected
        ? AppTokens.gold
        : (hasModifications ? AppTokens.primary : AppTokens.text2);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r16),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: isEnabled ? 1 : 0.5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.all(AppTokens.s12),
                decoration: BoxDecoration(
                  color: accent.withValues(
                    alpha: isSelected ? 0.16 : (hasModifications ? 0.14 : 0.06),
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withValues(
                      alpha: isSelected || hasModifications ? 1 : 0.35,
                    ),
                    width: isSelected ? 1.6 : 1.0,
                  ),
                ),
                child: FittedBox(
                    child: Icon(icon, color: accent, size: 24)),
              ),
            ),
            const SizedBox(height: AppTokens.s6),
            Text(
              label,
              style: AppTokens.caption.copyWith(
                color: accent,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 11, // Slightly smaller text on tight constraints
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
