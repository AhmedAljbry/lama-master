import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/core/ui/AppTokens.dart';
import 'package:lama/features/studio_editor/domain/entities/studio_editor_exceptions.dart';
import 'package:lama/features/studio_editor/domain/entities/studio_processing_request.dart';
import 'package:lama/features/studio_editor/domain/entities/theft_config.dart';
import 'package:lama/features/studio_editor/presentation/services/studio_editor_toolkit.dart';
import 'package:lama/features/studio_editor/presentation/widgets/studio_canvas_workspace.dart';
import 'package:lama/features/studio_editor/presentation/widgets/studio_header_bar.dart';
import 'package:lama/features/studio_editor/presentation/widgets/studio_tools_sidebar.dart';
import 'package:lama/features/studio_editor/presentation/widgets/states/studio_processing_screen.dart';
import 'package:lama/features/studio_editor/presentation/widgets/states/studio_result_screen.dart';
import 'package:lama/presentation/widgets/Steal/FullScreenImageViewer.dart';
import 'package:lama/presentation/widgets/Steal/MaskEditorScreen.dart';

enum EditorState { setup, processing, result }

class StudioEditorMainScreen extends StatefulWidget {
  final Locale? locale;
  final VoidCallback? onToggleLocale;

  const StudioEditorMainScreen({
    super.key,
    this.locale,
    this.onToggleLocale,
  });

  @override
  State<StudioEditorMainScreen> createState() => _StudioEditorMainScreenState();
}

class _StudioEditorMainScreenState extends State<StudioEditorMainScreen> {
  EditorState _state = EditorState.setup;

  String? _targetPath;
  String? _refPath;
  Uint8List? _targetBytes;
  Uint8List? _refBytes;
  Uint8List? _manualMaskBytes;
  Uint8List? _processedBytes;

  bool _isComparing = false;
  bool _useAI = false;

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
  String _selectedStyleKey = kStyleKeys.first;

  double _strength = 1.0;
  double _skinProtect = 0.85;
  double _lumaTransfer = 0.3;
  double _colorTransfer = 1.0;
  double _contrast = 1.15;
  double _vignette = 0.3;
  double _grain = 0.1;

  final List<Uint8List> _history = <Uint8List>[];
  int _histIdx = -1;

  bool get _hasTarget => _targetBytes != null;
  bool get _hasReference => _refBytes != null;
  bool get _hasManualMask => _manualMaskBytes != null;
  bool get _isProcessing => _state == EditorState.processing;
  bool get _hasResult => _state == EditorState.result && _outputBytes != null;

  Uint8List? get _outputBytes => (_histIdx >= 0 && _histIdx < _history.length)
      ? _history[_histIdx]
      : _processedBytes;

  bool get _canUndo => _histIdx > 0;
  bool get _canRedo => _histIdx >= 0 && _histIdx < _history.length - 1;

  void _pushHistory(Uint8List bytes) {
    if (_histIdx < _history.length - 1) {
      _history.removeRange(_histIdx + 1, _history.length);
    }
    _history.add(bytes);
    _histIdx = _history.length - 1;
  }

  void _undoHistory() {
    if (!_canUndo) return;
    HapticFeedback.selectionClick();
    setState(() {
      _histIdx--;
      _processedBytes = _history[_histIdx];
    });
  }

  void _redoHistory() {
    if (!_canRedo) return;
    HapticFeedback.selectionClick();
    setState(() {
      _histIdx++;
      _processedBytes = _history[_histIdx];
    });
  }

  Future<void> _pickImage(bool isTarget) async {
    HapticFeedback.lightImpact();
    final toolkit = context.read<StudioEditorToolkit>();
    final l10n = AppL10n.of(context);

    try {
      final picked = await toolkit.pickImage();
      if (!mounted || picked == null) return;

      setState(() {
        if (isTarget) {
          _targetPath = picked.path;
          _targetBytes = picked.bytes;
          _processedBytes = null;
          _manualMaskBytes = null;
          _state = EditorState.setup;
          _isComparing = false;
          _history.clear();
          _histIdx = -1;
        } else {
          _refPath = picked.path;
          _refBytes = picked.bytes;
        }
      });
    } on StudioImageConvertException {
      if (mounted) _snack(l10n.get('snack_convert_fail'), isError: true);
    } catch (error, stack) {
      toolkit.reporter.capture(error, stack, context: 'studioPickImage');
      if (mounted) _snack(error.toString(), isError: true);
    }
  }

  Future<void> _openMaskEditor() async {
    HapticFeedback.mediumImpact();
    final l10n = AppL10n.of(context);
    if (!_useAI) {
      _snack(l10n.get('snack_ai_conflict'), isWarning: true);
      return;
    }
    if (_targetPath == null) {
      _snack(l10n.get('snack_need_target'), isError: true);
      return;
    }

    final result = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute<Uint8List>(
        builder: (_) => MaskEditorScreen(imagePath: _targetPath!),
      ),
    );

    if (result != null) {
      setState(() => _manualMaskBytes = result);
      _snack(l10n.get('snack_received_mask'), isWarning: true);
      _startProcessing();
    }
  }

  Future<void> _startProcessing() async {
    if (_isProcessing) return;

    HapticFeedback.heavyImpact();
    final l10n = AppL10n.of(context);
    final toolkit = context.read<StudioEditorToolkit>();

    if (!_hasTarget || !_hasReference) {
      _snack(l10n.get('snack_need_both'), isWarning: true);
      return;
    }

    setState(() {
      _state = EditorState.processing;
      _isComparing = false;
    });

    try {
      final result = await toolkit.process(
        StudioProcessingRequest(
          targetBytes: _targetBytes!,
          refBytes: _refBytes!,
          targetPath: _targetPath,
          refPath: _refPath,
          manualMaskBytes: _manualMaskBytes,
          useAi: _useAI,
          config: _buildConfig(),
        ),
      );
      if (!mounted) return;

      if (_useAI && !_hasManualMask) {
        if (!result.targetPersonDetected) {
          _snack(l10n.get('snack_no_person'), isWarning: true);
        } else if (!result.aiMaskApplied) {
          _snack(l10n.get('snack_ai_mask_skipped'), isWarning: true);
        }
      }

      setState(() {
        _processedBytes = result.processedBytes;
        _pushHistory(result.processedBytes);
        _state = EditorState.result;
      });

      HapticFeedback.vibrate();
      _snack(l10n.get('snack_done'));
    } catch (error, stack) {
      toolkit.reporter.capture(error, stack, context: 'studioProcess');
      if (!mounted) return;
      setState(() => _state = EditorState.setup);
      _snack('${l10n.get('snack_error_prefix')}$error', isError: true);
    }
  }

  TheftConfig _buildConfig() {
    final style = _selectedStyleKey;
    return TheftConfig(
      strength: _strength,
      skinProtect: _skinProtect,
      lumaTransfer: _lumaTransfer,
      colorTransfer: _colorTransfer,
      contrastBoost: _contrast,
      vignette: _vignette,
      grain: _grain,
      isLightTheft: style == 'style_luma_master',
      isStyleTheft: style == 'style_pro_studio',
      isColorTheft: style == 'style_color_theft',
      isThemeTheft: style == 'style_theme_theft',
      isCinematic: style == 'style_cinematic',
      isCyberpunk: style == 'style_cyber_neon',
      isColorSplash: style == 'style_color_splash',
      isHDR: style == 'style_hdr_magic',
      isSepia: style == 'style_sepia_retro',
    ).sanitized();
  }

  Future<void> _save() async {
    final bytes = _outputBytes;
    if (bytes == null) return;
    final l10n = AppL10n.of(context);
    final toolkit = context.read<StudioEditorToolkit>();
    HapticFeedback.heavyImpact();
    _snack(l10n.get('snack_saving'));

    try {
      final saved = await toolkit.saveResult(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (saved) {
        _snack(l10n.get('snack_saved'));
      } else {
        _snack(l10n.get('snack_save_fail'), isError: true);
      }
    } catch (error, stack) {
      toolkit.reporter.capture(error, stack, context: 'studioSave');
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _snack(l10n.get('snack_save_fail'), isError: true);
    }
  }

  Future<void> _share() async {
    final bytes = _outputBytes;
    final l10n = AppL10n.of(context);
    final toolkit = context.read<StudioEditorToolkit>();
    if (bytes == null) {
      _snack(l10n.get('snack_no_output'), isWarning: true);
      return;
    }
    HapticFeedback.mediumImpact();
    _snack(l10n.get('snack_preparing_share'));

    try {
      final shared = await toolkit.shareResult(bytes, text: 'Studio Pro');
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (!shared) _snack(l10n.get('snack_share_fail'), isError: true);
    } catch (error, stack) {
      toolkit.reporter.capture(error, stack, context: 'studioShare');
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _snack('${l10n.get('snack_share_fail')}: $error', isError: true);
    }
  }

  void _openFullScreen() {
    if (_targetBytes == null) return;
    HapticFeedback.selectionClick();
    final show = _isComparing ? _targetBytes! : (_outputBytes ?? _targetBytes!);
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => FullScreenImageViewer(imageBytes: show),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _snack(String msg, {bool isError = false, bool isWarning = false}) {
    Color color = AppTokens.primary;
    if (isError) { color = AppTokens.danger; }
    else if (isWarning) { color = AppTokens.warning; }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        backgroundColor: AppTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r16),
          side: BorderSide(color: color.withValues(alpha: 0.25)),
        ),
        content: Text(
          msg,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  StudioToolsSidebar _buildToolsSidebar({
    ScrollController? scrollController,
  }) {
    return StudioToolsSidebar(
      state: _state,
      useAI: _useAI,
      hasTarget: _hasTarget,
      hasRef: _hasReference,
      hasManualMask: _hasManualMask,
      selectedStyle: _selectedStyleKey,
      strength: _strength,
      skinProtect: _skinProtect,
      lumaTransfer: _lumaTransfer,
      colorTransfer: _colorTransfer,
      contrast: _contrast,
      vignette: _vignette,
      grain: _grain,
      isBusy: _isProcessing,
      scrollController: scrollController,
      onAIToggle: (value) => setState(() {
        _useAI = value;
        if (!value) _manualMaskBytes = null;
      }),
      onPickTarget: () => _pickImage(true),
      onPickRef: () => _pickImage(false),
      onManualSelect: _openMaskEditor,
      onStyleChanged: (style) => setState(() => _selectedStyleKey = style),
      onStrengthChanged: (v) => setState(() => _strength = v),
      onSkinProtectChanged: (v) => setState(() => _skinProtect = v),
      onLumaChanged: (v) => setState(() => _lumaTransfer = v),
      onColorChanged: (v) => setState(() => _colorTransfer = v),
      onContrastChanged: (v) => setState(() => _contrast = v),
      onVignetteChanged: (v) => setState(() => _vignette = v),
      onGrainChanged: (v) => setState(() => _grain = v),
      onApply: _startProcessing,
      onEditResult: () => setState(() {
        _state = EditorState.setup;
        _isComparing = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final isDesktop = AppTokens.isDesktop(context);
    final isTablet = AppTokens.isTablet(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final showSidebar = isDesktop || (isTablet && isLandscape);
    final safePad = MediaQuery.of(context).padding;

    // The canvas workspace widget (reused in both layouts)
    final workspace = StudioCanvasWorkspace(
      state: _state,
      targetBytes: _targetBytes,
      outputBytes: _outputBytes,
      refPath: _refPath,
      isComparing: _isComparing,
      useAI: _useAI,
      hasManualMask: _hasManualMask,
      selectedStyle: _selectedStyleKey,
      onTapFullScreen: _openFullScreen,
      onPickTarget: () => _pickImage(true),
      onPickReference: () => _pickImage(false),
      onCompareToggle: (v) => setState(() => _isComparing = v),
      onCompareToggleEnd: () => setState(() => _isComparing = false),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTokens.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(76),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isDesktop ? AppTokens.s24 : AppTokens.s16,
              AppTokens.s8,
              isDesktop ? AppTokens.s24 : AppTokens.s16,
              0,
            ),
            child: StudioHeaderBar(
              onBack: () => Navigator.of(context).maybePop(),
              canUndo: _canUndo,
              canRedo: _canRedo,
              onUndo: _undoHistory,
              onRedo: _redoHistory,
              onSave: _save,
              onShare: _share,
              hasResult: _hasResult,
              statusLabel: _statusLabel(l10n),
              styleLabel: l10n.get(_selectedStyleKey),
              hasTarget: _hasTarget,
              hasReference: _hasReference,
              useAI: _useAI,
            ),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              AppTokens.bg,
              Color.lerp(AppTokens.bg, const Color(0xFF0F0F12), 0.5) ?? AppTokens.bg,
              const Color(0xFF0A0A0B),
            ],
          ),
        ),
        child: Column(
          children: <Widget>[
            // Space for appbar
            SizedBox(height: safePad.top + 84),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _state == EditorState.processing
                    ? const StudioProcessingScreen(key: ValueKey<String>('processing'))
                    : _state == EditorState.result && _outputBytes != null
                        ? StudioResultScreen(
                            key: const ValueKey<String>('result'),
                            imageBytes: _outputBytes!,
                            selectedStyle: _selectedStyleKey,
                            useAI: _useAI,
                            hasManualMask: _hasManualMask,
                            onEdit: () => setState(() {
                              _state = EditorState.setup;
                              _isComparing = false;
                            }),
                            onSave: _save,
                            onShare: _share,
                          )
                        : Padding(
                            key: const ValueKey<String>('workspace_root'),
                            padding: EdgeInsets.fromLTRB(
                              isDesktop ? AppTokens.s24 : AppTokens.s12,
                              0,
                              isDesktop ? AppTokens.s24 : AppTokens.s12,
                              isDesktop ? AppTokens.s24 : AppTokens.s12,
                            ),
                            child: showSidebar
                                ? _buildDesktopLayout(workspace, isDesktop)
                                : _buildMobileLayout(workspace),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(AppL10n l10n) {
    switch (_state) {
      case EditorState.setup:
        return l10n.get('editor_state_setup');
      case EditorState.processing:
        return l10n.get('editor_state_processing');
      case EditorState.result:
        return l10n.get('editor_state_result');
    }
  }

  Widget _buildDesktopLayout(Widget workspace, bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(flex: 7, child: workspace),
        const SizedBox(width: AppTokens.s16),
        SizedBox(
          width: isDesktop ? 380 : 340,
          child: Container(
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(AppTokens.r24),
              border: Border.all(color: AppTokens.border.withValues(alpha: 0.4)),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildToolsSidebar(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(Widget workspace) {
    return Column(
      children: <Widget>[
        Expanded(child: workspace),
        const SizedBox(height: AppTokens.s12),
        _MobileToolbar(
          hasTarget: _hasTarget,
          isBusy: _isProcessing,
          canUndo: _canUndo,
          onOpenTools: () => _showMobileToolsSheet(context),
          onApply: _startProcessing,
          onUndo: _undoHistory,
        ),
      ],
    );
  }

  void _showMobileToolsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.50,
          maxChildSize: 0.96,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTokens.r32),
                ),
                border: Border.all(
                  color: AppTokens.border.withValues(alpha: 0.18),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.75),
                    blurRadius: 60,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: AppTokens.s10),
                  // Drag handle — wider & more prominent
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTokens.border,
                      borderRadius: BorderRadius.circular(AppTokens.rFull),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: _buildToolsSidebar(scrollController: scrollController),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Mobile Bottom Toolbar — 3 actions: Edit Tools + Undo + Apply
// ─────────────────────────────────────────────────────────────
class _MobileToolbar extends StatelessWidget {
  final VoidCallback onOpenTools;
  final bool hasTarget;
  final bool isBusy;
  final VoidCallback onApply;
  final bool canUndo;
  final VoidCallback onUndo;

  const _MobileToolbar({
    required this.onOpenTools,
    required this.hasTarget,
    required this.isBusy,
    required this.onApply,
    this.canUndo = false,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: AppTokens.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppTokens.r20),
        border: Border.all(color: AppTokens.border.withValues(alpha: 0.35)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: <Widget>[
          // ── Open Edit Tools ──────────────────────────────
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: onOpenTools,
              borderRadius: BorderRadius.circular(AppTokens.r14),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.tune_rounded,
                      color: AppTokens.text,
                      size: 18,
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Text(
                      l10n.get('btn_edit'),
                      style: AppTokens.labelBold.copyWith(
                        color: AppTokens.text,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: AppTokens.border.withValues(alpha: 0.4),
          ),

          // ── Undo ─────────────────────────────────────────
          Tooltip(
            message: l10n.get('btn_undo'),
            child: InkWell(
              onTap: (canUndo && !isBusy) ? onUndo : null,
              borderRadius: BorderRadius.circular(AppTokens.r12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s12, vertical: 8),
                child: Icon(
                  Icons.undo_rounded,
                  size: 20,
                  color: (canUndo && !isBusy)
                      ? AppTokens.text
                      : AppTokens.text2.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: AppTokens.border.withValues(alpha: 0.4),
          ),

          // ── Apply ─────────────────────────────────────────
          if (hasTarget)
            GestureDetector(
              onTap: isBusy ? null : onApply,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s18,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  gradient: isBusy ? null : AppTokens.primaryGradient,
                  color: isBusy ? AppTokens.card2 : null,
                  borderRadius: BorderRadius.circular(AppTokens.r14),
                  boxShadow: isBusy ? null : AppTokens.primaryGlow(0.18),
                ),
                child: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTokens.text2,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.black,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            l10n.get('apply_btn'),
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.s10),
              child: Text(
                '① Add photo',
                style: AppTokens.caption.copyWith(
                  color: AppTokens.text2.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
