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
  EditorToolCategory _activeCategory = EditorToolCategory.setup;
  String? _activeSliderLabel;

  static const List<String> kStyles = <String>[
    'Luma Master',
    'Pro Studio',
    'Color Theft',
    'Theme Theft',
    'Cinematic',
    'Cyber Neon',
    'Color Splash',
    'HDR Magic',
    'Sepia Retro',
  ];

  static const Map<String, IconData> _styleIcons = <String, IconData>{
    'Luma Master': Icons.light_mode_rounded,
    'Pro Studio': Icons.star_rounded,
    'Color Theft': Icons.palette_rounded,
    'Theme Theft': Icons.style_rounded,
    'Cinematic': Icons.movie_rounded,
    'Cyber Neon': Icons.bolt_rounded,
    'Color Splash': Icons.water_drop_rounded,
    'HDR Magic': Icons.hdr_on_rounded,
    'Sepia Retro': Icons.camera_alt_rounded,
  };

  List<_AdjustmentInfo> _adjustments(AppL10n l10n) => <_AdjustmentInfo>[
        _AdjustmentInfo(
          id: 'strength',
          label: l10n.get('slider_strength'),
          icon: Icons.monitor_weight_outlined,
          value: widget.strength,
          min: 0.0,
          max: 1.0,
          defaultValue: 1.0,
          onChanged: widget.onStrengthChanged,
        ),
        _AdjustmentInfo(
          id: 'skin',
          label: l10n.get('slider_skin'),
          icon: Icons.face_rounded,
          value: widget.skinProtect,
          min: 0.0,
          max: 1.0,
          defaultValue: 0.85,
          onChanged: widget.onSkinProtectChanged,
        ),
        _AdjustmentInfo(
          id: 'luma',
          label: l10n.get('slider_luma'),
          icon: Icons.brightness_6_rounded,
          value: widget.lumaTransfer,
          min: 0.0,
          max: 1.0,
          defaultValue: 0.3,
          onChanged: widget.onLumaChanged,
        ),
        _AdjustmentInfo(
          id: 'color',
          label: l10n.get('slider_color'),
          icon: Icons.color_lens_outlined,
          value: widget.colorTransfer,
          min: 0.0,
          max: 2.0,
          defaultValue: 1.0,
          onChanged: widget.onColorChanged,
        ),
        _AdjustmentInfo(
          id: 'contrast',
          label: l10n.get('slider_contrast'),
          icon: Icons.contrast_rounded,
          value: widget.contrast,
          min: 0.5,
          max: 2.0,
          defaultValue: 1.15,
          onChanged: widget.onContrastChanged,
        ),
        _AdjustmentInfo(
          id: 'vignette',
          label: l10n.get('slider_vignette'),
          icon: Icons.camera_rounded,
          value: widget.vignette,
          min: 0.0,
          max: 1.0,
          defaultValue: 0.3,
          onChanged: widget.onVignetteChanged,
        ),
        _AdjustmentInfo(
          id: 'grain',
          label: l10n.get('slider_grain'),
          icon: Icons.grain_rounded,
          value: widget.grain,
          min: 0.0,
          max: 0.5,
          defaultValue: 0.1,
          onChanged: widget.onGrainChanged,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);



    return Column(
      children: <Widget>[
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  AppTokens.surface,
                  Color.lerp(AppTokens.surface, AppTokens.card2, 0.32) ??
                      AppTokens.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(AppTokens.r24),
              border: widget.isHorizontalScrollable
                  ? Border(top: BorderSide(color: AppTokens.border))
                  : Border.all(color: AppTokens.border),
            ),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: KeyedSubtree(
                      key: ValueKey<String>(
                        '${_activeCategory.name}:${_activeSliderLabel ?? 'base'}',
                      ),
                      child: _buildCategoryBody(l10n),
                    ),
                  ),
                ),
                _buildFooter(context, l10n),
              ],
            ),
          ),
        ),
        StudioCategoryMenu(
          selectedCategory: _activeCategory,
          isHorizontal: widget.isHorizontalScrollable,
          onCategorySelected: (category) {
            HapticFeedback.selectionClick();
            setState(() {
              _activeCategory = category;
              _activeSliderLabel = null;
            });
          },
        ),
      ],
    );
  }


  Widget _buildCategoryBody(AppL10n l10n) {
    switch (_activeCategory) {
      case EditorToolCategory.setup:
        return _buildSetupCategory(l10n);
      case EditorToolCategory.theme:
        return _buildThemeCategory(l10n);
      case EditorToolCategory.adjust:
        return _buildAdjustCategory(l10n);
    }
  }

  Widget _buildSetupCategory(AppL10n l10n) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(AppTokens.s16),
      children: <Widget>[
        SectionHeader(
          title: l10n.get('section_sources'),
          subtitle: l10n.get('section_sources_desc'),
          icon: Icons.folder_rounded,
        ),
        const SizedBox(height: AppTokens.s16),
        Row(
          children: <Widget>[
            Expanded(
              child: SourcePickerCard(
                label: l10n.get('your_photo'),
                statusLabel: widget.hasTarget
                    ? l10n.get('status_ready')
                    : l10n.get('status_missing'),
                isReady: widget.hasTarget,
                icon: Icons.person_rounded,
                color: AppTokens.primary,
                onTap: widget.onPickTarget,
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: SourcePickerCard(
                label: l10n.get('filter_ref'),
                statusLabel: widget.hasRef
                    ? l10n.get('status_ready')
                    : l10n.get('status_missing'),
                isReady: widget.hasRef,
                icon: Icons.color_lens_rounded,
                color: AppTokens.info,
                onTap: widget.onPickRef,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s24),
        SectionHeader(
          title: l10n.get('section_masking'),
          subtitle: l10n.get('section_masking_desc'),
          icon: Icons.masks_rounded,
        ),
        const SizedBox(height: AppTokens.s12),
        AiModeToggleCard(
          useAI: widget.useAI,
          onToggle: widget.isBusy ? null : widget.onAIToggle,
          label: l10n.get('ai_mode_label'),
          subLabel: l10n.get('ai_mode_sub'),
        ),
        const SizedBox(height: AppTokens.s12),
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
        const SizedBox(height: AppTokens.s12),
        InspectorHintCard(
          icon: Icons.info_outline_rounded,
          accent: AppTokens.info,
          title: l10n.get('workspace_tip'),
          description: l10n.get('manual_select_hint'),
        ),
      ],
    );
  }

  Widget _buildThemeCategory(AppL10n l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 360 ? 2 : 1;

        return ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.all(AppTokens.s16),
          children: <Widget>[
            SectionHeader(
              title: l10n.get('section_themes'),
              subtitle: l10n.get('section_themes_desc'),
              icon: Icons.style_rounded,
            ),
            const SizedBox(height: AppTokens.s16),
            StyleSpotlightCard(
              title: widget.selectedStyle,
              subtitle: widget.useAI
                  ? l10n.get('current_style_ai_on')
                  : l10n.get('current_style_ai_off'),
              icon: _styleIcons[widget.selectedStyle] ?? Icons.style_rounded,
              accent: AppTokens.info,
            ),
            const SizedBox(height: AppTokens.s16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppTokens.s10,
                mainAxisSpacing: AppTokens.s10,
                childAspectRatio: columns == 1 ? 2.8 : 2.1,
              ),
              itemCount: kStyles.length,
              itemBuilder: (context, index) {
                final style = kStyles[index];
                final isSelected = widget.selectedStyle == style;
                return StyleOptionCard(
                  label: style,
                  icon: _styleIcons[style] ?? Icons.tune_rounded,
                  isSelected: isSelected,
                  onTap: widget.isBusy
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          widget.onStyleChanged(style);
                        },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdjustCategory(AppL10n l10n) {
    final adjustments = _adjustments(l10n);
    final activeAdjustment = adjustments.where(
      (item) => item.id == _activeSliderLabel,
    ).firstOrNull;
    final modified =
        adjustments.where((item) => item.hasModifications).toList();

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(AppTokens.s16),
      children: <Widget>[
        SectionHeader(
          title: l10n.get('section_adjust'),
          subtitle: l10n.get('section_adjust_desc'),
          icon: Icons.tune_rounded,
        ),
        const SizedBox(height: AppTokens.s16),
        if (activeAdjustment != null) ...<Widget>[
          ContextualSliderOverlay(
            label: activeAdjustment.label,
            value: activeAdjustment.value,
            min: activeAdjustment.min,
            max: activeAdjustment.max,
            icon: activeAdjustment.icon,
            onChanged: widget.isBusy ? (_) {} : activeAdjustment.onChanged,
            onClose: () => setState(() => _activeSliderLabel = null),
          ),
          const SizedBox(height: AppTokens.s16),
        ] else
          InspectorHintCard(
            icon: Icons.tune_rounded,
            accent: AppTokens.gold,
            title: l10n.get('adjust_desc'),
            description: modified.isEmpty
                ? l10n.get('adjust_none')
                : '${modified.length} ${l10n.get('adjust_active')}',
          ),
        const SizedBox(height: AppTokens.s16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: widget.isHorizontalScrollable ? 4 : 3,
          crossAxisSpacing: AppTokens.s10,
          mainAxisSpacing: AppTokens.s12,
          childAspectRatio: widget.isHorizontalScrollable ? 1.05 : 0.96,
          children: adjustments.map((adjustment) {
            return AdjustToolButton(
              label: adjustment.label,
              icon: adjustment.icon,
              hasModifications: adjustment.hasModifications,
              isSelected: _activeSliderLabel == adjustment.id,
              onTap: widget.isBusy
                  ? null
                  : () => setState(() => _activeSliderLabel = adjustment.id),
            );
          }).toList(),
        ),
        const SizedBox(height: AppTokens.s16),
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: modified.isEmpty
              ? <Widget>[
                  StatusInfoPill(
                    label: l10n.get('adjust_none'),
                    color: AppTokens.text2,
                  ),
                ]
              : modified
                  .map(
                    (adjustment) => StatusInfoPill(
                      label: '${adjustment.label} ${adjustment.progressLabel}',
                      color: _activeSliderLabel == adjustment.id
                          ? AppTokens.gold
                          : AppTokens.primary,
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, AppL10n l10n) {
    final helperText = widget.isBusy
        ? l10n.get('apply_processing_hint')
        : widget.hasTarget && widget.hasRef
            ? l10n.get('apply_ready_hint')
            : l10n.get('apply_missing_hint');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s16,
        AppTokens.s12,
        AppTokens.s16,
        AppTokens.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          EnterpriseApplyBtn(
            label: l10n.get('apply_btn'),
            icon: Icons.auto_fix_high_rounded,
            isReady: widget.hasTarget && widget.hasRef,
            isBusy: widget.isBusy,
            onTap: widget.onApply,
          ),
          const SizedBox(height: AppTokens.s10),
          Text(
            helperText,
            style: AppTokens.caption.copyWith(
              color: AppTokens.text2,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

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

  String get progressLabel {
    final percent = max == min ? 0 : (((value - min) / (max - min)) * 100);
    return '${percent.clamp(0, 100).round()}%';
  }
}
