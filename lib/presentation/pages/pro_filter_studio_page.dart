// pro_filter_studio_page.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

// ─── Project imports ──────────────────────────────────────────────
import 'package:lama/core/i18n/t.dart'; // T, Lang
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
import 'package:lama/presentation/pages/PT.dart';
import 'package:lama/presentation/pages/Pro.dart';
import 'package:lama/presentation/pages/ProResultPage.dart';
import 'package:lama/presentation/pages/ProcessingOverlay_ProFilterStudioPage.dart';
import 'package:lama/presentation/widgets/artistic_canvas.dart';
import 'package:lama/presentation/widgets/bottom_controls.dart';
import 'package:lama/presentation/widgets/filter_studio/filter_studio_shell.dart';

// ─── Pro files (same folder — relative imports) ───────────────────

// ─────────────────────────────────────────────────────────────────
class ProFilterStudioPage extends StatefulWidget {
  final Lang currentLang;

  const ProFilterStudioPage({
    super.key,
    this.currentLang = Lang.en,
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
  Lang _lang = Lang.en;
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
    _lang = widget.currentLang;
  }

  T get _t => T(_lang);

  String get _aiButtonLabel {
    final insight = _aiInsight;
    if (_isAnalyzingInsight) {
      return _t.of('ai_status_running');
    }
    if (_imageBytes == null) {
      return 'AI';
    }
    if (insight == null) {
      return _t.of('ai_auto_fix');
    }
    return '${_t.of('ai_ready_short')} ${(insight.confidence * 100).round()}%';
  }

  String get _aiStatusLabel {
    if (_isAnalyzingInsight) {
      return _t.of('ai_status_running');
    }
    if (_aiInsight != null) {
      return _t.of('ai_status_ready');
    }
    return _t.of('ai_manual');
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
  ) {
    final selectedStyle = _selectedStyle;
    if (selectedStyle != null) {
      return selectedStyle.name(_lang);
    }
    return presets[state.selectedPreset]?.name ?? _t.of('normal');
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
        PT.mint;
  }

  List<FilterStudioInspectorTab> _buildInspectorTabs(
    BuildContext context,
    FilterStudioState state,
    Map<AppPreset, PresetConfig> presets,
  ) {
    final bloc = context.read<FilterStudioBloc>();

    return [
      FilterStudioInspectorTab(
        label: _t.of('ai_tab'),
        icon: Icons.auto_awesome_rounded,
        child: AiStudioTab(
          lang: _lang,
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
        label: _t.of('presets'),
        icon: Icons.auto_fix_high_rounded,
        child: PresetsTab(
          lang: _lang,
          presets: presets,
          selectedPreset: state.selectedPreset,
          onPresetSelected: (preset) => _selectCorePreset(context, preset),
          styleLibrary: _styleLibrary,
          selectedStyleId: _selectedStyleId,
          onStyleSelected: (style) => _applyCatalogStyle(context, style),
        ),
      ),
      FilterStudioInspectorTab(
        label: _t.of('adjust'),
        icon: Icons.tune_rounded,
        child: AdjustTab(
          lang: _lang,
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
        label: _t.of('effects'),
        icon: Icons.blur_on_rounded,
        child: EffectsTab(
          lang: _lang,
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
        label: _t.of('overlays'),
        icon: Icons.layers_rounded,
        child: OverlaysTab(
          lang: _lang,
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
    final tabs = _buildInspectorTabs(context, state, presets);
    final currentLookLabel = _currentLookLabel(state, presets);

    final preview = FilterStudioPreviewPane(
      t: t,
      mode: mode,
      accent: accent,
      state: state,
      repaintKey: _repaintKey,
      currentLookLabel: currentLookLabel,
      aiStatusLabel: _aiStatusLabel,
      totalLooks: _styleLibrary.length,
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
      aiStatusLabel: _aiStatusLabel,
      hasPersonMask: state.personMask != null,
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
        const SizedBox(width: PT.s16),
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
        auraColor: PT.gold,
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
        auraColor: PT.gold,
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
        auraColor: PT.t2,
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
        auraColor: PT.gold,
        colorOverlay: Colors.redAccent.withOpacity(0.10),
      ),
      AppPreset.editorial: PresetConfig(
        name: t.of('editorial'),
        icon: Icons.auto_fix_high_rounded,
        contrast: 1.08,
        saturation: 1.04,
        exposure: 0.01,
        vignette: 0.06,
        auraColor: PT.mint,
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
        auraColor: PT.cyan,
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
        auraColor: PT.cyan,
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
    setState(() => _lang = _lang == Lang.en ? Lang.ar : Lang.en);
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
      _showStudioSnack(context, _t.of('pick_hint'), PT.danger);
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
      color: PT.cyan,
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
    Color color = PT.mint,
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
    Color color = PT.mint,
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
        PT.warning,
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
      color: PT.purple,
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
        PT.warning,
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
      auraColor: PT.cyan,
      colorPop: true,
      vignette: (state.params.vignette + 0.10).clamp(0.0, 0.8),
    );

    _applyRecipe(
      context,
      next,
      preset: state.selectedPreset,
      message: _t.of('smart_focus'),
      color: PT.cyan,
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
      color: PT.gold,
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
      color: PT.mint,
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
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PT.r16),
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

    return FilterStudioScope(
      presets: presets,
      child: BlocConsumer<FilterStudioBloc, FilterStudioState>(
        listenWhen: (p, c) =>
            c.failureTick != p.failureTick && c.lastFailure != null,
        listener: (ctx, state) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(
              state.lastFailure?.message ?? 'Error',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            backgroundColor: PT.danger,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PT.r16)),
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
              backgroundColor: PT.bgOf(context),
              body: Stack(
                children: [
                  const Positioned.fill(child: FilterStudioShellBackdrop()),
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final mode = _layoutModeForWidth(constraints.maxWidth);
                        final accent = _currentAccent(state, presets);
                        final screenPadding =
                            mode == FilterStudioLayoutMode.compact
                                ? const EdgeInsets.fromLTRB(12, 12, 12, 12)
                                : mode == FilterStudioLayoutMode.medium
                                    ? const EdgeInsets.fromLTRB(18, 18, 18, 18)
                                    : const EdgeInsets.fromLTRB(24, 20, 24, 20);

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
                                    : _currentLookLabel(state, presets),
                                aiStatusLabel: _aiStatusLabel,
                                aiButtonLabel: _aiButtonLabel,
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
// CANVAS AREA
// ─────────────────────────────────────────────────────────────────
class _CanvasArea extends StatelessWidget {
  final FilterStudioState state;
  final GlobalKey repaintKey;
  final T t;
  final VoidCallback onPick;
  final String currentLookLabel;
  final String aiStatusLabel;
  final int totalLooks;
  final double topPadding;
  final double bottomPadding;
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

  const _CanvasArea({
    required this.state,
    required this.repaintKey,
    required this.t,
    required this.onPick,
    required this.currentLookLabel,
    required this.aiStatusLabel,
    required this.totalLooks,
    required this.topPadding,
    required this.bottomPadding,
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
    if (state.imageFile == null) {
      return _EmptyState(
        t: t,
        onPick: onPick,
        totalLooks: totalLooks,
      );
    }
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Pro.canvasW(context)),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 90),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(PT.r20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 40,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: RepaintBoundary(
                        key: repaintKey,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(PT.r20),
                          child: ArtisticCanvas(
                            imageFile: state.imageFile!,
                            personMask: state.personMask,
                            params: state.params,
                            showOriginal: state.isComparingHold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: PT.s12,
                      left: PT.s12,
                      child: _StudioHudCard(
                        title: t.of('studio_control'),
                        value: currentLookLabel,
                        status: aiStatusLabel,
                      ),
                    ),
                    Positioned(
                      left: PT.s12,
                      right: PT.s12,
                      bottom: PT.s12,
                      child: Wrap(
                        spacing: PT.s8,
                        runSpacing: PT.s8,
                        children: [
                          _StudioHudPill(
                            label: '$totalLooks ${t.of('looks_label')}',
                            color: PT.mint,
                          ),
                          _StudioHudPill(
                            label: t.of('live_preview'),
                            color: PT.cyan,
                          ),
                          _StudioHudPill(
                            label: aiStatusLabel,
                            color: PT.gold,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _PreviewQuickDock(
                  t: t,
                  canUndo: canUndo,
                  canRedo: canRedo,
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
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────
class _EmptyState extends StatefulWidget {
  final T t;
  final VoidCallback onPick;
  final int totalLooks;

  const _EmptyState({
    required this.t,
    required this.onPick,
    required this.totalLooks,
  });

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack)
        .drive(Tween(begin: 0.85, end: 1.0));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.scale(
        scale: _scale.value,
        child: Opacity(opacity: _opacity.value, child: child),
      ),
      child: Center(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onPick();
          },
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(PT.s32),
            decoration: BoxDecoration(
              color: PT.surface,
              borderRadius: BorderRadius.circular(PT.r24),
              border: Border.all(color: PT.mint.withOpacity(0.2)),
              boxShadow: PT.glow(PT.mint, blur: 40),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: PT.gradMint,
                    shape: BoxShape.circle,
                    boxShadow: PT.glow(PT.mint, blur: 30),
                  ),
                  child: const Icon(Icons.add_photo_alternate_rounded,
                      size: 40, color: Colors.black),
                ),
                const SizedBox(height: PT.s24),
                ShaderMask(
                  shaderCallback: (b) => PT.gradMint.createShader(b),
                  child: Text(
                    widget.t.of('tap_to_open'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: PT.s12),
                Text(
                  widget.t.of('welcome_sub'),
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: PT.t2, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: PT.s24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Badge(
                      label:
                          '${widget.totalLooks} ${widget.t.of('looks_label')}',
                      color: PT.mint,
                    ),
                    const SizedBox(width: PT.s8),
                    _Badge(label: widget.t.of('ai_manual'), color: PT.purple),
                    const SizedBox(width: PT.s8),
                    _Badge(label: widget.t.of('pro_pack'), color: PT.gold),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(PT.rFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1)),
    );
  }
}

class _StudioHudCard extends StatelessWidget {
  final String title;
  final String value;
  final String status;

  const _StudioHudCard({
    required this.title,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(PT.r20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(PT.s12),
          decoration: BoxDecoration(
            color: PT.surface.withOpacity(0.72),
            borderRadius: BorderRadius.circular(PT.r20),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: PT.t3,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: PT.s4),
              Text(
                value,
                style: const TextStyle(
                  color: PT.t1,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: PT.s6),
              Text(
                status,
                style: const TextStyle(
                  color: PT.mint,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudioHudPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StudioHudPill({
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
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────
class _PreviewQuickDock extends StatelessWidget {
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

  const _PreviewQuickDock({
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(PT.r20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(PT.s12),
          decoration: BoxDecoration(
            color: PT.surface.withOpacity(0.82),
            borderRadius: BorderRadius.circular(PT.r20),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
            boxShadow: PT.elevation,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.of('preview_tools'),
                style: const TextStyle(
                  color: PT.t1,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: PT.s10),
              Wrap(
                spacing: PT.s8,
                runSpacing: PT.s8,
                children: [
                  _PreviewDockBtn(
                    icon: Icons.auto_awesome_rounded,
                    label: t.of('ai_auto_fix'),
                    color: PT.cyan,
                    onTap: onAiAuto,
                  ),
                  _HoldPreviewDockBtn(
                    icon: Icons.compare_arrows_rounded,
                    label: t.of('compare_hold'),
                    color: PT.mint,
                    onStart: onCompareStart,
                    onEnd: onCompareEnd,
                  ),
                  _PreviewDockBtn(
                    icon: Icons.movie_creation_outlined,
                    label: t.of('cinematic_look'),
                    color: PT.gold,
                    onTap: onCinematic,
                  ),
                  _PreviewDockBtn(
                    icon: Icons.blur_on_rounded,
                    label: t.of('depth_blur'),
                    color: PT.purple,
                    onTap: onDepthBlur,
                  ),
                  _PreviewDockBtn(
                    icon: Icons.shuffle_rounded,
                    label: t.of('random_mix'),
                    color: PT.mint,
                    onTap: onRandom,
                  ),
                  _PreviewDockBtn(
                    icon: Icons.undo_rounded,
                    label: t.of('undo'),
                    color: canUndo ? PT.mint : PT.t3,
                    onTap: canUndo ? onUndo : null,
                  ),
                  _PreviewDockBtn(
                    icon: Icons.redo_rounded,
                    label: t.of('redo'),
                    color: canRedo ? PT.mint : PT.t3,
                    onTap: canRedo ? onRedo : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewDockBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _PreviewDockBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
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
      child: AnimatedOpacity(
        duration: PT.fast,
        opacity: enabled ? 1 : 0.45,
        child: Container(
          constraints: const BoxConstraints(minWidth: 92),
          padding: const EdgeInsets.symmetric(
            horizontal: PT.s12,
            vertical: PT.s10,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(enabled ? 0.12 : 0.05),
            borderRadius: BorderRadius.circular(PT.r16),
            border: Border.all(color: color.withOpacity(enabled ? 0.26 : 0.10)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
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
        ),
      ),
    );
  }
}

class _HoldPreviewDockBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  const _HoldPreviewDockBtn({
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
        constraints: const BoxConstraints(minWidth: 108),
        padding: const EdgeInsets.symmetric(
          horizontal: PT.s12,
          vertical: PT.s10,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(PT.r16),
          border: Border.all(color: color.withOpacity(0.26)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
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
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final T t;
  final bool isSaving;
  final bool hasImage;
  final Lang currentLang; // ← separate field avoids t.lang dependency
  final VoidCallback onPick;
  final VoidCallback? onAiApply;
  final String aiButtonLabel;
  final bool isAiBusy;
  final bool hasAiInsight;
  final VoidCallback? onSave;
  final VoidCallback onBack;
  final VoidCallback onLangToggle;
  final bool isDesktop;

  const _TopBar({
    required this.t,
    required this.isSaving,
    required this.hasImage,
    required this.currentLang,
    required this.onPick,
    required this.onAiApply,
    required this.aiButtonLabel,
    required this.isAiBusy,
    required this.hasAiInsight,
    required this.onSave,
    required this.onBack,
    required this.onLangToggle,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    // Show the OPPOSITE language as label (what user will switch TO)
    final langLabel = currentLang == Lang.ar ? 'EN' : 'AR';

    return ClipRRect(
      borderRadius: BorderRadius.circular(PT.r32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: PT.s8),
          decoration: BoxDecoration(
            color: PT.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(PT.r32),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(children: [
            _GlassBtn(
              icon: hasImage
                  ? Icons.arrow_back_ios_new_rounded
                  : Icons.close_rounded,
              onTap: onBack,
            ),
            const SizedBox(width: PT.s8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: PT.gradPurple,
                borderRadius: BorderRadius.circular(PT.r8),
              ),
              child: const Icon(Icons.movie_filter_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: PT.s8),
            ShaderMask(
              shaderCallback: (b) => PT.gradPurple.createShader(b),
              child: Text(
                t.of('pro_studio'),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontSize: 13),
              ),
            ),
            const Spacer(),
            _GlassBtn(
              icon: Icons.language_rounded,
              onTap: onLangToggle,
              label: langLabel,
            ),
            const SizedBox(width: PT.s8),
            if (!hasImage || isDesktop)
              _GlassBtn(icon: Icons.add_photo_alternate_rounded, onTap: onPick),
            if (hasImage) ...[
              const SizedBox(width: PT.s8),
              GestureDetector(
                onTap: isAiBusy || onAiApply == null ? null : onAiApply,
                child: AnimatedContainer(
                  duration: PT.fast,
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: PT.s12),
                  decoration: BoxDecoration(
                    color: hasAiInsight
                        ? PT.cyan.withOpacity(0.14)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(PT.rFull),
                    border: Border.all(
                      color: hasAiInsight
                          ? PT.cyan.withOpacity(0.34)
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isAiBusy)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: PT.cyan,
                          ),
                        )
                      else
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: hasAiInsight ? PT.cyan : PT.t3,
                        ),
                      const SizedBox(width: PT.s6),
                      Text(
                        aiButtonLabel,
                        style: TextStyle(
                          color: hasAiInsight ? PT.cyan : PT.t3,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (hasImage && onSave != null) ...[
              const SizedBox(width: PT.s8),
              GestureDetector(
                onTap: isSaving ? null : onSave,
                child: AnimatedContainer(
                  duration: PT.fast,
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: PT.s16),
                  decoration: BoxDecoration(
                    gradient: isSaving ? null : PT.gradMint,
                    color: isSaving ? PT.card : null,
                    borderRadius: BorderRadius.circular(PT.rFull),
                    boxShadow: isSaving ? [] : PT.glow(PT.mint, blur: 14),
                  ),
                  child: Center(
                    child: isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          )
                        : Text(
                            t.of('save'),
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 13),
                          ),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? label;

  const _GlassBtn({
    required this.icon,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 36,
        padding:
            EdgeInsets.symmetric(horizontal: label != null ? PT.s12 : PT.s8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(PT.r12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: PT.t2, size: 16),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(label!,
                  style: const TextStyle(
                      color: PT.t2, fontSize: 11, fontWeight: FontWeight.w800)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// DESKTOP TOOLBAR
// ─────────────────────────────────────────────────────────────────
class _DesktopToolbar extends StatelessWidget {
  final VoidCallback onPick;
  final VoidCallback? onAiApply;
  final VoidCallback onEditorial;
  final VoidCallback onHalo;

  const _DesktopToolbar({
    required this.onPick,
    required this.onAiApply,
    required this.onEditorial,
    required this.onHalo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      color: PT.surface,
      padding: const EdgeInsets.symmetric(vertical: PT.s24),
      child: Column(children: [
        const SizedBox(height: 60),
        _DesktopToolbarBtn(
          icon: Icons.add_photo_alternate_rounded,
          color: PT.mint,
          onTap: onPick,
        ),
        const SizedBox(height: PT.s10),
        _DesktopToolbarBtn(
          icon: Icons.auto_awesome_rounded,
          color: PT.cyan,
          onTap: onAiApply,
        ),
        const SizedBox(height: PT.s10),
        _DesktopToolbarBtn(
          icon: Icons.auto_fix_high_rounded,
          color: PT.gold,
          onTap: onEditorial,
        ),
        const SizedBox(height: PT.s10),
        _DesktopToolbarBtn(
          icon: Icons.wb_iridescent_rounded,
          color: PT.purple,
          onTap: onHalo,
        ),
      ]),
    );
  }
}

class _DesktopToolbarBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _DesktopToolbarBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(PT.r12),
          border: Border.all(color: color.withOpacity(0.24)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
