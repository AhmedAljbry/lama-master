// bottom_controls.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Project imports ──────────────────────────────────────────────
import 'package:lama/core/i18n/t.dart'; // T, Lang
import 'package:lama/features/filter_studio/domain/entities/app_preset.dart';
import 'package:lama/features/filter_studio/domain/entities/preset_config.dart';
import 'package:lama/features/filter_studio/domain/entities/filter_studio_ai_insight.dart';
import 'package:lama/features/filter_studio/presentation/models/filter_studio_ai_style_match.dart';
import 'package:lama/features/filter_studio/presentation/models/filter_studio_style_preset.dart';
import 'package:lama/presentation/pages/PT.dart';
import 'package:lama/presentation/pages/Pro.dart'; // PresetConfig

// ─── Pro design system (same folder — relative) ───────────────────

// ─────────────────────────────────────────────────────────────────
typedef OnParamChanged = void Function(String key, Object value);

class SheetTabModel {
  final String key; // translation key
  final Widget child;
  const SheetTabModel(this.key, this.child);
}

// ─────────────────────────────────────────────────────────────────
// BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────
class ModernBottomSheet extends StatelessWidget {
  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final List<SheetTabModel> tabs;
  final Lang currentLang;

  const ModernBottomSheet({
    super.key,
    required this.tabIndex,
    required this.onTabChanged,
    required this.tabs,
    this.currentLang = Lang.en,
  });

  @override
  Widget build(BuildContext context) {
    final t = T(currentLang);
    return Directionality(
      textDirection: t.isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Pro.sp(context, 10),
            0,
            Pro.sp(context, 10),
            Pro.sp(context, 10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(PT.r24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: PT.card.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(PT.r24),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                  boxShadow: PT.elevation,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: PT.s12),
                    Container(
                      width: 40,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(PT.rFull),
                      ),
                    ),
                    const SizedBox(height: PT.s12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: PT.s12),
                      child: _SegmentedTabs(
                        labels: tabs.map((tab) => t.of(tab.key)).toList(),
                        index: tabIndex,
                        onChanged: onTabChanged,
                      ),
                    ),
                    SizedBox(
                      height: Pro.sheetH(context),
                      child: AnimatedSwitcher(
                        duration: PT.medium,
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.05),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(tabIndex),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              PT.s16,
                              PT.s12,
                              PT.s16,
                              PT.s16,
                            ),
                            child: tabs[tabIndex].child,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SEGMENTED TABS
// ─────────────────────────────────────────────────────────────────
class _SegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    return Container(
      padding: const EdgeInsets.all(PT.s4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(PT.r16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: LayoutBuilder(builder: (_, cons) {
        final itemW = cons.maxWidth / labels.length;
        return Stack(
          children: [
            AnimatedPositioned(
              duration: PT.medium,
              curve: Curves.easeOutCubic,
              left: isRTL ? null : itemW * index,
              right: isRTL ? itemW * index : null,
              top: 0,
              bottom: 0,
              width: itemW,
              child: Container(
                decoration: BoxDecoration(
                  gradient: PT.gradMint,
                  borderRadius: BorderRadius.circular(PT.r12),
                  boxShadow: PT.glow(PT.mint, blur: 12),
                ),
              ),
            ),
            Row(
              children: List.generate(labels.length, (i) {
                final sel = i == index;
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(i);
                    },
                    borderRadius: BorderRadius.circular(PT.r12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: PT.s10),
                      child: AnimatedDefaultTextStyle(
                        duration: PT.fast,
                        style: TextStyle(
                          fontSize: Pro.sp(context, 12),
                          fontWeight: FontWeight.w800,
                          color: sel ? Colors.black : PT.t2,
                        ),
                        child: Text(
                          labels[i],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// PRESETS TAB
// ─────────────────────────────────────────────────────────────────
class AiStudioTab extends StatelessWidget {
  final Lang lang;
  final bool hasImage;
  final FilterStudioAiInsight? insight;
  final bool isLoading;
  final Map<AppPreset, PresetConfig> presets;
  final List<FilterStudioAiStyleMatch> styleMatches;
  final VoidCallback onAnalyze;
  final VoidCallback onApplyInsight;
  final VoidCallback onSmartFocus;
  final VoidCallback onCinemaBoost;
  final VoidCallback onCleanPro;
  final ValueChanged<AppPreset> onApplyPreset;
  final ValueChanged<FilterStudioStylePreset> onApplyStyle;

  const AiStudioTab({
    super.key,
    required this.lang,
    required this.hasImage,
    required this.insight,
    required this.isLoading,
    required this.presets,
    required this.styleMatches,
    required this.onAnalyze,
    required this.onApplyInsight,
    required this.onSmartFocus,
    required this.onCinemaBoost,
    required this.onCleanPro,
    required this.onApplyPreset,
    required this.onApplyStyle,
  });

  @override
  Widget build(BuildContext context) {
    final t = T(lang);
    final activeInsight = insight;

    if (isLoading) {
      return _AiLoadingState(t: t);
    }

    if (activeInsight == null) {
      return _AiEmptyState(
        t: t,
        hasImage: hasImage,
        onAnalyze: hasImage ? onAnalyze : null,
      );
    }

    final accent = presets[activeInsight.recommendedPreset]?.auraColor ??
        presets[activeInsight.recommendedPreset]?.colorOverlay ??
        PT.cyan;
    final quickActionWidth =
        Pro.val(context, phone: 104.0, tablet: 128.0, desktop: 146.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.of('ai_report'),
                  style: const TextStyle(
                    color: PT.t1,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _SecondaryActionBtn(
                icon: Icons.auto_awesome_rounded,
                label: t.of('rerun_ai'),
                color: accent,
                onTap: onAnalyze,
              ),
            ],
          ),
          const SizedBox(height: PT.s10),
          Container(
            padding: const EdgeInsets.all(PT.s16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withOpacity(0.18),
                  PT.card2.withOpacity(0.86),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(PT.r20),
              border: Border.all(color: accent.withOpacity(0.28)),
              boxShadow: PT.glow(accent, blur: 24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent, PT.mint],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(PT.r16),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: PT.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.of('ai_director'),
                            style: const TextStyle(
                              color: PT.t1,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: PT.s4),
                          Text(
                            activeInsight.headline,
                            style: const TextStyle(
                              color: PT.t2,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PT.s12),
                Wrap(
                  spacing: PT.s8,
                  runSpacing: PT.s8,
                  children: [
                    _MetaChip(label: activeInsight.sceneLabel, color: PT.cyan),
                    _MetaChip(label: activeInsight.moodLabel, color: PT.gold),
                    _MetaChip(
                      label:
                          '${t.of('lighting')}: ${activeInsight.lightingLabel}',
                      color: accent,
                    ),
                  ],
                ),
                const SizedBox(height: PT.s12),
                Text(
                  activeInsight.summary,
                  style: const TextStyle(
                    color: PT.t2,
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PT.s12),
          Wrap(
            spacing: PT.s10,
            runSpacing: PT.s10,
            children: [
              _AiStatTile(
                label: t.of('focus'),
                value: activeInsight.subjectFocus,
                color: PT.mint,
              ),
              _AiStatTile(
                label: t.of('energy'),
                value: activeInsight.colorEnergy,
                color: PT.cyan,
              ),
              _AiStatTile(
                label: t.of('range'),
                value: activeInsight.dynamicRange,
                color: PT.gold,
              ),
              _AiStatTile(
                label: t.of('ai_match'),
                value: activeInsight.confidence,
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: PT.s14),
          GestureDetector(
            onTap: onApplyInsight,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: PT.s12,
                vertical: PT.s12,
              ),
              decoration: BoxDecoration(
                gradient: PT.gradMint,
                borderRadius: BorderRadius.circular(PT.r16),
                boxShadow: PT.glow(PT.mint, blur: 18),
              ),
              child: Text(
                t.of('apply_direction'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: PT.s14),
          Text(
            t.of('quick_actions'),
            style: const TextStyle(
              color: PT.t1,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: PT.s8),
          Wrap(
            spacing: PT.s8,
            runSpacing: PT.s8,
            children: [
              SizedBox(
                width: quickActionWidth,
                child: _QuickActionBtn(
                  icon: Icons.center_focus_strong_rounded,
                  label: t.of('smart_focus'),
                  color: PT.cyan,
                  onTap: onSmartFocus,
                ),
              ),
              SizedBox(
                width: quickActionWidth,
                child: _QuickActionBtn(
                  icon: Icons.movie_creation_outlined,
                  label: t.of('cinema_boost'),
                  color: PT.gold,
                  onTap: onCinemaBoost,
                ),
              ),
              SizedBox(
                width: quickActionWidth,
                child: _QuickActionBtn(
                  icon: Icons.auto_fix_high_rounded,
                  label: t.of('clean_pro'),
                  color: PT.mint,
                  onTap: onCleanPro,
                ),
              ),
            ],
          ),
          if (styleMatches.isNotEmpty) ...[
            const SizedBox(height: PT.s14),
            Text(
              t.of('ai_picks'),
              style: const TextStyle(
                color: PT.t1,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: PT.s8),
            SizedBox(
              height: 154,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: styleMatches.length,
                separatorBuilder: (_, __) => const SizedBox(width: PT.s10),
                itemBuilder: (_, index) {
                  final match = styleMatches[index];
                  return SizedBox(
                    width: Pro.val(
                      context,
                      phone: 214.0,
                      tablet: 236.0,
                      desktop: 248.0,
                    ),
                    child: _AiStyleMatchCard(
                      lang: lang,
                      match: match,
                      onTap: () => onApplyStyle(match.style),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: PT.s14),
          Text(
            t.of('recommended_presets'),
            style: const TextStyle(
              color: PT.t1,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: PT.s8),
          Wrap(
            spacing: PT.s8,
            runSpacing: PT.s8,
            children: activeInsight.alternatePresets.map((preset) {
              final config = presets[preset];
              final presetAccent =
                  config?.auraColor ?? config?.colorOverlay ?? accent;
              return _AiPresetChip(
                label: config?.name ?? preset.name,
                color: presetAccent,
                highlighted: preset == activeInsight.recommendedPreset,
                onTap: () => onApplyPreset(preset),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AiLoadingState extends StatelessWidget {
  final T t;

  const _AiLoadingState({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PT.s20),
      decoration: BoxDecoration(
        color: PT.card2,
        borderRadius: BorderRadius.circular(PT.r20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: PT.mint,
            ),
          ),
          const SizedBox(width: PT.s12),
          Expanded(
            child: Text(
              t.of('ai_loading'),
              style: const TextStyle(
                color: PT.t2,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiEmptyState extends StatelessWidget {
  final T t;
  final bool hasImage;
  final VoidCallback? onAnalyze;

  const _AiEmptyState({
    required this.t,
    required this.hasImage,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(PT.s16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PT.purple.withOpacity(0.18),
                  PT.card2.withOpacity(0.90),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(PT.r20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: PT.glow(PT.purple, blur: 28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: PT.gradPurple,
                        borderRadius: BorderRadius.circular(PT.r16),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: PT.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.of('ai_manual_title'),
                            style: const TextStyle(
                              color: PT.t1,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: PT.s4),
                          Text(
                            hasImage
                                ? t.of('ai_manual_desc')
                                : t.of('ai_no_image_desc'),
                            style: const TextStyle(
                              color: PT.t2,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: PT.s6),
                          Text(
                            t.of('background_optional'),
                            style: const TextStyle(
                              color: PT.t3,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PT.s14),
                Wrap(
                  spacing: PT.s8,
                  runSpacing: PT.s8,
                  children: [
                    _MetaChip(label: t.of('ai_manual'), color: PT.purple),
                    _MetaChip(
                        label: t.of('ai_recommendations'), color: PT.cyan),
                    _MetaChip(label: t.of('quick_actions'), color: PT.gold),
                  ],
                ),
                const SizedBox(height: PT.s14),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: onAnalyze,
                    child: AnimatedOpacity(
                      duration: PT.fast,
                      opacity: onAnalyze == null ? 0.45 : 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: PT.s12,
                          vertical: PT.s12,
                        ),
                        decoration: BoxDecoration(
                          gradient: onAnalyze == null ? null : PT.gradMint,
                          color: onAnalyze == null ? PT.card : null,
                          borderRadius: BorderRadius.circular(PT.r16),
                          boxShadow: onAnalyze == null
                              ? const []
                              : PT.glow(PT.mint, blur: 18),
                        ),
                        child: Text(
                          hasImage ? t.of('ai_auto_fix') : t.of('tap_to_open'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: onAnalyze == null ? PT.t3 : Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PT.s12),
          Wrap(
            spacing: PT.s10,
            runSpacing: PT.s10,
            children: [
              _AiFeatureTile(
                icon: Icons.landscape_rounded,
                title: t.of('scene'),
                body: t.of('ai_feature_scene'),
                color: PT.cyan,
              ),
              _AiFeatureTile(
                icon: Icons.style_rounded,
                title: t.of('recommended_presets'),
                body: t.of('ai_feature_preset'),
                color: PT.gold,
              ),
              _AiFeatureTile(
                icon: Icons.tune_rounded,
                title: t.of('quick_actions'),
                body: t.of('ai_feature_finish'),
                color: PT.mint,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiFeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _AiFeatureTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Pro.val(context, phone: 156.0, tablet: 178.0, desktop: 188.0),
      padding: const EdgeInsets.all(PT.s14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(PT.r20),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: PT.s10),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: PT.s6),
          Text(
            body,
            style: const TextStyle(
              color: PT.t2,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiStatTile extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _AiStatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round().clamp(0, 100);
    return Container(
      width: Pro.val(context, phone: 132.0, tablet: 142.0, desktop: 150.0),
      padding: const EdgeInsets.all(PT.s12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(PT.r16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: PT.t2,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: PT.s8),
          Text(
            '$pct%',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: PT.s8),
          ClipRRect(
            borderRadius: BorderRadius.circular(PT.rFull),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PT.s10,
          vertical: PT.s12,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(PT.r16),
          border: Border.all(color: color.withOpacity(0.24)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: PT.s6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SecondaryActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: PT.s12, vertical: PT.s8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(PT.rFull),
          border: Border.all(color: color.withOpacity(0.24)),
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
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiPresetChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool highlighted;
  final VoidCallback onTap;

  const _AiPresetChip({
    required this.label,
    required this.color,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: PT.fast,
        padding:
            const EdgeInsets.symmetric(horizontal: PT.s12, vertical: PT.s10),
        decoration: BoxDecoration(
          color: highlighted
              ? color.withOpacity(0.14)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(PT.rFull),
          border: Border.all(
            color: highlighted ? color : color.withOpacity(0.20),
          ),
          boxShadow: highlighted ? PT.glow(color, blur: 14) : const [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: highlighted ? color : PT.t1,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AiStyleMatchCard extends StatelessWidget {
  final Lang lang;
  final FilterStudioAiStyleMatch match;
  final VoidCallback onTap;

  const _AiStyleMatchCard({
    required this.lang,
    required this.match,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = T(lang);
    final style = match.style;
    final accent = style.accent;
    final score = (match.score * 100).round().clamp(0, 100);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(PT.s14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withOpacity(0.18),
              PT.card2.withOpacity(0.94),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(PT.r20),
          border: Border.all(color: accent.withOpacity(0.28)),
          boxShadow: PT.glow(accent, blur: 18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(PT.r12),
                  ),
                  child: Icon(style.icon, size: 18, color: accent),
                ),
                const SizedBox(width: PT.s10),
                Expanded(
                  child: Text(
                    style.badge(lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PT.s8,
                    vertical: PT.s6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(PT.rFull),
                    border: Border.all(color: accent.withOpacity(0.24)),
                  ),
                  child: Text(
                    '$score% ${t.of('ai_match')}',
                    style: TextStyle(
                      color: accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: PT.s12),
            Text(
              style.name(lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PT.t1,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: PT.s6),
            Text(
              style.tagline(lang),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PT.t2,
                fontSize: 11,
                height: 1.45,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    style.categoryLabel(lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PT.t3,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: PT.s8),
                Text(
                  t.of('instant_apply'),
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: PT.s10, vertical: PT.s7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(PT.rFull),
        border: Border.all(color: color.withOpacity(0.26)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class PresetsTab extends StatefulWidget {
  final Lang lang;
  final Map<AppPreset, PresetConfig> presets;
  final AppPreset selectedPreset;
  final ValueChanged<AppPreset> onPresetSelected;
  final List<FilterStudioStylePreset> styleLibrary;
  final String? selectedStyleId;
  final ValueChanged<FilterStudioStylePreset> onStyleSelected;

  const PresetsTab({
    super.key,
    required this.lang,
    required this.presets,
    required this.selectedPreset,
    required this.onPresetSelected,
    required this.styleLibrary,
    required this.selectedStyleId,
    required this.onStyleSelected,
  });

  @override
  State<PresetsTab> createState() => _PresetsTabState();
}

class _PresetsTabState extends State<PresetsTab> {
  String _categoryId = 'all';

  @override
  Widget build(BuildContext context) {
    final t = T(widget.lang);
    final featuredStyles =
        widget.styleLibrary.where((style) => style.featured).toList();
    final visibleStyles = _categoryId == 'all'
        ? widget.styleLibrary
        : widget.styleLibrary
            .where((style) => style.categoryId == _categoryId)
            .toList();
    final categories = <_StyleCategoryFilter>[
      _StyleCategoryFilter(id: 'all', label: t.of('all_styles')),
      ..._buildCategoryFilters(widget.styleLibrary, widget.lang),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PresetLibraryHero(
            t: t,
            totalStyles: widget.styleLibrary.length,
            totalPacks: widget.styleLibrary
                .map((style) => style.categoryId)
                .toSet()
                .length,
          ),
          const SizedBox(height: PT.s16),
          _SectionHeader(
            title: t.of('featured_drops'),
            subtitle: t.of('featured_drops_desc'),
          ),
          const SizedBox(height: PT.s10),
          SizedBox(
            height: 164,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: featuredStyles.length,
              separatorBuilder: (_, __) => const SizedBox(width: PT.s10),
              itemBuilder: (_, index) {
                final style = featuredStyles[index];
                return SizedBox(
                  width: Pro.val(context,
                      phone: 220.0, tablet: 248.0, desktop: 272.0),
                  child: _FeaturedStyleCard(
                    lang: widget.lang,
                    style: style,
                    selected: style.id == widget.selectedStyleId,
                    onTap: () => widget.onStyleSelected(style),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: PT.s16),
          _SectionHeader(
            title: t.of('core_presets'),
            subtitle: t.of('core_presets_desc'),
          ),
          const SizedBox(height: PT.s10),
          SizedBox(
            height: 168,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.presets.length,
              itemBuilder: (_, i) {
                final entry = widget.presets.entries.elementAt(i);
                final preset = entry.key;
                final config = entry.value;
                final isSelected = widget.selectedStyleId == null &&
                    preset == widget.selectedPreset;
                return _CorePresetCard(
                  preset: preset,
                  config: config,
                  isSelected: isSelected,
                  onTap: () => widget.onPresetSelected(preset),
                );
              },
            ),
          ),
          const SizedBox(height: PT.s16),
          _SectionHeader(
            title: t.of('curated_packs'),
            subtitle: t.of('curated_packs_desc'),
          ),
          const SizedBox(height: PT.s10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final isSelected = category.id == _categoryId;
                return Padding(
                  padding: const EdgeInsets.only(right: PT.s8),
                  child: _CategoryChip(
                    label: category.label,
                    selected: isSelected,
                    onTap: () => setState(() => _categoryId = category.id),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: PT.s16),
          _SectionHeader(
            title: t.of('signature_library'),
            subtitle:
                '${visibleStyles.length} ${t.of('signature_library_count')}',
          ),
          const SizedBox(height: PT.s10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 560
                      ? 2
                      : 1;
              final spacing = PT.s12;
              final itemWidth =
                  (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: visibleStyles.map((style) {
                  return SizedBox(
                    width: itemWidth,
                    child: _StyleGridCard(
                      lang: widget.lang,
                      style: style,
                      selected: style.id == widget.selectedStyleId,
                      onTap: () => widget.onStyleSelected(style),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

List<_StyleCategoryFilter> _buildCategoryFilters(
  List<FilterStudioStylePreset> styles,
  Lang lang,
) {
  final seen = <String>{};
  final filters = <_StyleCategoryFilter>[];

  for (final style in styles) {
    if (seen.add(style.categoryId)) {
      filters.add(
        _StyleCategoryFilter(
          id: style.categoryId,
          label: style.categoryLabel(lang),
        ),
      );
    }
  }

  return filters;
}

class _StyleCategoryFilter {
  final String id;
  final String label;

  const _StyleCategoryFilter({
    required this.id,
    required this.label,
  });
}

class _PresetLibraryHero extends StatelessWidget {
  final T t;
  final int totalStyles;
  final int totalPacks;

  const _PresetLibraryHero({
    required this.t,
    required this.totalStyles,
    required this.totalPacks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PT.s16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PT.cyan.withOpacity(0.16),
            PT.card2.withOpacity(0.92),
            PT.purple.withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(PT.r24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: PT.glow(PT.cyan, blur: 28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.of('signature_library'),
            style: const TextStyle(
              color: PT.t1,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: PT.s6),
          Text(
            t.of('signature_library_desc'),
            style: const TextStyle(
              color: PT.t2,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: PT.s14),
          Wrap(
            spacing: PT.s10,
            runSpacing: PT.s10,
            children: [
              _LibraryStatPill(
                value: '$totalStyles',
                label: t.of('looks_label'),
                color: PT.cyan,
              ),
              _LibraryStatPill(
                value: '$totalPacks',
                label: t.of('packs_label'),
                color: PT.gold,
              ),
              _LibraryStatPill(
                value: '1 Tap',
                label: t.of('instant_apply'),
                color: PT.mint,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LibraryStatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _LibraryStatPill({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: PT.s12, vertical: PT.s10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(PT.r16),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: PT.t2,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: PT.t1,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: PT.s4),
        Text(
          subtitle,
          style: const TextStyle(
            color: PT.t3,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: PT.fast,
        padding:
            const EdgeInsets.symmetric(horizontal: PT.s12, vertical: PT.s8),
        decoration: BoxDecoration(
          gradient: selected ? PT.gradMint : null,
          color: selected ? null : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(PT.rFull),
          border: Border.all(
            color:
                selected ? Colors.transparent : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : PT.t2,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _FeaturedStyleCard extends StatelessWidget {
  final Lang lang;
  final FilterStudioStylePreset style;
  final bool selected;
  final VoidCallback onTap;

  const _FeaturedStyleCard({
    required this.lang,
    required this.style,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: PT.medium,
        padding: const EdgeInsets.all(PT.s14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              style.accent.withOpacity(selected ? 0.22 : 0.16),
              PT.card2.withOpacity(0.94),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(PT.r20),
          border: Border.all(
            color: selected ? style.accent : Colors.white.withOpacity(0.08),
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected ? PT.glow(style.accent, blur: 22) : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PT.s8,
                    vertical: PT.s4,
                  ),
                  decoration: BoxDecoration(
                    color: style.accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(PT.rFull),
                  ),
                  child: Text(
                    style.badge(lang),
                    style: TextStyle(
                      color: style.accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(style.icon, color: style.accent, size: 18),
              ],
            ),
            const Spacer(),
            Text(
              style.name(lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PT.t1,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: PT.s6),
            Text(
              style.tagline(lang),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PT.t2,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CorePresetCard extends StatelessWidget {
  final AppPreset preset;
  final PresetConfig config;
  final bool isSelected;
  final VoidCallback onTap;

  const _CorePresetCard({
    required this.preset,
    required this.config,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = config.auraColor ?? config.colorOverlay ?? PT.mint;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: PT.medium,
        curve: Curves.easeOutCubic,
        width: Pro.sp(context, isSelected ? 122 : 110),
        margin: EdgeInsets.symmetric(
          horizontal: Pro.sp(context, 5),
          vertical: PT.s4,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [
                    accent.withOpacity(0.22),
                    PT.card2.withOpacity(0.96),
                  ]
                : [
                    Colors.white.withOpacity(0.04),
                    PT.card2.withOpacity(0.86),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(PT.r16),
          border: Border.all(
            color: isSelected ? accent : Colors.white.withOpacity(0.08),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? PT.glow(accent, blur: 16) : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: PT.s10, left: PT.s10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: PT.s8,
                  vertical: PT.s4,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(PT.rFull),
                ),
                child: Text(
                  _presetBadge(preset),
                  style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            const Spacer(),
            AnimatedContainer(
              duration: PT.medium,
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withOpacity(0.18)
                    : Colors.white.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
              child: Icon(
                config.icon,
                size: Pro.sp(context, 24),
                color: isSelected ? accent : PT.t2,
              ),
            ),
            const SizedBox(height: PT.s8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: PT.s10),
              child: Text(
                config.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Pro.sp(context, 11),
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: isSelected ? PT.t1 : PT.t2,
                ),
              ),
            ),
            const SizedBox(height: PT.s10),
          ],
        ),
      ),
    );
  }
}

class _StyleGridCard extends StatelessWidget {
  final Lang lang;
  final FilterStudioStylePreset style;
  final bool selected;
  final VoidCallback onTap;

  const _StyleGridCard({
    required this.lang,
    required this.style,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: PT.fast,
        padding: const EdgeInsets.all(PT.s14),
        decoration: BoxDecoration(
          color: selected
              ? style.accent.withOpacity(0.14)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(PT.r20),
          border: Border.all(
            color: selected ? style.accent : Colors.white.withOpacity(0.08),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected ? PT.glow(style.accent, blur: 18) : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: PT.s6,
                    runSpacing: PT.s6,
                    children: [
                      _MiniLabel(
                        label: style.badge(lang),
                        color: style.accent,
                      ),
                      _MiniLabel(
                        label: style.categoryLabel(lang),
                        color: PT.t2,
                      ),
                    ],
                  ),
                ),
                Icon(style.icon, size: 18, color: style.accent),
              ],
            ),
            const SizedBox(height: PT.s14),
            Text(
              style.name(lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PT.t1,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: PT.s6),
            Text(
              style.tagline(lang),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PT.t2,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniLabel({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: PT.s8, vertical: PT.s4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(PT.rFull),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _presetBadge(AppPreset preset) {
  switch (preset) {
    case AppPreset.editorial:
    case AppPreset.vaporwave:
    case AppPreset.chrome:
    case AppPreset.halo:
    case AppPreset.monoPop:
    case AppPreset.street:
      return 'NEW';
    default:
      return 'PRO';
  }
}

// ─────────────────────────────────────────────────────────────────
// ADJUST TAB
// ─────────────────────────────────────────────────────────────────
class AdjustTab extends StatelessWidget {
  final Lang lang;
  final double exposure,
      brightness,
      contrast,
      saturation,
      warmth,
      tint,
      highlights,
      shadows,
      clarity,
      dehaze,
      sharpen,
      vignette,
      vignetteSize;
  final bool replaceBackground;
  final bool canUndo, canRedo;
  final VoidCallback onUndo, onRedo, onReset;
  final VoidCallback onCompareHoldStart, onCompareHoldEnd;
  final OnParamChanged onParamChanged;

  const AdjustTab({
    super.key,
    required this.lang,
    required this.exposure,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.warmth,
    required this.tint,
    required this.highlights,
    required this.shadows,
    required this.clarity,
    required this.dehaze,
    required this.sharpen,
    required this.vignette,
    required this.vignetteSize,
    required this.replaceBackground,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onReset,
    required this.onCompareHoldStart,
    required this.onCompareHoldEnd,
    required this.onParamChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = T(lang);
    return Column(
      children: [
        _AdjustActions(
          t: t,
          canUndo: canUndo,
          canRedo: canRedo,
          onUndo: onUndo,
          onRedo: onRedo,
          onReset: onReset,
          onCompareStart: onCompareHoldStart,
          onCompareEnd: onCompareHoldEnd,
          replaceBackground: replaceBackground,
          onToggleBg: (v) => onParamChanged('replaceBackground', v),
        ),
        const SizedBox(height: PT.s8),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(children: [
              _SliderRow(
                  icon: Icons.wb_sunny_outlined,
                  label: t.of('exposure'),
                  value: exposure,
                  min: -1.0,
                  max: 1.0,
                  onChanged: (v) => onParamChanged('exposure', v)),
              _SliderRow(
                  icon: Icons.brightness_6_rounded,
                  label: t.of('brightness'),
                  value: brightness,
                  min: -0.5,
                  max: 0.5,
                  onChanged: (v) => onParamChanged('brightness', v)),
              _SliderRow(
                  icon: Icons.contrast_rounded,
                  label: t.of('contrast'),
                  value: contrast,
                  min: 0.5,
                  max: 1.5,
                  onChanged: (v) => onParamChanged('contrast', v)),
              _SliderRow(
                  icon: Icons.color_lens_outlined,
                  label: t.of('saturation'),
                  value: saturation,
                  min: 0.0,
                  max: 2.0,
                  onChanged: (v) => onParamChanged('saturation', v)),
              _SliderRow(
                  icon: Icons.thermostat_rounded,
                  label: t.of('warmth'),
                  value: warmth,
                  min: -1,
                  max: 1,
                  onChanged: (v) => onParamChanged('warmth', v)),
              _SliderRow(
                  icon: Icons.gradient_rounded,
                  label: t.of('tint'),
                  value: tint,
                  min: -1,
                  max: 1,
                  onChanged: (v) => onParamChanged('tint', v)),
              _SliderRow(
                  icon: Icons.highlight_rounded,
                  label: t.of('highlights'),
                  value: highlights,
                  min: -1,
                  max: 1,
                  onChanged: (v) => onParamChanged('highlights', v)),
              _SliderRow(
                  icon: Icons.nights_stay_rounded,
                  label: t.of('shadows'),
                  value: shadows,
                  min: -1,
                  max: 1,
                  onChanged: (v) => onParamChanged('shadows', v)),
              _SliderRow(
                  icon: Icons.lens_blur_rounded,
                  label: t.of('clarity'),
                  value: clarity,
                  min: 0,
                  max: 1,
                  onChanged: (v) => onParamChanged('clarity', v)),
              _SliderRow(
                  icon: Icons.cloud_off_rounded,
                  label: t.of('dehaze'),
                  value: dehaze,
                  min: 0,
                  max: 1,
                  onChanged: (v) => onParamChanged('dehaze', v)),
              _SliderRow(
                  icon: Icons.auto_fix_high_rounded,
                  label: t.of('sharpen'),
                  value: sharpen,
                  min: 0,
                  max: 1,
                  onChanged: (v) => onParamChanged('sharpen', v)),
              _SliderRow(
                  icon: Icons.vignette_rounded,
                  label: t.of('vignette'),
                  value: vignette,
                  min: 0,
                  max: 1,
                  onChanged: (v) => onParamChanged('vignette', v)),
              _SliderRow(
                  icon: Icons.crop_free_rounded,
                  label: t.of('vignette_size'),
                  value: vignetteSize,
                  min: 0.2,
                  max: 0.9,
                  onChanged: (v) => onParamChanged('vignetteSize', v)),
            ]),
          ),
        ),
      ],
    );
  }
}

class _AdjustActions extends StatelessWidget {
  final T t;
  final bool canUndo, canRedo, replaceBackground;
  final VoidCallback onUndo, onRedo, onReset;
  final VoidCallback onCompareStart, onCompareEnd;
  final ValueChanged<bool> onToggleBg;

  const _AdjustActions({
    required this.t,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onReset,
    required this.onCompareStart,
    required this.onCompareEnd,
    required this.replaceBackground,
    required this.onToggleBg,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: PT.s8,
      runSpacing: PT.s8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MicroBtn(
            icon: Icons.undo_rounded,
            label: t.of('undo'),
            color: canUndo ? PT.mint : PT.t3,
            onTap: canUndo ? onUndo : null),
        _MicroBtn(
            icon: Icons.redo_rounded,
            label: t.of('redo'),
            color: canRedo ? PT.mint : PT.t3,
            onTap: canRedo ? onRedo : null),
        _MicroBtn(
            icon: Icons.restore_rounded,
            label: t.of('reset'),
            color: PT.gold,
            onTap: onReset),
        GestureDetector(
          onTapDown: (_) => onCompareStart(),
          onTapUp: (_) => onCompareEnd(),
          onTapCancel: onCompareEnd,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: PT.s12, vertical: PT.s8),
            decoration: BoxDecoration(
              color: PT.mint.withOpacity(0.1),
              borderRadius: BorderRadius.circular(PT.r12),
              border: Border.all(color: PT.mint.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.compare_arrows_rounded,
                  color: PT.mint, size: 14),
              const SizedBox(width: PT.s4),
              Text(t.of('compare'),
                  style: const TextStyle(
                      color: PT.mint,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
        _ToggleChip(
          label: t.of('remove_bg'),
          active: replaceBackground,
          activeColor: PT.coral,
          onTap: () => onToggleBg(!replaceBackground),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// EFFECTS TAB
// ─────────────────────────────────────────────────────────────────
class EffectsTab extends StatelessWidget {
  final Lang lang;
  final double blur, aura, grain, scanlines, glitch;
  final Color auraColor;
  final bool ghost, colorPop;
  final OnParamChanged onParamChanged;

  const EffectsTab({
    super.key,
    required this.lang,
    required this.blur,
    required this.aura,
    required this.auraColor,
    required this.grain,
    required this.scanlines,
    required this.glitch,
    required this.ghost,
    required this.colorPop,
    required this.onParamChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = T(lang);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SliderRow(
            icon: Icons.blur_on_rounded,
            label: t.of('blur'),
            value: blur,
            min: 0,
            max: 20,
            onChanged: (v) => onParamChanged('blur', v)),
        _SliderRow(
            icon: Icons.flare_rounded,
            label: t.of('aura'),
            value: aura,
            min: 0,
            max: 1,
            onChanged: (v) => onParamChanged('aura', v)),
        _SliderRow(
            icon: Icons.grain_rounded,
            label: t.of('grain'),
            value: grain,
            min: 0,
            max: 0.5,
            onChanged: (v) => onParamChanged('grain', v)),
        _SliderRow(
            icon: Icons.horizontal_rule_rounded,
            label: t.of('scanlines'),
            value: scanlines,
            min: 0,
            max: 0.8,
            onChanged: (v) => onParamChanged('scanlines', v)),
        _SliderRow(
            icon: Icons.electrical_services,
            label: t.of('glitch'),
            value: glitch,
            min: 0,
            max: 5,
            onChanged: (v) => onParamChanged('glitch', v)),
        if (aura > 0.05) ...[
          const SizedBox(height: PT.s8),
          Text(t.of('aura_color'),
              style: const TextStyle(
                  color: PT.t2, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: PT.s8),
          _AuraColorPicker(
              selected: auraColor,
              onPick: (c) => onParamChanged('auraColor', c)),
        ],
        const SizedBox(height: PT.s12),
        Row(children: [
          Expanded(
              child: _ToggleBtn(
                  icon: Icons.person_rounded,
                  label: t.of('ghost'),
                  active: ghost,
                  onTap: () => onParamChanged('ghost', !ghost))),
          const SizedBox(width: PT.s10),
          Expanded(
              child: _ToggleBtn(
                  icon: Icons.color_lens_rounded,
                  label: t.of('color_pop'),
                  active: colorPop,
                  activeColor: PT.purple,
                  onTap: () => onParamChanged('colorPop', !colorPop))),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// OVERLAYS TAB
// ─────────────────────────────────────────────────────────────────
class OverlaysTab extends StatelessWidget {
  final Lang lang;
  final bool showDateStamp, cinemaMode, polaroidFrame;
  final double vignette, prismOverlay, dustOverlay;
  final int lightLeakIndex;
  final OnParamChanged onParamChanged;

  const OverlaysTab({
    super.key,
    required this.lang,
    required this.showDateStamp,
    required this.cinemaMode,
    required this.polaroidFrame,
    required this.vignette,
    required this.lightLeakIndex,
    required this.prismOverlay,
    required this.dustOverlay,
    required this.onParamChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = T(lang);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: _SwitchRow(
                  label: t.of('date_stamp'),
                  value: showDateStamp,
                  onChanged: (v) => onParamChanged('showDateStamp', v))),
          const SizedBox(width: PT.s8),
          Expanded(
              child: _SwitchRow(
                  label: t.of('cinema_bar'),
                  value: cinemaMode,
                  onChanged: (v) => onParamChanged('cinemaMode', v))),
        ]),
        const SizedBox(height: PT.s8),
        Row(children: [
          Expanded(
              child: _SwitchRow(
                  label: t.of('polaroid'),
                  value: polaroidFrame,
                  onChanged: (v) => onParamChanged('polaroidFrame', v))),
          const Expanded(child: SizedBox()),
        ]),
        const SizedBox(height: PT.s8),
        _SliderRow(
            icon: Icons.vignette_rounded,
            label: t.of('vignette'),
            value: vignette,
            min: 0,
            max: 0.8,
            onChanged: (v) => onParamChanged('vignette', v)),
        const SizedBox(height: PT.s12),
        Text(t.of('overlay_finish_title'),
            style: const TextStyle(
                color: PT.t2, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: PT.s4),
        Text(t.of('overlay_finish_desc'),
            style: const TextStyle(color: PT.t3, fontSize: 11, height: 1.4)),
        const SizedBox(height: PT.s8),
        _SliderRow(
            icon: Icons.auto_awesome_rounded,
            label: t.of('prism_overlay'),
            value: prismOverlay,
            min: 0,
            max: 0.6,
            onChanged: (v) => onParamChanged('prismOverlay', v)),
        _SliderRow(
            icon: Icons.grain_rounded,
            label: t.of('dust_overlay'),
            value: dustOverlay,
            min: 0,
            max: 0.4,
            onChanged: (v) => onParamChanged('dustOverlay', v)),
        const SizedBox(height: PT.s12),
        Text(t.of('light_leaks'),
            style: const TextStyle(
                color: PT.t2, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: PT.s8),
        Row(children: [
          _LeakBtn(
              label: t.of('none'),
              index: 0,
              selected: lightLeakIndex,
              color: PT.t2,
              onTap: (i) => onParamChanged('lightLeakIndex', i)),
          const SizedBox(width: PT.s8),
          _LeakBtn(
              label: t.of('warm'),
              index: 1,
              selected: lightLeakIndex,
              color: PT.gold,
              onTap: (i) => onParamChanged('lightLeakIndex', i)),
          const SizedBox(width: PT.s8),
          _LeakBtn(
              label: t.of('cool'),
              index: 2,
              selected: lightLeakIndex,
              color: PT.cyan,
              onTap: (i) => onParamChanged('lightLeakIndex', i)),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// ATOMS
// ─────────────────────────────────────────────────────────────────
class _SliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value, min, max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pct = max == min ? 0 : ((value - min) / (max - min) * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Icon(icon, size: Pro.sp(context, 14), color: PT.t3),
        const SizedBox(width: PT.s8),
        SizedBox(
          width: Pro.sp(context, 80),
          child: Text(label,
              style: TextStyle(
                  color: PT.t2,
                  fontSize: Pro.sp(context, 11),
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: PT.mint.withOpacity(0.85),
              inactiveTrackColor: Colors.white.withOpacity(0.08),
              thumbColor: PT.mint,
              overlayColor: PT.mint.withOpacity(0.1),
              trackHeight: 1.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text('$pct',
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: PT.t3,
                  fontSize: Pro.sp(context, 10),
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color? activeColor;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = activeColor ?? PT.mint;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: PT.fast,
        padding: const EdgeInsets.symmetric(vertical: PT.s12),
        decoration: BoxDecoration(
          color: active ? c.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(PT.r12),
          border:
              Border.all(color: active ? c : Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: active ? c : PT.t2),
            const SizedBox(width: PT.s6),
            Text(label,
                style: TextStyle(
                    color: active ? c : PT.t2,
                    fontSize: Pro.sp(context, 12),
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color? activeColor;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = activeColor ?? PT.mint;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: PT.fast,
        padding:
            const EdgeInsets.symmetric(horizontal: PT.s10, vertical: PT.s6),
        decoration: BoxDecoration(
          color: active ? c.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(PT.rFull),
          border: Border.all(color: active ? c : Colors.white.withOpacity(0.1)),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? c : PT.t2,
                fontSize: Pro.sp(context, 11),
                fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: PT.fast,
        padding:
            const EdgeInsets.symmetric(horizontal: PT.s12, vertical: PT.s10),
        decoration: BoxDecoration(
          color: value ? PT.gold.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(PT.r12),
          border: Border.all(
              color: value
                  ? PT.gold.withOpacity(0.4)
                  : Colors.white.withOpacity(0.08)),
        ),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: value ? PT.t1 : PT.t2,
                      fontSize: Pro.sp(context, 11),
                      fontWeight: FontWeight.w700))),
          AnimatedContainer(
            duration: PT.fast,
            width: 28,
            height: 16,
            decoration: BoxDecoration(
              color: value
                  ? PT.gold.withOpacity(0.7)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(PT.rFull),
            ),
            child: Align(
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MicroBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _MicroBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onTap!();
            }
          : null,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: PT.s10, vertical: PT.s6),
        decoration: BoxDecoration(
          color: color.withOpacity(enabled ? 0.08 : 0.03),
          borderRadius: BorderRadius.circular(PT.r12),
          border: Border.all(color: color.withOpacity(enabled ? 0.25 : 0.08)),
        ),
        child: Row(children: [
          Icon(icon, size: 14, color: color.withOpacity(enabled ? 1 : 0.3)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color.withOpacity(enabled ? 0.9 : 0.3),
                  fontSize: Pro.sp(context, 10),
                  fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

class _LeakBtn extends StatelessWidget {
  final String label;
  final int index, selected;
  final Color color;
  final ValueChanged<int> onTap;

  const _LeakBtn({
    required this.label,
    required this.index,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSel = index == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap(index);
        },
        child: AnimatedContainer(
          duration: PT.fast,
          padding: const EdgeInsets.symmetric(vertical: PT.s10),
          decoration: BoxDecoration(
            color: isSel ? color.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(PT.r12),
            border: Border.all(
                color: isSel ? color : Colors.white.withOpacity(0.08)),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isSel ? color : PT.t2,
                  fontSize: Pro.sp(context, 12),
                  fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class _AuraColorPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onPick;

  const _AuraColorPicker({required this.selected, required this.onPick});

  static const _colors = <Color>[
    Colors.purpleAccent,
    Colors.blueAccent,
    PT.mint,
    PT.cyan,
    Colors.pinkAccent,
    Colors.redAccent,
    Colors.white,
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _colors.map((c) {
          final isSel = c.value == selected.value;
          return GestureDetector(
            onTap: () => onPick(c),
            child: AnimatedContainer(
              duration: PT.fast,
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(right: PT.s8),
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSel ? Colors.white : Colors.transparent,
                    width: isSel ? 2.5 : 1),
                boxShadow: isSel ? PT.glow(c, blur: 12) : [],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
