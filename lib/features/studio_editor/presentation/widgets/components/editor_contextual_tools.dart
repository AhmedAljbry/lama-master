import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lama/core/ui/AppTokens.dart';

enum EditorToolCategory {
  source('Source', Icons.photo_library_rounded),
  style('Style', Icons.auto_awesome_motion_rounded),
  refine('Refine', Icons.tune_rounded);

  final String label;
  final IconData icon;

  const EditorToolCategory(this.label, this.icon);
}

// ─────────────────────────────────────────────────────────────
// Premium Pill-Style Segmented Tab Bar with numbered step badges
// ─────────────────────────────────────────────────────────────
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

  static const List<String> _stepNumbers = ['①', '②', '③'];

  @override
  Widget build(BuildContext context) {
    final items = EditorToolCategory.values.toList();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTokens.bg,
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: AppTokens.border.withValues(alpha: 0.5)),
      ),
      child: isHorizontal
          ? Row(
              children: List.generate(items.length, (i) => Expanded(
                child: _PillTab(
                  category: items[i],
                  stepLabel: _stepNumbers[i],
                  isSelected: items[i] == selectedCategory,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onCategorySelected(items[i]);
                  },
                ),
              )),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(items.length, (i) => _PillTab(
                category: items[i],
                stepLabel: _stepNumbers[i],
                isSelected: items[i] == selectedCategory,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onCategorySelected(items[i]);
                },
              )),
            ),
    );
  }
}

class _PillTab extends StatelessWidget {
  final EditorToolCategory category;
  final String stepLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _PillTab({
    required this.category,
    required this.stepLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTokens.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.r12),
          border: isSelected
              ? Border.all(color: AppTokens.primary.withValues(alpha: 0.38), width: 1.0)
              : Border.all(color: Colors.transparent),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Step number badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTokens.primary.withValues(alpha: 0.22)
                        : AppTokens.card2.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(AppTokens.r8),
                  ),
                  child: Text(
                    stepLabel,
                    style: TextStyle(
                      color: isSelected ? AppTokens.primary : AppTokens.text2,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  category.icon,
                  color: isSelected ? AppTokens.primary : AppTokens.text2,
                  size: 15,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                category.label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? AppTokens.primary : AppTokens.text2,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  fontSize: isSelected ? 12 : 11,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 3),
            // Active indicator underline
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              height: 2,
              width: isSelected ? 22 : 0,
              decoration: BoxDecoration(
                color: AppTokens.primary,
                borderRadius: BorderRadius.circular(AppTokens.rFull),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Contextual Slider Overlay — premium large focused view
// ─────────────────────────────────────────────────────────────
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
    final normalizedValue = (value - min) / (max - min);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            AppTokens.gold.withValues(alpha: 0.14),
            AppTokens.card.withValues(alpha: 0.98),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTokens.r20),
        border: Border.all(color: AppTokens.gold.withValues(alpha: 0.32)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTokens.gold.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppTokens.gold.withValues(alpha: 0.16),
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
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$progress%',
                      style: AppTokens.caption.copyWith(
                        color: AppTokens.gold,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTokens.card2,
                    borderRadius: BorderRadius.circular(AppTokens.r8),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppTokens.text2,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          // Progress track bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.rFull),
            child: LinearProgressIndicator(
              value: normalizedValue.toDouble(),
              minHeight: 3,
              backgroundColor: AppTokens.border.withValues(alpha: 0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTokens.gold),
            ),
          ),
          const SizedBox(height: AppTokens.s8),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
              activeTrackColor: AppTokens.gold,
              inactiveTrackColor: AppTokens.border.withValues(alpha: 0.6),
              thumbColor: Colors.white,
              overlayColor: AppTokens.gold.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
              onChangeEnd: (_) => HapticFeedback.selectionClick(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
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
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Adjust Tool Button (icon grid in Refine tab)
// ─────────────────────────────────────────────────────────────
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
    final Color accent = isSelected
        ? AppTokens.gold
        : (hasModifications ? AppTokens.primary : AppTokens.text2);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: isEnabled ? 1.0 : 0.45,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: 0.14)
                : (hasModifications
                    ? accent.withValues(alpha: 0.08)
                    : AppTokens.card.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(AppTokens.r16),
            border: Border.all(
              color: isSelected
                  ? accent.withValues(alpha: 0.52)
                  : (hasModifications
                      ? accent.withValues(alpha: 0.25)
                      : AppTokens.border.withValues(alpha: 0.4)),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: accent, size: 22),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 10,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasModifications) ...<Widget>[
                const SizedBox(height: 4),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
