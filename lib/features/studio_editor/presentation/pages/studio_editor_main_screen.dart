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
  final Locale locale;
  final VoidCallback onToggleLocale;

  const StudioEditorMainScreen({
    super.key,
    required this.locale,
    required this.onToggleLocale,
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
  String _selectedStyle = kStyles.first;

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
    if (!_canUndo) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _histIdx--;
      _processedBytes = _history[_histIdx];
    });
  }

  void _redoHistory() {
    if (!_canRedo) {
      return;
    }
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
      if (!mounted || picked == null) {
        return;
      }

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
      if (mounted) {
        _snack(l10n.get('snack_convert_fail'), isError: true);
      }
    } catch (error, stack) {
      toolkit.reporter.capture(error, stack, context: 'studioPickImage');
      if (mounted) {
        _snack(error.toString(), isError: true);
      }
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
    if (_isProcessing) {
      return;
    }

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
      if (!mounted) {
        return;
      }

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
      if (!mounted) {
        return;
      }
      setState(() => _state = EditorState.setup);
      _snack('${l10n.get('snack_error_prefix')}$error', isError: true);
    }
  }

  TheftConfig _buildConfig() {
    final style = _selectedStyle;
    return TheftConfig(
      strength: _strength,
      skinProtect: _skinProtect,
      lumaTransfer: _lumaTransfer,
      colorTransfer: _colorTransfer,
      contrastBoost: _contrast,
      vignette: _vignette,
      grain: _grain,
      isLightTheft: style == 'Luma Master',
      isStyleTheft: style == 'Pro Studio',
      isColorTheft: style == 'Color Theft',
      isThemeTheft: style == 'Theme Theft',
      isCinematic: style == 'Cinematic',
      isCyberpunk: style == 'Cyber Neon',
      isColorSplash: style == 'Color Splash',
      isHDR: style == 'HDR Magic',
      isSepia: style == 'Sepia Retro',
    ).sanitized();
  }

  Future<void> _save() async {
    final bytes = _outputBytes;
    if (bytes == null) {
      return;
    }
    final l10n = AppL10n.of(context);
    final toolkit = context.read<StudioEditorToolkit>();
    HapticFeedback.heavyImpact();
    _snack(l10n.get('snack_saving'));

    try {
      final saved = await toolkit.saveResult(bytes);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (saved) {
        _snack(l10n.get('snack_saved'));
      } else {
        _snack(l10n.get('snack_save_fail'), isError: true);
      }
    } catch (error, stack) {
      toolkit.reporter.capture(error, stack, context: 'studioSave');
      if (!mounted) {
        return;
      }
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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (!shared) {
        _snack(l10n.get('snack_share_fail'), isError: true);
      }
    } catch (error, stack) {
      toolkit.reporter.capture(error, stack, context: 'studioShare');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _snack('${l10n.get('snack_share_fail')}: $error', isError: true);
    }
  }

  void _openFullScreen() {
    if (_targetBytes == null) {
      return;
    }
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
    var color = AppTokens.primary;
    if (isError) {
      color = AppTokens.danger;
    } else if (isWarning) {
      color = AppTokens.warning;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        backgroundColor: AppTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r16),
          side: BorderSide(color: color.withValues(alpha: 0.28)),
        ),
        content: Text(
          msg,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
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

  StudioToolsSidebar _buildToolsSidebar({
    required bool isHorizontal,
    ScrollController? scrollController,
  }) {
    return StudioToolsSidebar(
      state: _state,
      useAI: _useAI,
      hasTarget: _hasTarget,
      hasRef: _hasReference,
      hasManualMask: _hasManualMask,
      selectedStyle: _selectedStyle,
      strength: _strength,
      skinProtect: _skinProtect,
      lumaTransfer: _lumaTransfer,
      colorTransfer: _colorTransfer,
      contrast: _contrast,
      vignette: _vignette,
      grain: _grain,
      isHorizontalScrollable: isHorizontal,
      scrollController: scrollController,
      isBusy: _isProcessing,
      onAIToggle: (value) => setState(() {
        _useAI = value;
        if (!value) {
          _manualMaskBytes = null;
        }
      }),
      onPickTarget: () => _pickImage(true),
      onPickRef: () => _pickImage(false),
      onManualSelect: _openMaskEditor,
      onStyleChanged: (style) => setState(() => _selectedStyle = style),
      onStrengthChanged: (value) => setState(() => _strength = value),
      onSkinProtectChanged: (value) => setState(() => _skinProtect = value),
      onLumaChanged: (value) => setState(() => _lumaTransfer = value),
      onColorChanged: (value) => setState(() => _colorTransfer = value),
      onContrastChanged: (value) => setState(() => _contrast = value),
      onVignetteChanged: (value) => setState(() => _vignette = value),
      onGrainChanged: (value) => setState(() => _grain = value),
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

    final workspace = StudioCanvasWorkspace(
      state: _state,
      targetBytes: _targetBytes,
      outputBytes: _outputBytes,
      refPath: _refPath,
      isComparing: _isComparing,
      useAI: _useAI,
      hasManualMask: _hasManualMask,
      selectedStyle: _selectedStyle,
      onTapFullScreen: _openFullScreen,
      onPickTarget: () => _pickImage(true),
      onPickReference: () => _pickImage(false),
      onCompareToggle: (value) => setState(() => _isComparing = value),
      onCompareToggleEnd: () => setState(() => _isComparing = false),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? AppTokens.s24 : AppTokens.s16,
              vertical: AppTokens.s8,
            ),
            child: StudioHeaderBar(
              onToggleLocale: widget.onToggleLocale,
              onBack: () => Navigator.of(context).maybePop(),
              canUndo: _canUndo,
              canRedo: _canRedo,
              onUndo: _undoHistory,
              onRedo: _redoHistory,
              onSave: _save,
              onShare: _share,
              hasResult: _hasResult,
              statusLabel: _statusLabel(l10n),
              styleLabel: _selectedStyle,
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppTokens.bg,
              Color.lerp(AppTokens.bg, AppTokens.surface, 0.55) ?? AppTokens.bg,
              AppTokens.surface,
            ],
            stops: const <double>[0.0, 0.45, 1.0],
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _state == EditorState.processing
              ? const StudioProcessingScreen(key: ValueKey('processing'))
              : _state == EditorState.result && _outputBytes != null
                  ? StudioResultScreen(
                      key: const ValueKey('result'),
                      imageBytes: _outputBytes!,
                      selectedStyle: _selectedStyle,
                      useAI: _useAI,
                      hasManualMask: _hasManualMask,
                      onEdit: () => setState(() {
                        _state = EditorState.setup;
                        _isComparing = false;
                      }),
                      onSave: _save,
                      onShare: _share,
                    )
                  : Column(
                      key: const ValueKey('workspace'),
                      children: <Widget>[
            SizedBox(height: MediaQuery.of(context).padding.top + 80),
            Expanded(
              child: showSidebar
                  ? Padding(
                      padding: EdgeInsets.fromLTRB(
                        isDesktop ? AppTokens.s24 : AppTokens.s16,
                        AppTokens.s16,
                        isDesktop ? AppTokens.s24 : AppTokens.s16,
                        AppTokens.s20,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(flex: 7, child: workspace),
                          const SizedBox(width: AppTokens.s24),
                          SizedBox(
                            width: isDesktop ? 396 : 360,
                            child: _buildToolsSidebar(isHorizontal: false),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppTokens.s16,
                              AppTokens.s16,
                              AppTokens.s16,
                              AppTokens.s16,
                            ),
                            child: workspace,
                          ),
                        ),
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppTokens.s24,
                              0,
                              AppTokens.s24,
                              AppTokens.s16,
                            ),
                            child: _MobileFloatingToolbar(
                              onOpenTools: () => _showMobileToolsSheet(context),
                              hasTarget: _hasTarget,
                              isBusy: _isProcessing,
                              onApply: _startProcessing,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _showMobileToolsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.70,
          minChildSize: 0.40,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppTokens.bg,
                border: Border(
                  top: BorderSide(
                    color: AppTokens.border.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTokens.r32),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 40,
                    spreadRadius: 10,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: AppTokens.s12),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTokens.border,
                      borderRadius: BorderRadius.circular(AppTokens.rFull),
                    ),
                  ),
                  const SizedBox(height: AppTokens.s8),
                  Expanded(
                    child: _buildToolsSidebar(
                      isHorizontal: false,
                      scrollController: scrollController,
                    ),
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

class _MobileFloatingToolbar extends StatelessWidget {
  final VoidCallback onOpenTools;
  final bool hasTarget;
  final bool isBusy;
  final VoidCallback onApply;

  const _MobileFloatingToolbar({
    required this.onOpenTools,
    required this.hasTarget,
    required this.isBusy,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.r24),
        border: Border.all(color: AppTokens.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: InkWell(
              onTap: onOpenTools,
              borderRadius: BorderRadius.circular(AppTokens.r16),
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.s8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.tune_rounded,
                      color: AppTokens.text,
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Text(
                      l10n.get('btn_edit'),
                      style: AppTokens.headingM.copyWith(
                        color: AppTokens.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasTarget) ...<Widget>[
            Container(
              width: 1,
              height: 32,
              color: AppTokens.border,
              margin: const EdgeInsets.symmetric(horizontal: AppTokens.s8),
            ),
            IconButton(
              onPressed: isBusy ? null : onApply,
              icon: Icon(
                Icons.auto_fix_high_rounded,
                color: isBusy ? AppTokens.text2 : AppTokens.primary,
              ),
              style: IconButton.styleFrom(
                backgroundColor:
                    isBusy ? AppTokens.surface : AppTokens.primary.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
