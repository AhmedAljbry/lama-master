import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/core/ui/AppTokens.dart';
import 'package:lama/features/studio_editor/presentation/pages/studio_editor_main_screen.dart';
import 'components/editor_contextual_tools.dart';
import 'components/sidebar_components.dart';

class StudioToolsSidebar extends StatefulWidget {
  final EditorState state;
  final bool useAI;
  final bool hasTarget;
  final bool hasRef;
  final bool hasManualMask;
  final String selectedStyle;
  final double strength;
  final double skinProtect;
  final double lumaTransfer;
  final double colorTransfer;
  final double contrast;
  final double vignette;
  final double grain;
  final bool isHorizontalScrollable;
  final bool isBusy;
  final ScrollController? scrollController;
  final ValueChanged<bool> onAIToggle;
  final VoidCallback onPickTarget;
  final VoidCallback onPickRef;
  final VoidCallback onManualSelect;
  final ValueChanged<String> onStyleChanged;
  final ValueChanged<double> onStrengthChanged;
  final ValueChanged<double> onSkinProtectChanged;
  final ValueChanged<double> onLumaChanged;
  final ValueChanged<double> onColorChanged;
  final ValueChanged<double> onContrastChanged;
  final ValueChanged<double> onVignetteChanged;
  final ValueChanged<double> onGrainChanged;
  final VoidCallback onApply;
  final VoidCallback onEditResult;

  const StudioToolsSidebar({
    super.key,
    required this.state,
    required this.useAI,
    required this.hasTarget,
    required this.hasRef,
    required this.hasManualMask,
    required this.selectedStyle,
    required this.strength,
    required this.skinProtect,
    required this.lumaTransfer,
    required this.colorTransfer,
    required this.contrast,
    required this.vignette,
    required this.grain,
    this.isHorizontalScrollable = false,
    this.isBusy = false,
    this.scrollController,
    required this.onAIToggle,
    required this.onPickTarget,
    required this.onPickRef,
    required this.onManualSelect,
    required this.onStyleChanged,
    required this.onStrengthChanged,
    required this.onSkinProtectChanged,
    required this.onLumaChanged,
    required this.onColorChanged,
    required this.onContrastChanged,
    required this.onVignetteChanged,
    required this.onGrainChanged,
    required this.onApply,
    required this.onEditResult,
  });

  @override
  State<StudioToolsSidebar> createState() => _StudioToolsSidebarState();
}

class _StudioToolsSidebarState extends State<StudioToolsSidebar> {
  EditorToolCategory _activeCategory = EditorToolCategory.source;
  String? _activeSliderLabel;

  static const List<String> kStyleKeys = <String>[
    'style_luma_master',
    'style_pro_studio',
    'style_color_theft',
    'style_theme_theft',
    'style_cinematic',
    'style_cyber_neon',
    'style_color_splash',
    'style_hdr_magic',
    'style_sepia_retro',
  ];

  static const Map<String, IconData> _styleIcons = <String, IconData>{
    'style_luma_master': Icons.auto_awesome_rounded,
    'style_pro_studio': Icons.stars_rounded,
    'style_color_theft': Icons.palette_rounded,
    'style_theme_theft': Icons.style_rounded,
    'style_cinematic': Icons.movie_filter_rounded,
    'style_cyber_neon': Icons.bolt_rounded,
    'style_color_splash': Icons.blur_on_rounded,
    'style_hdr_magic': Icons.hdr_strong_rounded,
    'style_sepia_retro': Icons.history_edu_rounded,
  };

  List<_AdjustmentInfo> _adjustments(AppL10n l10n) => <_AdjustmentInfo>[
        _AdjustmentInfo(
          id: 'strength',
          label: l10n.get('slider_strength'),
          icon: Icons.tune_rounded,
          value: widget.strength,
          min: 0.0, max: 1.0, defaultValue: 1.0,
          onChanged: widget.onStrengthChanged,
        ),
        _AdjustmentInfo(
          id: 'skin',
          label: l10n.get('slider_skin'),
          icon: Icons.face_rounded,
          value: widget.skinProtect,
          min: 0.0, max: 1.0, defaultValue: 0.85,
          onChanged: widget.onSkinProtectChanged,
        ),
        _AdjustmentInfo(
          id: 'luma',
          label: l10n.get('slider_luma'),
          icon: Icons.brightness_medium_rounded,
          value: widget.lumaTransfer,
          min: 0.0, max: 1.0, defaultValue: 0.3,
          onChanged: widget.onLumaChanged,
        ),
        _AdjustmentInfo(
          id: 'color',
          label: l10n.get('slider_color'),
          icon: Icons.colorize_rounded,
          value: widget.colorTransfer,
          min: 0.0, max: 2.0, defaultValue: 1.0,
          onChanged: widget.onColorChanged,
        ),
        _AdjustmentInfo(
          id: 'contrast',
          label: l10n.get('slider_contrast'),
          icon: Icons.tonality_rounded,
          value: widget.contrast,
          min: 0.5, max: 2.0, defaultValue: 1.15,
          onChanged: widget.onContrastChanged,
        ),
        _AdjustmentInfo(
          id: 'vignette',
          label: l10n.get('slider_vignette'),
          icon: Icons.vignette_rounded,
          value: widget.vignette,
          min: 0.0, max: 1.0, defaultValue: 0.3,
          onChanged: widget.onVignetteChanged,
        ),
        _AdjustmentInfo(
          id: 'grain',
          label: l10n.get('slider_grain'),
          icon: Icons.grain_rounded,
          value: widget.grain,
          min: 0.0, max: 0.5, defaultValue: 0.1,
          onChanged: widget.onGrainChanged,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final isReady = widget.hasTarget && widget.hasRef;

    return Column(
      children: <Widget>[
        // ── Workflow Progress Strip ──────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s16,
            AppTokens.s14,
            AppTokens.s16,
            0,
          ),
          child: WorkflowProgressStrip(
            sourceReady: widget.hasTarget && widget.hasRef,
            styleSelected: true, // always a style is "selected" (has default)
            refineActive: widget.state == EditorState.result,
          ),
        ),
        const SizedBox(height: AppTokens.s12),

        // ── Tab Navigation ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s16,
            0,
            AppTokens.s16,
            0,
          ),
          child: StudioCategoryMenu(
            selectedCategory: _activeCategory,
            isHorizontal: true,
            onCategorySelected: (category) {
              HapticFeedback.lightImpact();
              setState(() {
                _activeCategory = category;
                _activeSliderLabel = null;
              });
            },
          ),
        ),

        // ── Category Body ────────────────────────────────────
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey<String>(
                '${_activeCategory.name}:${_activeSliderLabel ?? 'view'}',
              ),
              child: _buildCategoryBody(l10n),
            ),
          ),
        ),

        // ── Footer Apply Button ──────────────────────────────
        _buildFooter(l10n, isReady),
      ],
    );
  }

  Widget _buildCategoryBody(AppL10n l10n) {
    switch (_activeCategory) {
      case EditorToolCategory.source:
        return _buildSourceCategory(l10n);
      case EditorToolCategory.style:
        return _buildStyleCategory(l10n);
      case EditorToolCategory.refine:
        return _buildRefineCategory(l10n);
    }
  }

  Widget _buildSourceCategory(AppL10n l10n) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s16,
        AppTokens.s16,
        AppTokens.s16,
        AppTokens.s8,
      ),
      children: <Widget>[
        SectionHeader(
          title: l10n.get('section_sources'),
          subtitle: l10n.get('section_sources_desc'),
          icon: Icons.photo_library_rounded,
        ),
        const SizedBox(height: AppTokens.s12),

        // ── Full-width source picker cards ────────────────
        SourcePickerCard(
          label: l10n.get('your_photo'),
          isReady: widget.hasTarget,
          icon: Icons.add_photo_alternate_rounded,
          color: AppTokens.primary,
          onTap: widget.onPickTarget,
          statusLabel: widget.hasTarget
              ? l10n.get('status_ready')
              : l10n.get('status_missing'),
        ),
        const SizedBox(height: AppTokens.s10),
        SourcePickerCard(
          label: l10n.get('filter_ref'),
          isReady: widget.hasRef,
          icon: Icons.color_lens_rounded,
          color: AppTokens.info,
          onTap: widget.onPickRef,
          statusLabel: widget.hasRef
              ? l10n.get('status_ready')
              : l10n.get('status_missing'),
        ),

        const SizedBox(height: AppTokens.s20),
        SectionHeader(
          title: l10n.get('section_masking'),
          subtitle: l10n.get('section_masking_desc'),
          icon: Icons.auto_awesome_rounded,
        ),
        const SizedBox(height: AppTokens.s12),
        AiModeToggleCard(
          useAI: widget.useAI,
          onToggle: widget.isBusy ? null : widget.onAIToggle,
          label: l10n.get('ai_mode_label'),
          subLabel: l10n.get('ai_mode_sub'),
        ),
        const SizedBox(height: AppTokens.s10),
        ManualMaskCard(
          isReady: widget.hasManualMask,
          isLocked: !widget.useAI || widget.isBusy,
          onTap: widget.onManualSelect,
          title: l10n.get('manual_select'),
          lockedLabel: widget.isBusy
              ? l10n.get('editor_state_processing')
              : l10n.get('manual_locked'),
          readyLabel: l10n.get('manual_ready'),
          idleLabel: l10n.get('manual_draw'),
        ),
      ],
    );
  }

  Widget _buildStyleCategory(AppL10n l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use horizontal filmstrip for narrower panels (mobile/tablet),
        // fall back to 3-column grid on desktop-width panels.
        final useFilmstrip = constraints.maxWidth < 480;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s16,
                AppTokens.s16,
                AppTokens.s16,
                AppTokens.s12,
              ),
              child: SectionHeader(
                title: l10n.get('section_themes'),
                subtitle: l10n.get('section_themes_desc'),
                icon: Icons.auto_awesome_motion_rounded,
              ),
            ),

            if (useFilmstrip) ...<Widget>[
              // Horizontal scrollable filmstrip
              SizedBox(
                height: 112,
                child: ListView.separated(
                  controller: widget.scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s16),
                  itemCount: kStyleKeys.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppTokens.s10),
                  itemBuilder: (context, index) {
                    final style = kStyleKeys[index];
                    final isSelected = widget.selectedStyle == style;
                    return SizedBox(
                      width: 90,
                      child: StyleOptionCard(
                        label: l10n.get(style),
                        icon: _styleIcons[style] ?? Icons.style_rounded,
                        isSelected: isSelected,
                        onTap: widget.isBusy
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                widget.onStyleChanged(style);
                              },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTokens.s8),
              // Selected style spotlight
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s16),
                child: _SelectedStyleBanner(
                  styleKey: widget.selectedStyle,
                  icon: _styleIcons[widget.selectedStyle] ??
                      Icons.style_rounded,
                  label: l10n.get(widget.selectedStyle),
                  l10n: l10n,
                ),
              ),
            ] else ...<Widget>[
              Expanded(
                child: ListView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.s16,
                    0,
                    AppTokens.s16,
                    AppTokens.s8,
                  ),
                  children: <Widget>[
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: AppTokens.s10,
                        mainAxisSpacing: AppTokens.s10,
                        childAspectRatio: 0.88,
                      ),
                      itemCount: kStyleKeys.length,
                      itemBuilder: (context, index) {
                        final style = kStyleKeys[index];
                        final isSelected = widget.selectedStyle == style;
                        return StyleOptionCard(
                          label: l10n.get(style),
                          icon: _styleIcons[style] ?? Icons.style_rounded,
                          isSelected: isSelected,
                          onTap: widget.isBusy
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  widget.onStyleChanged(style);
                                },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRefineCategory(AppL10n l10n) {
    final adjustments = _adjustments(l10n);
    final activeAdjustment =
        adjustments.where((item) => item.id == _activeSliderLabel).firstOrNull;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s16,
        AppTokens.s16,
        AppTokens.s16,
        AppTokens.s8,
      ),
      children: <Widget>[
        SectionHeader(
          title: l10n.get('section_adjust'),
          subtitle: l10n.get('section_adjust_desc'),
          icon: Icons.tune_rounded,
        ),
        const SizedBox(height: AppTokens.s14),

        // Active slider overlay (contextual, shown at top)
        if (activeAdjustment != null) ...<Widget>[
          ContextualSliderOverlay(
            label: activeAdjustment.label,
            value: activeAdjustment.value,
            min: activeAdjustment.min,
            max: activeAdjustment.max,
            icon: activeAdjustment.icon,
            onChanged:
                widget.isBusy ? (_) {} : activeAdjustment.onChanged,
            onClose: () => setState(() => _activeSliderLabel = null),
          ),
          const SizedBox(height: AppTokens.s14),
        ],

        // Inline sliders — always visible, no two-tap required
        ...adjustments.map((adjustment) {
          final isActive = _activeSliderLabel == adjustment.id;
          return _InlineAdjustRow(
            info: adjustment,
            isActive: isActive,
            isDisabled: widget.isBusy,
            onTap: () => setState(() =>
                _activeSliderLabel =
                    isActive ? null : adjustment.id),
            onChanged: widget.isBusy
                ? (_) {}
                : adjustment.onChanged,
          );
        }),

        const SizedBox(height: AppTokens.s12),
        InspectorHintCard(
          icon: Icons.lightbulb_outline_rounded,
          accent: AppTokens.gold,
          title: l10n.get('adjust_desc'),
          description: l10n.get('manual_select_hint'),
        ),
      ],
    );
  }

  Widget _buildFooter(AppL10n l10n, bool isReady) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.card.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(color: AppTokens.border.withValues(alpha: 0.25)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          EnterpriseApplyBtn(
            label: l10n.get('apply_btn'),
            icon: Icons.auto_awesome_rounded,
            isReady: isReady,
            isBusy: widget.isBusy,
            onTap: widget.onApply,
          ),
          if (!isReady && !widget.isBusy) ...<Widget>[
            const SizedBox(height: AppTokens.s8),
            Text(
              l10n.get('apply_missing_hint'),
              textAlign: TextAlign.center,
              style: AppTokens.caption.copyWith(
                color: AppTokens.text2,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Selected Style Banner — compact info strip in filmstrip mode
// ─────────────────────────────────────────────────────────────
class _SelectedStyleBanner extends StatelessWidget {
  final String styleKey;
  final IconData icon;
  final String label;
  final AppL10n l10n;
  const _SelectedStyleBanner({
    required this.styleKey,
    required this.icon,
    required this.label,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s14, vertical: AppTokens.s10),
      decoration: BoxDecoration(
        color: AppTokens.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTokens.r14),
        border: Border.all(
          color: AppTokens.primary.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTokens.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppTokens.r10),
            ),
            child: Icon(icon, color: AppTokens.primary, size: 17),
          ),
          const SizedBox(width: AppTokens.s10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.get('section_themes').toUpperCase(),
                  style: AppTokens.caption.copyWith(
                    color: AppTokens.primary,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  label,
                  style: AppTokens.labelBold.copyWith(
                    color: AppTokens.text,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTokens.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppTokens.rFull),
            ),
            child: Text(
              'SELECTED',
              style: TextStyle(
                color: AppTokens.primary,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Inline Adjust Row — compact slider row for Refine tab
// ─────────────────────────────────────────────────────────────
class _InlineAdjustRow extends StatelessWidget {
  final _AdjustmentInfo info;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback onTap;
  final ValueChanged<double> onChanged;

  const _InlineAdjustRow({
    required this.info,
    required this.isActive,
    required this.isDisabled,
    required this.onTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        ((info.value - info.min) / (info.max - info.min) * 100)
            .clamp(0, 100)
            .round();
    final Color accent =
        isActive ? AppTokens.gold : (info.hasModifications ? AppTokens.primary : AppTokens.text2);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: AppTokens.s8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: BoxDecoration(
        color: isActive
            ? accent.withValues(alpha: 0.08)
            : AppTokens.card.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppTokens.r14),
        border: Border.all(
          color: isActive
              ? accent.withValues(alpha: 0.4)
              : (info.hasModifications
                  ? AppTokens.primary.withValues(alpha: 0.2)
                  : AppTokens.border.withValues(alpha: 0.6)),
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Header row — tap to select/focus
          GestureDetector(
            onTap: isDisabled ? null : onTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: <Widget>[
                Icon(info.icon, size: 15, color: accent),
                const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: Text(
                    info.label,
                    style: AppTokens.labelBold.copyWith(
                      color: accent,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (info.hasModifications)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: AppTokens.s6),
                    decoration: BoxDecoration(
                      color: AppTokens.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTokens.r8),
                  ),
                  child: Text(
                    '$progress%',
                    style: AppTokens.caption.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Always-visible compact slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: isActive ? 4.0 : 2.5,
              thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: isActive ? 8.0 : 5.5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: accent,
              inactiveTrackColor: AppTokens.border.withValues(alpha: 0.5),
              thumbColor: isActive ? Colors.white : accent,
              overlayColor: accent.withValues(alpha: 0.14),
            ),
            child: Slider(
              value: info.value,
              min: info.min,
              max: info.max,
              onChanged: isDisabled ? null : onChanged,
              onChangeEnd: (_) => HapticFeedback.selectionClick(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Adjustment data model
// ─────────────────────────────────────────────────────────────
class _AdjustmentInfo {
  final String id;
  final String label;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final double defaultValue;
  final ValueChanged<double> onChanged;

  const _AdjustmentInfo({
    required this.id,
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.onChanged,
  });

  bool get hasModifications => (value - defaultValue).abs() > 0.001;
}
