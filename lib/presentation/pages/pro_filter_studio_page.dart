// pro_filter_studio_page.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

// ─── Project imports ──────────────────────────────────────────────
import 'package:lama/core/i18n/t.dart';
import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/core/i18n/locale_controller.dart';
import 'package:lama/core/performance/render_capture_service.dart';
import 'package:lama/features/filter_studio/data/services/filter_studio_ai_analysis_service.dart';
import 'package:lama/features/filter_studio/domain/entities/app_preset.dart';
import 'package:lama/features/filter_studio/domain/entities/filter_params.dart';
import 'package:lama/features/filter_studio/domain/entities/preset_config.dart';
import 'package:lama/features/filter_studio/domain/entities/filter_studio_ai_insight.dart';
import 'package:lama/features/filter_studio/presentation/bloc/filter_studio_bloc.dart';
import 'package:lama/features/filter_studio/presentation/bloc/filter_studio_event.dart';
import 'package:lama/features/filter_studio/presentation/models/filter_studio_ai_style_match.dart';
import 'package:lama/features/filter_studio/presentation/models/filter_studio_style_preset.dart';
import 'package:lama/features/filter_studio/presentation/bloc/filter_studio_state.dart';
import 'package:lama/features/filter_studio/presentation/pages/filter_studio_scope.dart';
import 'package:lama/features/filter_studio/presentation/services/filter_studio_ai_style_matcher.dart';
import 'package:lama/features/filter_studio/presentation/services/filter_studio_style_catalog.dart';
import 'package:lama/core/ui/AppTokens.dart';
import 'package:lama/core/ui/app_theme.dart';
import 'package:lama/presentation/pages/Pro.dart';
import 'package:lama/presentation/pages/ProResultPage.dart';
import 'package:lama/presentation/pages/ProcessingOverlay_ProFilterStudioPage.dart';
import 'package:lama/presentation/widgets/artistic_canvas.dart';
import 'package:lama/presentation/widgets/bottom_controls.dart';
import 'package:lama/presentation/widgets/filter_studio/filter_studio_shell.dart';

// ─── Pro files (same folder — relative imports) ───────────────────

class ProFilterStudioPage extends StatefulWidget {
  const ProFilterStudioPage({
    super.key,
  });

  @override
  State<ProFilterStudioPage> createState() => _ProFilterStudioPageState();
}

class _ProFilterStudioPageState extends State<ProFilterStudioPage> {
  static const _renderCaptureService = RenderCaptureService();
  static const _aiAnalysisService = FilterStudioAiAnalysisService();
  static const _aiStyleMatcher = FilterStudioAiStyleMatcher();
  final GlobalKey _repaintKey = GlobalKey();

  bool _showResult = false;
  Uint8List? _imageBytes;
  FilterStudioAiInsight? _aiInsight;
  bool _isAnalyzingInsight = false;
  int _insightRequestId = 0;
  String? _selectedStyleId;

  late final List<FilterStudioStylePreset> _styleLibrary =
      FilterStudioStyleCatalog.presets;

  @override
  void initState() {
    super.initState();
  }

  T get _t => T.from(context);
  AppL10n get l10n => AppL10n.of(context);
  Lang get _lang => l10n.isAr ? Lang.ar : Lang.en;

  String _aiButtonLabel(AppL10n l10n) {
    final insight = _aiInsight;
    if (_isAnalyzingInsight) {
      return l10n.get('ai_status_running');
    }
    if (_imageBytes == null) {
      return 'AI';
    }
    if (insight == null) {
      return l10n.get('ai_auto_fix');
    }
    return '${l10n.get('ai_ready_short')} ${(insight.confidence * 100).round()}%';
  }

  String _aiStatusLabel(AppL10n l10n) {
    if (_isAnalyzingInsight) {
      return l10n.get('ai_status_running');
    }
    if (_aiInsight != null) {
      return l10n.get('ai_status_ready');
    }
    return l10n.get('ai_manual');
  }

  FilterStudioStylePreset? get _selectedStyle {
    final selectedStyleId = _selectedStyleId;
    if (selectedStyleId == null) {
      return null;
    }
    for (final style in _styleLibrary) {
      if (style.id == selectedStyleId) {
        return style;
      }
    }
    return null;
  }

  List<FilterStudioAiStyleMatch> get _aiStyleMatches {
    final insight = _aiInsight;
    if (insight == null) {
      return const <FilterStudioAiStyleMatch>[];
    }
    return _aiStyleMatcher.match(
      insight: insight,
      styles: _styleLibrary,
    );
  }

  String _currentLookLabel(
    FilterStudioState state,
    Map<AppPreset, PresetConfig> presets,
    AppL10n l10n,
  ) {
    final selectedStyle = _selectedStyle;
    if (selectedStyle != null) {
      return selectedStyle.name(l10n.locale.languageCode == 'ar' ? Lang.ar : Lang.en);
    }
    return presets[state.selectedPreset]?.name ?? l10n.get('normal');
  }

  void _handleBack(BuildContext context, FilterStudioState state) {
    if (state.imageFile != null) {
      _resetStudioSession();
      context.read<FilterStudioBloc>().add(const ClearImage());
    } else {
      Navigator.of(context).pop();
    }
  }

  FilterStudioLayoutMode _layoutModeForWidth(double width) {
    if (width >= 1320) {
      return FilterStudioLayoutMode.expanded;
    }
    if (width >= 860) {
      return FilterStudioLayoutMode.medium;
    }
    return FilterStudioLayoutMode.compact;
  }

  Color _currentAccent(
    FilterStudioState state,
    Map<AppPreset, PresetConfig> presets,
  ) {
    final selectedStyle = _selectedStyle;
    if (selectedStyle != null) {
      return selectedStyle.accent;
    }
    return presets[state.selectedPreset]?.auraColor ??
        presets[state.selectedPreset]?.colorOverlay ??
        AppTokens.primary;
  }

  List<FilterStudioInspectorTab> _buildInspectorTabs(
    BuildContext context,
    FilterStudioState state,
    Map<AppPreset, PresetConfig> presets,
    AppL10n l10n,
  ) {
    final bloc = context.read<FilterStudioBloc>();
    final isAr = l10n.locale.languageCode == 'ar';

    return [
      FilterStudioInspectorTab(
        label: l10n.get('ai_tab'),
        icon: Icons.auto_awesome_rounded,
        child: AiStudioTab(
          l10n: l10n,
          hasImage: state.imageFile != null,
          insight: _aiInsight,
          isLoading: _isAnalyzingInsight,
          presets: presets,
          styleMatches: _aiStyleMatches,
          onAnalyze: () => _runAiAnalysis(context, autoApply: true),
          onApplyInsight: () => _applyAiInsight(context),
          onSmartFocus: () => _applySmartFocus(context, state),
          onCinemaBoost: () => _applyCinemaBoost(context, state),
          onCleanPro: () => _applyCleanPro(context, state),
          onApplyPreset: (preset) => _selectCorePreset(context, preset),
          onApplyStyle: (style) => _applyCatalogStyle(context, style),
        ),
      ),
      FilterStudioInspectorTab(
        label: l10n.get('presets'),
        icon: Icons.auto_fix_high_rounded,
        child: PresetsTab(
          l10n: l10n,
          presets: presets,
          selectedPreset: state.selectedPreset,
          onPresetSelected: (preset) => _selectCorePreset(context, preset),
          styleLibrary: _styleLibrary,
          selectedStyleId: _selectedStyleId,
          onStyleSelected: (style) => _applyCatalogStyle(context, style),
        ),
      ),
      FilterStudioInspectorTab(
        label: l10n.get('adjust'),
        icon: Icons.tune_rounded,
        child: AdjustTab(
          l10n: l10n,
          exposure: state.params.exposure,
          brightness: state.params.brightness,
          contrast: state.params.contrast,
          saturation: state.params.saturation,
          warmth: state.params.warmth,
          tint: state.params.tint,
          highlights: state.params.highlights,
          shadows: state.params.shadows,
          clarity: state.params.clarity,
          dehaze: state.params.dehaze,
          sharpen: state.params.sharpen,
          vignette: state.params.vignette,
          vignetteSize: state.params.vignetteSize,
          replaceBackground: state.params.replaceBackground,
          canUndo: state.canUndoAdjust,
          canRedo: state.canRedoAdjust,
          onUndo: () => bloc.add(const AdjustUndoRequested()),
          onRedo: () => bloc.add(const AdjustRedoRequested()),
          onReset: () => bloc.add(const AdjustResetRequested()),
          onCompareHoldStart: () => bloc.add(const CompareHoldChanged(true)),
          onCompareHoldEnd: () => bloc.add(const CompareHoldChanged(false)),
          onParamChanged: (key, value) =>
              bloc.add(FilterParamChanged(key, value)),
        ),
      ),
      FilterStudioInspectorTab(
        label: l10n.get('effects'),
        icon: Icons.blur_on_rounded,
        child: EffectsTab(
          l10n: l10n,
          blur: state.params.blur,
          aura: state.params.aura,
          auraColor: state.params.auraColor,
          grain: state.params.grain,
          scanlines: state.params.scanlines,
          glitch: state.params.glitch,
          ghost: state.params.ghost,
          colorPop: state.params.colorPop,
          onParamChanged: (key, value) =>
              bloc.add(FilterParamChanged(key, value)),
        ),
      ),
      FilterStudioInspectorTab(
        label: l10n.get('overlays'),
        icon: Icons.layers_rounded,
        child: OverlaysTab(
          l10n: l10n,
          showDateStamp: state.params.showDateStamp,
          cinemaMode: state.params.cinemaMode,
          polaroidFrame: state.params.polaroidFrame,
          vignette: state.params.vignette,
          lightLeakIndex: state.params.lightLeakIndex,
          prismOverlay: state.params.prismOverlay,
          dustOverlay: state.params.dustOverlay,
          onParamChanged: (key, value) =>
              bloc.add(FilterParamChanged(key, value)),
        ),
      ),
    ];
  }

  Widget _buildWorkspace(
    BuildContext context,
    FilterStudioState state,
    Map<AppPreset, PresetConfig> presets,
    T t,
    FilterStudioLayoutMode mode,
    Color accent,
  ) {
    final l10n = AppL10n.of(context);
    final tabs = _buildInspectorTabs(context, state, presets, l10n);
    final currentLookLabel = _currentLookLabel(state, presets, l10n);

    final preview = FilterStudioPreviewPane(
      t: t,
      mode: mode,
      accent: accent,
      state: state,
      repaintKey: _repaintKey,
      currentLookLabel: currentLookLabel,
      aiStatusLabel: _aiStatusLabel(l10n),      totalLooks: _styleLibrary.length,
      onUndo: () =>
          context.read<FilterStudioBloc>().add(const AdjustUndoRequested()),
      onRedo: () =>
          context.read<FilterStudioBloc>().add(const AdjustRedoRequested()),
      onCompareStart: () =>
          context.read<FilterStudioBloc>().add(const CompareHoldChanged(true)),
      onCompareEnd: () =>
          context.read<FilterStudioBloc>().add(const CompareHoldChanged(false)),
      onAiAuto: () => _runAiAnalysis(context, autoApply: true),
      onCinematic: () => _selectCorePreset(context, AppPreset.cinematic),
      onRandom: () => _applyRandomStyle(context),
      onDepthBlur: () => _applyDepthBlur(context, state),
    );

    final inspector = FilterStudioInspector(
      t: t,
      mode: mode,
      accent: accent,
      currentLookLabel: currentLookLabel,
      aiStatusLabel: _aiStatusLabel(l10n),      hasPersonMask: state.personMask != null,
      selectedIndex: state.params.selectedTabIndex,
      tabs: tabs,
      onTabChanged: (index) =>
          context.read<FilterStudioBloc>().add(TabChanged(index)),
    );

    if (mode == FilterStudioLayoutMode.compact) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final inspectorHeight = math.min(
            520.0,
            math.max(300.0, constraints.maxHeight * 0.5),
          );
          final previewBottomPadding = inspectorHeight * 0.72;

          return Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(bottom: previewBottomPadding),
                  child: preview,
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: inspectorHeight,
                    child: inspector,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    final inspectorWidth =
        mode == FilterStudioLayoutMode.expanded ? 420.0 : 360.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: mode == FilterStudioLayoutMode.expanded ? 9 : 8,
          child: preview,
        ),
        SizedBox(width: AppTokens.s16),
        SizedBox(width: inspectorWidth, child: inspector),
      ],
    );
  }

  // ─── Presets ────────────────────────────────────────────────────
  Map<AppPreset, PresetConfig> get _presets {
    final t = _t;
    return {
      AppPreset.original:
          PresetConfig(name: t.of('normal'), icon: Icons.adjust_rounded),
      AppPreset.cinematic: PresetConfig(
        name: t.of('cinematic_look'),
        icon: Icons.movie_creation_outlined,
        contrast: 1.16,
        saturation: 1.02,
        exposure: 0.04,
        brightness: 0.02,
        warmth: 0.04,
        grain: 0.12,
        scanlines: 0.06,
        cinemaMode: true,
        vignette: 0.18,
        dustOverlay: 0.08,
        auraColor: AppTokens.warning,
        colorOverlay: const Color(0x0F10233F),
      ),
      AppPreset.dreamy: PresetConfig(
        name: t.of('dreamy'),
        icon: Icons.cloud_rounded,
        blur: 5.0,
        grain: 0.10,
        saturation: 1.08,
        aura: 0.18,
        auraColor: Colors.purpleAccent,
        colorOverlay: Colors.purpleAccent.withOpacity(0.10),
      ),
      AppPreset.motion: PresetConfig(
        name: t.of('motion'),
        icon: Icons.blur_linear_rounded,
        blur: 2.0,
        grain: 0.15,
        ghost: true,
        contrast: 1.12,
        exposure: 0.03,
        auraColor: Colors.blueAccent,
      ),
      AppPreset.vintage: PresetConfig(
        name: t.of('vintage'),
        icon: Icons.camera_roll_rounded,
        grain: 0.28,
        scanlines: 0.22,
        saturation: 1.06,
        warmth: 0.10,
        vignette: 0.10,
        lightLeakIndex: 1,
        dustOverlay: 0.10,
        auraColor: AppTokens.warning,
        colorOverlay: Colors.orange.withOpacity(0.10),
      ),
      AppPreset.noir: PresetConfig(
        name: t.of('noir'),
        icon: Icons.movie_filter_rounded,
        contrast: 1.18,
        saturation: 0.30,
        grain: 0.22,
        vignette: 0.24,
        cinemaMode: true,
        auraColor: AppTokens.text2,
        colorPop: true,
      ),
      AppPreset.neon: PresetConfig(
        name: t.of('neon'),
        icon: Icons.flare_rounded,
        contrast: 1.10,
        saturation: 1.16,
        blur: 6.0,
        aura: 0.55,
        tint: 0.06,
        auraColor: Colors.pinkAccent,
        colorOverlay: Colors.blue.withOpacity(0.18),
      ),
      AppPreset.cyber: PresetConfig(
        name: t.of('cyber'),
        icon: Icons.electrical_services,
        contrast: 1.16,
        saturation: 1.18,
        grain: 0.18,
        scanlines: 0.35,
        glitch: 1.6,
        aura: 0.32,
        tint: 0.08,
        auraColor: Colors.cyanAccent,
      ),
      AppPreset.warm: PresetConfig(
        name: t.of('sunset'),
        icon: Icons.wb_sunny_rounded,
        warmth: 0.14,
        saturation: 1.06,
        blur: 1.8,
        lightLeakIndex: 1,
        auraColor: AppTokens.warning,
        colorOverlay: Colors.redAccent.withOpacity(0.10),
      ),
      AppPreset.editorial: PresetConfig(
        name: t.of('editorial'),
        icon: Icons.auto_fix_high_rounded,
        contrast: 1.08,
        saturation: 1.04,
        exposure: 0.01,
        vignette: 0.06,
        auraColor: AppTokens.primary,
      ),
      AppPreset.vaporwave: PresetConfig(
        name: t.of('vaporwave'),
        icon: Icons.bubble_chart_rounded,
        contrast: 1.12,
        saturation: 1.20,
        tint: 0.08,
        blur: 1.8,
        aura: 0.34,
        glitch: 1.0,
        lightLeakIndex: 2,
        prismOverlay: 0.22,
        auraColor: Colors.pinkAccent,
        colorOverlay: const Color(0x1500D7FF),
      ),
      AppPreset.chrome: PresetConfig(
        name: t.of('chrome'),
        icon: Icons.diamond_rounded,
        contrast: 1.14,
        saturation: 1.08,
        exposure: 0.02,
        brightness: -0.01,
        vignette: 0.08,
        auraColor: AppTokens.info,
        colorOverlay: const Color(0x10FFFFFF),
      ),
      AppPreset.halo: PresetConfig(
        name: t.of('halo'),
        icon: Icons.wb_iridescent_rounded,
        contrast: 1.08,
        saturation: 1.10,
        warmth: 0.12,
        blur: 3.4,
        aura: 0.42,
        grain: 0.05,
        vignette: 0.12,
        lightLeakIndex: 1,
        prismOverlay: 0.08,
        auraColor: const Color(0xFFFFC46B),
        colorOverlay: const Color(0x18FFB06B),
      ),
      AppPreset.monoPop: PresetConfig(
        name: t.of('mono_pop'),
        icon: Icons.filter_b_and_w_rounded,
        contrast: 1.18,
        saturation: 0.18,
        grain: 0.16,
        colorPop: true,
        vignette: 0.18,
        auraColor: Colors.white,
      ),
      AppPreset.street: PresetConfig(
        name: t.of('street'),
        icon: Icons.flash_on_rounded,
        contrast: 1.18,
        saturation: 1.10,
        grain: 0.14,
        scanlines: 0.18,
        glitch: 0.25,
        cinemaMode: true,
        vignette: 0.18,
        lightLeakIndex: 1,
        auraColor: AppTokens.info,
        colorOverlay: const Color(0x0DFFFFFF),
      ),
    };
  }

  // ─── Actions ────────────────────────────────────────────────────
  Future<void> _pickImage(BuildContext ctx) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picked == null) {
      if (mounted) {
        setState(() => _isAnalyzingInsight = false);
      }
      return;
    }
    if (!ctx.mounted) return;
    final bytes = await File(picked.path).readAsBytes();
    if (!mounted || !ctx.mounted) {
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _imageBytes = bytes;
      _aiInsight = null;
      _isAnalyzingInsight = false;
      _selectedStyleId = null;
    });
    ctx.read<FilterStudioBloc>().add(ImagePicked(File(picked.path)));
    if (_showResult) setState(() => _showResult = false);
  }

  void _toggleLang() {
    HapticFeedback.selectionClick();
    context.read<LocaleController>().toggleLocale();
    final bytes = _imageBytes;
    if (bytes != null) {
      if (_aiInsight != null || _isAnalyzingInsight) {
        _refreshAiInsight(bytes);
      }
    }
  }

  Future<void> _runAiAnalysis(
    BuildContext context, {
    bool autoApply = true,
    bool showAiTab = false,
  }) async {
    final bytes = _imageBytes;
    if (bytes == null) {
      _showStudioSnack(context, _t.of('pick_hint'), AppTokens.danger);
      return;
    }

    HapticFeedback.mediumImpact();
    if (showAiTab) {
      context.read<FilterStudioBloc>().add(const TabChanged(0));
    }
    final insight = await _refreshAiInsight(bytes);
    if (!context.mounted || insight == null || !autoApply) {
      return;
    }
    _applyAiInsightRecipe(
      context,
      insight,
      message: _t.of('ai_auto_applied'),
      color: AppTokens.info,
    );
  }

  Future<void> _saveResult(BuildContext context) async {
    final pngBytes = await _renderCaptureService.capturePng(_repaintKey);
    if (!context.mounted) {
      return;
    }
    context.read<FilterStudioBloc>().add(SaveRequested(pngBytes));
  }

  Future<FilterStudioAiInsight?> _refreshAiInsight(Uint8List bytes) async {
    final requestId = ++_insightRequestId;

    if (mounted) {
      setState(() {
        _isAnalyzingInsight = true;
      });
    }

    try {
      final insight =
          await _aiAnalysisService.generateInsight(bytes, _lang.name);
      if (!mounted || requestId != _insightRequestId) {
        return null;
      }

      setState(() {
        _aiInsight = insight;
        _isAnalyzingInsight = false;
      });
      return insight;
    } catch (_) {
      if (!mounted || requestId != _insightRequestId) {
        return null;
      }
      setState(() => _isAnalyzingInsight = false);
      return null;
    }
  }

  void _applyRecipe(
    BuildContext context,
    FilterParams params, {
    AppPreset? preset,
    String? message,
    Color color = AppTokens.primary,
  }) {
    HapticFeedback.mediumImpact();
    setState(() => _selectedStyleId = null);
    context.read<FilterStudioBloc>().add(
          ApplyRecipe(
            params: params,
            preset: preset,
          ),
        );
    if (message != null) {
      _showStudioSnack(context, message, color);
    }
  }

  void _applyAiInsight(BuildContext context) {
    final insight = _aiInsight;
    if (insight == null) {
      return;
    }
    _applyAiInsightRecipe(
      context,
      insight,
      message: _t.of('style_applied'),
    );
  }

  void _applyAiInsightRecipe(
    BuildContext context,
    FilterStudioAiInsight insight, {
    required String message,
    Color color = AppTokens.primary,
  }) {
    _applyRecipe(
      context,
      insight.recipe,
      preset: insight.recommendedPreset,
      message: message,
      color: color,
    );
  }

  void _applyCatalogStyle(
    BuildContext context,
    FilterStudioStylePreset style,
  ) {
    HapticFeedback.mediumImpact();
    setState(() => _selectedStyleId = style.id);
    context.read<FilterStudioBloc>().add(
          ApplyRecipe(
            params: style.recipe,
          ),
        );
    _showStudioSnack(context, style.name(_lang), style.accent);
  }

  void _selectCorePreset(BuildContext context, AppPreset preset) {
    HapticFeedback.selectionClick();
    setState(() => _selectedStyleId = null);
    context.read<FilterStudioBloc>().add(ApplyPreset(preset));
  }

  void _applyDepthBlur(BuildContext context, FilterStudioState state) {
    if (state.personMask == null) {
      _showStudioSnack(
        context,
        _t.of('subject_mask_needed'),
        AppTokens.warning,
      );
      return;
    }

    final next = state.params.copyWith(
      subjectMaskEnabled: true,
      blur: (state.params.blur + 2.6).clamp(0.0, 20.0),
      aura: math.max(state.params.aura, 0.08).toDouble(),
      vignette: (state.params.vignette + 0.08).clamp(0.0, 0.8),
    );

    _applyRecipe(
      context,
      next,
      preset: state.selectedPreset,
      message: _t.of('depth_blur'),
      color: AppTokens.accent,
    );
  }

  void _applyRandomStyle(BuildContext context) {
    if (_styleLibrary.isEmpty) {
      return;
    }
    final currentId = _selectedStyleId;
    final eligible = currentId == null
        ? _styleLibrary
        : _styleLibrary.where((style) => style.id != currentId).toList();
    final styles = eligible.isEmpty ? _styleLibrary : eligible;
    final style = styles[math.Random().nextInt(styles.length)];
    _applyCatalogStyle(context, style);
  }

  void _applySmartFocus(BuildContext context, FilterStudioState state) {
    if (state.personMask == null) {
      _showStudioSnack(
        context,
        _t.of('subject_mask_needed'),
        AppTokens.warning,
      );
      return;
    }

    final next = state.params.copyWith(
      subjectMaskEnabled: true,
      contrast: (state.params.contrast + 0.06).clamp(0.5, 1.5),
      saturation: (state.params.saturation + 0.04).clamp(0.0, 2.0),
      blur: (state.params.blur + 2.2).clamp(0.0, 20.0),
      aura:
          (state.params.aura < 0.18 ? 0.18 : state.params.aura).clamp(0.0, 1.0),
      auraColor: AppTokens.info,
      colorPop: true,
      vignette: (state.params.vignette + 0.10).clamp(0.0, 0.8),
    );

    _applyRecipe(
      context,
      next,
      preset: state.selectedPreset,
      message: _t.of('smart_focus'),
      color: AppTokens.info,
    );
  }

  void _applyCinemaBoost(BuildContext context, FilterStudioState state) {
    final next = state.params.copyWith(
      subjectMaskEnabled: false,
      contrast: (state.params.contrast + 0.08).clamp(0.5, 1.5),
      grain: (state.params.grain + 0.08).clamp(0.0, 0.5),
      scanlines: (state.params.scanlines + 0.08).clamp(0.0, 0.8),
      cinemaMode: true,
      vignette: (state.params.vignette + 0.16).clamp(0.0, 0.8),
      lightLeakIndex:
          state.params.lightLeakIndex == 0 ? 1 : state.params.lightLeakIndex,
    );

    _applyRecipe(
      context,
      next,
      preset: state.selectedPreset,
      message: _t.of('cinema_boost'),
      color: AppTokens.warning,
    );
  }

  void _applyCleanPro(BuildContext context, FilterStudioState state) {
    final next = state.params.copyWith(
      subjectMaskEnabled: false,
      contrast: (state.params.contrast + 0.04).clamp(0.5, 1.5),
      saturation: state.params.saturation > 1.08
          ? (state.params.saturation - 0.06).clamp(0.0, 2.0)
          : (state.params.saturation + 0.02).clamp(0.0, 2.0),
      exposure: state.params.exposure < 0
          ? (state.params.exposure + 0.05).clamp(-1.0, 1.0)
          : state.params.exposure,
      brightness: state.params.brightness < 0
          ? (state.params.brightness + 0.03).clamp(-0.5, 0.5)
          : state.params.brightness,
      warmth: (state.params.warmth * 0.5).clamp(-1.0, 1.0),
      blur: (state.params.blur * 0.35).clamp(0.0, 20.0),
      aura: state.personMask == null
          ? 0.0
          : (state.params.aura * 0.45).clamp(0.0, 0.18),
      grain: state.params.grain.clamp(0.0, 0.06),
      scanlines: 0.0,
      glitch: 0.0,
      ghost: false,
      colorPop: false,
      overlayColor: null,
      replaceBackground: false,
      showDateStamp: false,
      cinemaMode: false,
      polaroidFrame: false,
      vignette: state.params.vignette.clamp(0.0, 0.08),
      lightLeakIndex: 0,
    );

    _applyRecipe(
      context,
      next,
      preset: state.selectedPreset,
      message: _t.of('clean_pro'),
      color: AppTokens.primary,
    );
  }

  void _resetStudioSession() {
    setState(() {
      _imageBytes = null;
      _aiInsight = null;
      _isAnalyzingInsight = false;
      _selectedStyleId = null;
      _showResult = false;
    });
  }

  void _showStudioSnack(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r16),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final presets = _presets;
    final t = _t;
    final l10n = this.l10n;

    return FilterStudioScope(
      presets: presets,
      child: BlocConsumer<FilterStudioBloc, FilterStudioState>(
        listenWhen: (p, c) =>
            c.failureTick != p.failureTick && c.lastFailure != null,
        listener: (ctx, state) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(
              state.lastFailure?.message ?? 'Error',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppTokens.danger,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.r16)),
          ));
        },
        builder: (ctx, state) {
          // ── Result page ──────────────────────────────────────────
          if (_showResult && state.imageFile != null) {
            return ProResultPage(
              imageFile: state.imageFile!,
              t: t,
              canvasBuilder: (file) => ArtisticCanvas(
                imageFile: file,
                personMask: state.personMask,
                params: state.params,
              ),
              onEditAgain: () => setState(() => _showResult = false),
              onNewImage: () {
                setState(() => _showResult = false);
                _pickImage(ctx);
              },
              onSave: () => _saveResult(ctx),
            );
          }

          return Directionality(
            textDirection: t.isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              backgroundColor: AppTokens.bg,
              body: Stack(
                children: [
                  Positioned.fill(child: FilterStudioShellBackdrop()),
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final mode = _layoutModeForWidth(constraints.maxWidth);
                        final accent = _currentAccent(state, presets);
                        final screenPadding =
                            mode == FilterStudioLayoutMode.compact
                                ? EdgeInsets.fromLTRB(12, 12, 12, 12)
                                : mode == FilterStudioLayoutMode.medium
                                    ? EdgeInsets.fromLTRB(18, 18, 18, 18)
                                    : EdgeInsets.fromLTRB(24, 20, 24, 20);

                        return Padding(
                          padding: screenPadding,
                          child: Column(
                            children: [
                              FilterStudioHeader(
                                t: t,
                                mode: mode,
                                currentLang: _lang,
                                accent: accent,
                                hasImage: state.imageFile != null,
                                currentLookLabel: state.imageFile == null
                                    ? null
                                    : _currentLookLabel(state, presets, l10n),
                                aiStatusLabel: _aiStatusLabel(l10n),
                                aiButtonLabel: _aiButtonLabel(l10n),
                                isAiBusy: _isAnalyzingInsight,
                                hasAiInsight: _aiInsight != null,
                                onBack: () => _handleBack(ctx, state),
                                onPick: () => _pickImage(ctx),
                                onToggleLanguage: _toggleLang,
                                onAnalyze: state.imageFile == null
                                    ? null
                                    : () => _runAiAnalysis(
                                          ctx,
                                          autoApply: true,
                                        ),
                                onReview: state.imageFile == null
                                    ? null
                                    : () => setState(() => _showResult = true),
                              ),
                              SizedBox(
                                height: mode == FilterStudioLayoutMode.compact
                                    ? 12
                                    : 18,
                              ),
                              Expanded(
                                child: state.imageFile == null
                                    ? FilterStudioEmptyState(
                                        t: t,
                                        mode: mode,
                                        accent: accent,
                                        totalLooks: _styleLibrary.length,
                                        onPick: () => _pickImage(ctx),
                                      )
                                    : _buildWorkspace(
                                        ctx,
                                        state,
                                        presets,
                                        t,
                                        mode,
                                        accent,
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (state.isProcessing)
                    Positioned.fill(child: _overlay(state, t)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Phone ──────────────────────────────────────────────────────

  // ─── Tablet ─────────────────────────────────────────────────────

  // ─── Desktop ────────────────────────────────────────────────────

  // ─── Bottom Sheet ────────────────────────────────────────────────

  // ─── Processing Overlay ──────────────────────────────────────────
  Widget _overlay(FilterStudioState state, T t) {
    return ProcessingOverlay(
      title: t.of('applying_magic'),
      subtitle: t.of('analyzing'),
      // Guard with null-coalescing — add these fields to
      // FilterStudioState when you're ready to show real progress.
      progress: null,
      steps: const [],
      onCancel: null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// END OF FILE
// ─────────────────────────────────────────────────────────────────

