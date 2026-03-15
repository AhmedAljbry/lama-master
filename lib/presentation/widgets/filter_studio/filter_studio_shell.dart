import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lama/core/i18n/t.dart';
import 'package:lama/features/filter_studio/presentation/bloc/filter_studio_state.dart';
import 'package:lama/presentation/pages/PT.dart';
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF070D13),
            Color(0xFF09121A),
            Color(0xFF0C1822),
          ],
          stops: [0.0, 0.48, 1.0],
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -96,
            left: -72,
            child: FilterStudioAmbientGlow(color: PT.mint, size: 260),
          ),
          Positioned(
            top: 180,
            right: -84,
            child: FilterStudioAmbientGlow(color: PT.cyan, size: 320),
          ),
          Positioned(
            bottom: -110,
            left: 110,
            child: FilterStudioAmbientGlow(color: PT.purple, size: 280),
          ),
        ],
      ),
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
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? PT.surface.withOpacity(0.8),
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: PT.elevation,
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
      padding: const EdgeInsets.symmetric(
        horizontal: PT.s12,
        vertical: PT.s8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(PT.rFull),
        border: Border.all(color: color.withOpacity(0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: PT.s6),
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
    final showLabels = mode != FilterStudioLayoutMode.compact;
    final languageLabel = currentLang == Lang.ar ? 'EN' : 'AR';

    return FilterStudioGlassPanel(
      borderRadius: BorderRadius.circular(PT.r32),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 760;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilterStudioHeaderIconAction(
                    icon: hasImage
                        ? Icons.arrow_back_ios_new_rounded
                        : Icons.close_rounded,
                    onTap: onBack,
                  ),
                  const SizedBox(width: PT.s12),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: PT.gradPurple,
                            borderRadius: BorderRadius.circular(PT.r16),
                            boxShadow: PT.glow(PT.purple, blur: 18),
                          ),
                          child: const Icon(
                            Icons.movie_filter_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: PT.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    PT.gradMint.createShader(bounds),
                                child: Text(
                                  t.of('pro_studio'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasImage
                                    ? t.of('studio_ready')
                                    : t.of('pick_hint'),
                                style: const TextStyle(
                                  color: PT.t2,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: PT.s10),
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterStudioHeaderPillAction(
                            icon: Icons.language_rounded,
                            label: languageLabel,
                            onTap: onToggleLanguage,
                          ),
                          const SizedBox(width: PT.s8),
                          FilterStudioHeaderPillAction(
                            icon: Icons.add_photo_alternate_rounded,
                            label: showLabels ? t.of('pick_gallery') : null,
                            onTap: onPick,
                            tint: PT.gold,
                          ),
                          const SizedBox(width: PT.s8),
                          FilterStudioHeaderPillAction(
                            icon: Icons.auto_awesome_rounded,
                            label: showLabels ? aiButtonLabel : null,
                            onTap: onAnalyze,
                            tint: hasAiInsight ? PT.cyan : PT.t2,
                            loading: isAiBusy,
                          ),
                          if (onReview != null) ...[
                            const SizedBox(width: PT.s8),
                            FilterStudioHeaderPrimaryAction(
                              icon: Icons.download_rounded,
                              label: showLabels || !isCompact
                                  ? t.of('save')
                                  : null,
                              onTap: onReview,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (hasImage && currentLookLabel != null) ...[
                const SizedBox(height: PT.s12),
                Wrap(
                  spacing: PT.s8,
                  runSpacing: PT.s8,
                  children: [
                    FilterStudioStatusChip(
                      label: currentLookLabel!,
                      color: accent,
                      icon: Icons.tune_rounded,
                    ),
                    FilterStudioStatusChip(
                      label: aiStatusLabel,
                      color: hasAiInsight ? PT.cyan : PT.gold,
                      icon: Icons.auto_awesome_rounded,
                    ),
                    FilterStudioStatusChip(
                      label: t.of('live_preview'),
                      color: PT.mint,
                      icon: Icons.remove_red_eye_outlined,
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class FilterStudioHeaderIconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const FilterStudioHeaderIconAction({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(PT.r16),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(PT.r16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Icon(icon, color: PT.t2, size: 16),
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
    this.tint = PT.t2,
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
        borderRadius: BorderRadius.circular(PT.rFull),
        child: AnimatedOpacity(
          duration: PT.fast,
          opacity: enabled ? 1 : 0.45,
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: label == null ? PT.s12 : PT.s14,
              vertical: PT.s10,
            ),
            decoration: BoxDecoration(
              color: tint.withOpacity(0.11),
              borderRadius: BorderRadius.circular(PT.rFull),
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
                  const SizedBox(width: PT.s6),
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
        borderRadius: BorderRadius.circular(PT.rFull),
        child: AnimatedOpacity(
          duration: PT.fast,
          opacity: enabled ? 1 : 0.45,
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: label == null ? PT.s12 : PT.s16,
              vertical: PT.s10,
            ),
            decoration: BoxDecoration(
              gradient: PT.gradMint,
              borderRadius: BorderRadius.circular(PT.rFull),
              boxShadow: PT.glow(PT.mint, blur: 18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.black),
                if (label != null) ...[
                  const SizedBox(width: PT.s6),
                  Text(
                    label!,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
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
    return FilterStudioGlassPanel(
      borderRadius: BorderRadius.circular(PT.r32),
      padding: EdgeInsets.all(mode == FilterStudioLayoutMode.compact ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(PT.s16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withOpacity(0.18),
                  PT.card2.withOpacity(0.96),
                  PT.surface.withOpacity(0.94),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(PT.r24),
              border: Border.all(color: accent.withOpacity(0.26)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.of('studio_control'),
                  style: const TextStyle(
                    color: PT.t3,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: PT.s6),
                Text(
                  currentLookLabel,
                  style: const TextStyle(
                    color: PT.t1,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: PT.s6),
                Text(
                  aiStatusLabel,
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: PT.s12),
                Wrap(
                  spacing: PT.s8,
                  runSpacing: PT.s8,
                  children: [
                    FilterStudioStatusChip(
                      label: '$totalLooks ${t.of('looks_label')}',
                      color: PT.mint,
                      icon: Icons.style_rounded,
                    ),
                    FilterStudioStatusChip(
                      label: state.personMask != null
                          ? t.of('editor_mask_ready')
                          : t.of('editor_mask_pending'),
                      color: state.personMask != null ? PT.cyan : PT.t2,
                      icon: Icons.person_pin_circle_outlined,
                    ),
                    FilterStudioStatusChip(
                      label: t.of('live_preview'),
                      color: PT.gold,
                      icon: Icons.flash_on_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: PT.s14),
          FilterStudioQuickActionsBar(
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
          const SizedBox(height: PT.s14),
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
        ],
      ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterStudioQuickActionButton(
            icon: Icons.auto_awesome_rounded,
            label: t.of('ai_auto_fix'),
            color: PT.cyan,
            onTap: onAiAuto,
          ),
          const SizedBox(width: PT.s8),
          FilterStudioQuickHoldActionButton(
            icon: Icons.compare_arrows_rounded,
            label: t.of('compare_hold'),
            color: PT.mint,
            onStart: onCompareStart,
            onEnd: onCompareEnd,
          ),
          const SizedBox(width: PT.s8),
          FilterStudioQuickActionButton(
            icon: Icons.movie_creation_outlined,
            label: t.of('cinematic_look'),
            color: PT.gold,
            onTap: onCinematic,
          ),
          const SizedBox(width: PT.s8),
          FilterStudioQuickActionButton(
            icon: Icons.blur_on_rounded,
            label: t.of('depth_blur'),
            color: PT.purple,
            onTap: onDepthBlur,
          ),
          const SizedBox(width: PT.s8),
          FilterStudioQuickActionButton(
            icon: Icons.shuffle_rounded,
            label: t.of('random_mix'),
            color: PT.mint,
            onTap: onRandom,
          ),
          const SizedBox(width: PT.s8),
          FilterStudioQuickActionButton(
            icon: Icons.undo_rounded,
            label: t.of('undo'),
            color: canUndo ? PT.mint : PT.t3,
            onTap: canUndo ? onUndo : null,
          ),
          const SizedBox(width: PT.s8),
          FilterStudioQuickActionButton(
            icon: Icons.redo_rounded,
            label: t.of('redo'),
            color: canRedo ? PT.mint : PT.t3,
            onTap: canRedo ? onRedo : null,
          ),
        ],
      ),
    );
  }
}

class FilterStudioQuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const FilterStudioQuickActionButton({
    super.key,
    required this.icon,
    required this.label,
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
        borderRadius: BorderRadius.circular(PT.r16),
        child: AnimatedOpacity(
          duration: PT.fast,
          opacity: enabled ? 1 : 0.45,
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: PT.s12,
              vertical: PT.s10,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(PT.r16),
              border: Border.all(color: color.withOpacity(0.24)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: PT.s6),
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
        padding: const EdgeInsets.symmetric(
          horizontal: PT.s12,
          vertical: PT.s10,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(PT.r16),
          border: Border.all(color: color.withOpacity(0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: PT.s6),
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
        final maxCanvasWidth = mode == FilterStudioLayoutMode.expanded
            ? 860.0
            : mode == FilterStudioLayoutMode.medium
                ? 720.0
                : constraints.maxWidth;
        final canvasWidth = math.min(
          maxCanvasWidth,
          math.min(constraints.maxWidth, constraints.maxHeight * 0.98),
        );
        final canvasHeight =
            math.min(constraints.maxHeight, canvasWidth * 1.18);

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
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.08),
                          PT.card2.withOpacity(0.96),
                          PT.surface.withOpacity(0.98),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(PT.r24),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.14),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: GestureDetector(
                        onLongPressStart: (_) => onCompareStart(),
                        onLongPressEnd: (_) => onCompareEnd(),
                        child: RepaintBoundary(
                          key: repaintKey,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(PT.r24),
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
                Positioned(
                  top: 16,
                  left: 16,
                  child: FilterStudioStatusChip(
                    label: currentLookLabel,
                    color: accent,
                    icon: Icons.photo_filter_rounded,
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: FilterStudioStatusChip(
                    label: state.isComparingHold
                        ? t.of('original_label')
                        : t.of('compare_hold'),
                    color: state.isComparingHold ? PT.gold : PT.t2,
                    icon: Icons.compare_arrows_rounded,
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Wrap(
                    spacing: PT.s8,
                    runSpacing: PT.s8,
                    children: [
                      FilterStudioStatusChip(
                        label: aiStatusLabel,
                        color: accent,
                        icon: Icons.auto_awesome_rounded,
                      ),
                      FilterStudioStatusChip(
                        label: t.of('live_preview'),
                        color: PT.mint,
                        icon: Icons.waves_rounded,
                      ),
                    ],
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
        ? const BorderRadius.vertical(top: Radius.circular(PT.r32))
        : BorderRadius.circular(PT.r32);

    return FilterStudioGlassPanel(
      borderRadius: radius,
      padding: EdgeInsets.zero,
      color: PT.surface.withOpacity(0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mode == FilterStudioLayoutMode.compact) ...[
            const SizedBox(height: PT.s12),
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(PT.rFull),
                ),
              ),
            ),
            const SizedBox(height: PT.s8),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(PT.s16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withOpacity(0.18),
                    PT.card2.withOpacity(0.92),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(PT.r24),
                border: Border.all(color: accent.withOpacity(0.24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentLookLabel,
                    style: const TextStyle(
                      color: PT.t1,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: PT.s6),
                  Text(
                    aiStatusLabel,
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: PT.s12),
                  Wrap(
                    spacing: PT.s8,
                    runSpacing: PT.s8,
                    children: [
                      FilterStudioStatusChip(
                        label: t.of('active_look'),
                        color: accent,
                        icon: Icons.tune_rounded,
                      ),
                      FilterStudioStatusChip(
                        label: hasPersonMask
                            ? t.of('editor_mask_ready')
                            : t.of('editor_mask_pending'),
                        color: hasPersonMask ? PT.cyan : PT.t2,
                        icon: Icons.face_retouching_natural_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: PT.s12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilterStudioInspectorTabBar(
              tabs: tabs,
              selectedIndex: selectedIndex,
              onChanged: onTabChanged,
            ),
          ),
          const SizedBox(height: PT.s12),
          Expanded(
            child: AnimatedSwitcher(
              duration: PT.medium,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.03),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(selectedIndex),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final isSelected = index == selectedIndex;

          return Padding(
            padding: EdgeInsets.only(
              right: index == tabs.length - 1 ? 0 : PT.s8,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(index);
                },
                borderRadius: BorderRadius.circular(PT.r16),
                child: AnimatedContainer(
                  duration: PT.fast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: PT.s12,
                    vertical: PT.s10,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? PT.gradMint : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(PT.r16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 15,
                        color: isSelected ? Colors.black : PT.t2,
                      ),
                      const SizedBox(width: PT.s6),
                      Text(
                        tab.label,
                        style: TextStyle(
                          color: isSelected ? Colors.black : PT.t2,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
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
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut)
        .drive(Tween<double>(begin: 0, end: 1));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack)
        .drive(Tween<double>(begin: 0.92, end: 1));
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
          final stacked = constraints.maxWidth < 960;
          final hero = FilterStudioGlassPanel(
            borderRadius: BorderRadius.circular(PT.r32),
            padding: const EdgeInsets.all(PT.s24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    gradient: PT.gradMint,
                    shape: BoxShape.circle,
                    boxShadow: PT.glow(PT.mint, blur: 28),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_rounded,
                    size: 34,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: PT.s20),
                Text(
                  widget.t.of('tap_to_open'),
                  style: const TextStyle(
                    color: PT.t1,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: PT.s12),
                Text(
                  widget.t.of('ai_no_image_desc'),
                  style: const TextStyle(
                    color: PT.t2,
                    fontSize: 14,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: PT.s20),
                Wrap(
                  spacing: PT.s8,
                  runSpacing: PT.s8,
                  children: [
                    FilterStudioStatusChip(
                      label:
                          '${widget.totalLooks} ${widget.t.of('looks_label')}',
                      color: PT.mint,
                      icon: Icons.style_rounded,
                    ),
                    FilterStudioStatusChip(
                      label: widget.t.of('ai_tab'),
                      color: widget.accent,
                      icon: Icons.auto_awesome_rounded,
                    ),
                    FilterStudioStatusChip(
                      label: widget.t.of('pro_pack'),
                      color: PT.gold,
                      icon: Icons.workspace_premium_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: PT.s24),
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
                color: PT.cyan,
                icon: Icons.auto_awesome_rounded,
                title: widget.t.of('ai_auto_fix'),
                description: widget.t.of('ai_manual_desc'),
              ),
              const SizedBox(height: PT.s12),
              FilterStudioEmptyFeatureCard(
                color: PT.gold,
                icon: Icons.collections_rounded,
                title: widget.t.of('featured_drops'),
                description: widget.t.of('featured_drops_desc'),
              ),
              const SizedBox(height: PT.s12),
              FilterStudioEmptyFeatureCard(
                color: PT.purple,
                icon: Icons.style_rounded,
                title: widget.t.of('signature_library'),
                description: widget.t.of('signature_library_desc'),
              ),
            ],
          );

          if (stacked) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  hero,
                  const SizedBox(height: PT.s16),
                  features,
                ],
              ),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 6, child: hero),
              const SizedBox(width: PT.s16),
              Expanded(flex: 4, child: features),
            ],
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
      borderRadius: BorderRadius.circular(PT.r24),
      padding: const EdgeInsets.all(PT.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(PT.r16),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: PT.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: PT.t1,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: PT.s6),
                Text(
                  description,
                  style: const TextStyle(
                    color: PT.t2,
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
