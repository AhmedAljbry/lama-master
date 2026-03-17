import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lama/core/i18n/t.dart';
import 'package:lama/features/filter_studio/presentation/bloc/filter_studio_state.dart';
import 'package:lama/core/ui/AppTokens.dart';
import 'package:lama/core/ui/app_theme.dart';
import 'package:lama/presentation/widgets/artistic_canvas.dart';

enum FilterStudioLayoutMode { compact, medium, expanded }

class FilterStudioInspectorTab {
  final String label;
  final IconData icon;
  final Widget child;

  const FilterStudioInspectorTab({
    required this.label,
    required this.icon,
    required this.child,
  });
}

class FilterStudioShellBackdrop extends StatelessWidget {
  const FilterStudioShellBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTokens.bg,
      ),
      child: SizedBox.expand(),
    );
  }
}

class FilterStudioAmbientGlow extends StatelessWidget {
  final Color color;
  final double size;

  const FilterStudioAmbientGlow({
    super.key,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.18),
              blurRadius: size * 0.28,
              spreadRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}

class FilterStudioGlassPanel extends StatelessWidget {
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry padding;
  final Widget child;
  final Color? color;

  const FilterStudioGlassPanel({
    super.key,
    required this.borderRadius,
    required this.padding,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? AppTokens.surface.withOpacity(0.75),
            borderRadius: borderRadius,
            border: Border.all(color: AppTokens.border.withOpacity(0.4)),
            boxShadow: AppTokens.cardShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

class FilterStudioStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const FilterStudioStatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(AppTokens.rFull),
        border: Border.all(color: color.withOpacity(0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: AppTokens.s6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class FilterStudioHeader extends StatelessWidget {
  final T t;
  final FilterStudioLayoutMode mode;
  final Lang currentLang;
  final Color accent;
  final bool hasImage;
  final String? currentLookLabel;
  final String aiStatusLabel;
  final String aiButtonLabel;
  final bool isAiBusy;
  final bool hasAiInsight;
  final VoidCallback onBack;
  final VoidCallback onPick;
  final VoidCallback onToggleLanguage;
  final VoidCallback? onAnalyze;
  final VoidCallback? onReview;

  const FilterStudioHeader({
    super.key,
    required this.t,
    required this.mode,
    required this.currentLang,
    required this.accent,
    required this.hasImage,
    required this.currentLookLabel,
    required this.aiStatusLabel,
    required this.aiButtonLabel,
    required this.isAiBusy,
    required this.hasAiInsight,
    required this.onBack,
    required this.onPick,
    required this.onToggleLanguage,
    required this.onAnalyze,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = mode == FilterStudioLayoutMode.compact;
    final languageLabel = currentLang == Lang.ar ? 'EN' : 'AR';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          FilterStudioHeaderIconAction(
            icon: hasImage
                ? Icons.arrow_back_ios_new_rounded
                : Icons.close_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.of('pro_studio').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                if (!isCompact && hasImage)
                  Text(
                    t.of('studio_ready'),
                    style: TextStyle(
                      color: AppTokens.text2.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilterStudioHeaderIconAction(
                icon: Icons.language_rounded,
                onTap: onToggleLanguage,
              ),
              const SizedBox(width: AppTokens.s8),
              FilterStudioHeaderIconAction(
                icon: Icons.add_photo_alternate_rounded,
                onTap: onPick,
                tint: AppTokens.warning.withOpacity(0.9),
              ),
              const SizedBox(width: AppTokens.s8),
              FilterStudioHeaderIconAction(
                icon: Icons.auto_awesome_rounded,
                onTap: onAnalyze,
                tint: hasAiInsight ? AppTokens.info : AppTokens.text2,
                isLoading: isAiBusy,
              ),
              if (onReview != null) ...[
                const SizedBox(width: AppTokens.s12),
                FilterStudioHeaderPrimaryAction(
                  icon: Icons.check_rounded,
                  label: isCompact ? null : t.of('save'),
                  onTap: onReview,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class FilterStudioHeaderIconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color tint;
  final bool isLoading;

  const FilterStudioHeaderIconAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.tint = AppTokens.text2,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : 0.4,
          child: Ink(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppTokens.r12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(tint),
                      ),
                    )
                  : Icon(icon, color: tint, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}

class FilterStudioHeaderPillAction extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final Color tint;
  final bool loading;

  const FilterStudioHeaderPillAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint = AppTokens.text2,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(AppTokens.rFull),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : 0.45,
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: label == null ? AppTokens.s12 : AppTokens.s14,
              vertical: AppTokens.s10,
            ),
            decoration: BoxDecoration(
              color: tint.withOpacity(0.11),
              borderRadius: BorderRadius.circular(AppTokens.rFull),
              border: Border.all(color: tint.withOpacity(0.24)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tint,
                    ),
                  )
                else
                  Icon(icon, size: 16, color: tint),
                if (label != null) ...[
                  SizedBox(width: AppTokens.s6),
                  Text(
                    label!,
                    style: TextStyle(
                      color: tint,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FilterStudioHeaderPrimaryAction extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;

  const FilterStudioHeaderPrimaryAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(AppTokens.rFull),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : 0.45,
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: label == null ? AppTokens.s12 : AppTokens.s18,
              vertical: AppTokens.s10,
            ),
            decoration: BoxDecoration(
              gradient: AppTokens.primaryGradient,
              borderRadius: BorderRadius.circular(AppTokens.rFull),
              boxShadow: AppTokens.primaryGlow(0.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.black),
                if (label != null) ...[
                  const SizedBox(width: AppTokens.s8),
                  Text(
                    label!.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FilterStudioPreviewPane extends StatelessWidget {
  final T t;
  final FilterStudioLayoutMode mode;
  final Color accent;
  final FilterStudioState state;
  final GlobalKey repaintKey;
  final String currentLookLabel;
  final String aiStatusLabel;
  final int totalLooks;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onCompareStart;
  final VoidCallback onCompareEnd;
  final VoidCallback onAiAuto;
  final VoidCallback onCinematic;
  final VoidCallback onRandom;
  final VoidCallback onDepthBlur;

  const FilterStudioPreviewPane({
    super.key,
    required this.t,
    required this.mode,
    required this.accent,
    required this.state,
    required this.repaintKey,
    required this.currentLookLabel,
    required this.aiStatusLabel,
    required this.totalLooks,
    required this.onUndo,
    required this.onRedo,
    required this.onCompareStart,
    required this.onCompareEnd,
    required this.onAiAuto,
    required this.onCinematic,
    required this.onRandom,
    required this.onDepthBlur,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = mode == FilterStudioLayoutMode.compact;

    return Column(
      children: [
        Expanded(
          child: FilterStudioCanvasStage(
            t: t,
            mode: mode,
            accent: accent,
            state: state,
            repaintKey: repaintKey,
            currentLookLabel: currentLookLabel,
            aiStatusLabel: aiStatusLabel,
            onCompareStart: onCompareStart,
            onCompareEnd: onCompareEnd,
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 0),
          child: FilterStudioQuickActionsBar(
            t: t,
            canUndo: state.canUndoAdjust,
            canRedo: state.canRedoAdjust,
            onUndo: onUndo,
            onRedo: onRedo,
            onCompareStart: onCompareStart,
            onCompareEnd: onCompareEnd,
            onAiAuto: onAiAuto,
            onCinematic: onCinematic,
            onRandom: onRandom,
            onDepthBlur: onDepthBlur,
          ),
        ),
        const SizedBox(height: AppTokens.s8),
      ],
    );
  }
}

class FilterStudioQuickActionsBar extends StatelessWidget {
  final T t;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onCompareStart;
  final VoidCallback onCompareEnd;
  final VoidCallback onAiAuto;
  final VoidCallback onCinematic;
  final VoidCallback onRandom;
  final VoidCallback onDepthBlur;

  const FilterStudioQuickActionsBar({
    super.key,
    required this.t,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onCompareStart,
    required this.onCompareEnd,
    required this.onAiAuto,
    required this.onCinematic,
    required this.onRandom,
    required this.onDepthBlur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTokens.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTokens.r20),
        border: Border.all(color: AppTokens.border.withOpacity(0.3)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // History Group
              FilterStudioQuickActionButton(
                icon: Icons.undo_rounded,
                label: null,
                color: AppTokens.text2,
                onTap: canUndo ? onUndo : null,
              ),
              const SizedBox(width: AppTokens.s4),
              FilterStudioQuickActionButton(
                icon: Icons.redo_rounded,
                label: null,
                color: AppTokens.text2,
                onTap: canRedo ? onRedo : null,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: VerticalDivider(color: AppTokens.border, width: 1),
              ),
              // Creative Tools Group
              FilterStudioQuickActionButton(
                icon: Icons.auto_awesome_rounded,
                label: t.of('ai_auto_fix'),
                color: AppTokens.info,
                onTap: onAiAuto,
              ),
              const SizedBox(width: AppTokens.s8),
              FilterStudioQuickActionButton(
                icon: Icons.movie_creation_outlined,
                label: t.of('cinematic_look'),
                color: AppTokens.warning.withOpacity(0.9),
                onTap: onCinematic,
              ),
              const SizedBox(width: AppTokens.s8),
              FilterStudioQuickActionButton(
                icon: Icons.blur_on_rounded,
                label: t.of('depth_blur'),
                color: AppTokens.accent,
                onTap: onDepthBlur,
              ),
              const SizedBox(width: AppTokens.s8),
              FilterStudioQuickActionButton(
                icon: Icons.shuffle_rounded,
                label: t.of('random_mix'),
                color: AppTokens.primary,
                onTap: onRandom,
              ),
              const SizedBox(width: AppTokens.s8),
              FilterStudioQuickHoldActionButton(
                icon: Icons.compare_arrows_rounded,
                label: t.of('compare_hold'),
                color: AppTokens.text,
                onStart: onCompareStart,
                onEnd: onCompareEnd,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterStudioQuickActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback? onTap;

  const FilterStudioQuickActionButton({
    super.key,
    required this.icon,
    this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(AppTokens.r14),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : 0.35,
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: label == null ? AppTokens.s10 : AppTokens.s12,
              vertical: AppTokens.s10,
            ),
            decoration: BoxDecoration(
              color: enabled ? color.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTokens.r14),
              border: Border.all(
                color: enabled ? color.withOpacity(0.2) : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                if (label != null) ...[
                  const SizedBox(width: AppTokens.s6),
                  Text(
                    label!,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FilterStudioQuickHoldActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  const FilterStudioQuickHoldActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onStart,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        onStart();
      },
      onTapUp: (_) => onEnd(),
      onTapCancel: onEnd,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTokens.s12,
          vertical: AppTokens.s10,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTokens.r16),
          border: Border.all(color: color.withOpacity(0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            SizedBox(width: AppTokens.s6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterStudioCanvasStage extends StatelessWidget {
  final T t;
  final FilterStudioLayoutMode mode;
  final Color accent;
  final FilterStudioState state;
  final GlobalKey repaintKey;
  final String currentLookLabel;
  final String aiStatusLabel;
  final VoidCallback onCompareStart;
  final VoidCallback onCompareEnd;

  const FilterStudioCanvasStage({
    super.key,
    required this.t,
    required this.mode,
    required this.accent,
    required this.state,
    required this.repaintKey,
    required this.currentLookLabel,
    required this.aiStatusLabel,
    required this.onCompareStart,
    required this.onCompareEnd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasWidth = constraints.maxWidth;
        final canvasHeight = constraints.maxHeight;

        return Center(
          child: SizedBox(
            width: canvasWidth,
            height: canvasHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTokens.r24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: GestureDetector(
                        onLongPressStart: (_) => onCompareStart(),
                        onLongPressEnd: (_) => onCompareEnd(),
                        child: RepaintBoundary(
                          key: repaintKey,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppTokens.r20),
                            child: ArtisticCanvas(
                              imageFile: state.imageFile!,
                              personMask: state.personMask,
                              params: state.params,
                              showOriginal: state.isComparingHold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (state.isComparingHold)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: FilterStudioStatusChip(
                      label: t.of('original_label').toUpperCase(),
                      color: AppTokens.warning,
                      icon: Icons.compare_arrows_rounded,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FilterStudioInspector extends StatelessWidget {
  final T t;
  final FilterStudioLayoutMode mode;
  final Color accent;
  final String currentLookLabel;
  final String aiStatusLabel;
  final bool hasPersonMask;
  final int selectedIndex;
  final List<FilterStudioInspectorTab> tabs;
  final ValueChanged<int> onTabChanged;

  const FilterStudioInspector({
    super.key,
    required this.t,
    required this.mode,
    required this.accent,
    required this.currentLookLabel,
    required this.aiStatusLabel,
    required this.hasPersonMask,
    required this.selectedIndex,
    required this.tabs,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final radius = mode == FilterStudioLayoutMode.compact
        ? const BorderRadius.vertical(top: Radius.circular(AppTokens.r32))
        : BorderRadius.circular(AppTokens.r32);

    return FilterStudioGlassPanel(
      borderRadius: radius,
      padding: EdgeInsets.zero,
      color: AppTokens.surface.withOpacity(0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mode == FilterStudioLayoutMode.compact) ...[
            const SizedBox(height: AppTokens.s12),
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTokens.rFull),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.s8),
          ],
          const SizedBox(height: AppTokens.s12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilterStudioInspectorTabBar(
              tabs: tabs,
              selectedIndex: selectedIndex,
              onChanged: onTabChanged,
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),

              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.02),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(selectedIndex),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: tabs[selectedIndex].child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FilterStudioInspectorTabBar extends StatelessWidget {
  final List<FilterStudioInspectorTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const FilterStudioInspectorTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTokens.r18),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final isSelected = index == selectedIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTokens.primaryGradient : null,
                  borderRadius: BorderRadius.circular(AppTokens.r14),
                  boxShadow: isSelected ? AppTokens.primaryGlow(0.2) : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 16,
                      color: isSelected ? Colors.black : AppTokens.text2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      style: TextStyle(
                        color: isSelected ? Colors.black : AppTokens.text2,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class FilterStudioEmptyState extends StatefulWidget {
  final T t;
  final FilterStudioLayoutMode mode;
  final Color accent;
  final int totalLooks;
  final VoidCallback onPick;

  const FilterStudioEmptyState({
    super.key,
    required this.t,
    required this.mode,
    required this.accent,
    required this.totalLooks,
    required this.onPick,
  });

  @override
  State<FilterStudioEmptyState> createState() => _FilterStudioEmptyStateState();
}

class _FilterStudioEmptyStateState extends State<FilterStudioEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut)
        .drive(Tween<double>(begin: 0, end: 1));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack)
        .drive(Tween<double>(begin: 0.9, end: 1));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fade,
          child: Transform.scale(scale: _scale.value, child: child),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isStacked = constraints.maxWidth < 900;

          final heroCard = FilterStudioGlassPanel(
            borderRadius: BorderRadius.circular(AppTokens.r32),
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: AppTokens.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_rounded,
                    size: 36,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: AppTokens.s24),
                Text(
                  widget.t.of('tap_to_open'),
                   style: const TextStyle(
                    color: AppTokens.text,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
                Text(
                  widget.t.of('ai_no_image_desc'),
                  style: TextStyle(
                    color: AppTokens.text2.withOpacity(0.8),
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppTokens.s28),
                FilterStudioHeaderPrimaryAction(
                  icon: Icons.photo_library_rounded,
                  label: widget.t.of('pick_gallery'),
                  onTap: widget.onPick,
                ),
              ],
            ),
          );

          final features = Column(
            children: [
              FilterStudioEmptyFeatureCard(
                color: AppTokens.info,
                icon: Icons.auto_awesome_rounded,
                title: widget.t.of('ai_auto_fix'),
                description: widget.t.of('ai_manual_desc'),
              ),
              const SizedBox(height: AppTokens.s12),
              FilterStudioEmptyFeatureCard(
                color: AppTokens.warning,
                icon: Icons.collections_rounded,
                title: widget.t.of('featured_drops'),
                description: widget.t.of('featured_drops_desc'),
              ),
              const SizedBox(height: AppTokens.s12),
              FilterStudioEmptyFeatureCard(
                color: AppTokens.accent,
                icon: Icons.style_rounded,
                title: widget.t.of('signature_library'),
                description: widget.t.of('signature_library_desc'),
              ),
            ],
          );

          if (isStacked) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    heroCard,
                    const SizedBox(height: AppTokens.s16),
                    features,
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 7, child: heroCard),
                const SizedBox(width: AppTokens.s20),
                Expanded(flex: 5, child: SingleChildScrollView(child: features)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FilterStudioEmptyFeatureCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String description;

  const FilterStudioEmptyFeatureCard({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return FilterStudioGlassPanel(
      borderRadius: BorderRadius.circular(AppTokens.r24),
      padding: EdgeInsets.all(AppTokens.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(AppTokens.r16),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTokens.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: AppTokens.s6),
                Text(
                  description,
                  style: TextStyle(
                    color: AppTokens.text2,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
