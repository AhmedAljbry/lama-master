import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:lama/core/i18n/t.dart';
import 'package:lama/core/routing/app_routes.dart';
import 'package:lama/core/ui/cover_mapping.dart';
import 'package:lama/core/ui/mask_exporter.dart';
import 'package:lama/core/ui/mask_postprocess.dart';
import 'package:lama/features/inpainting/application/drawing/drawing_cubit.dart';
import 'package:lama/features/inpainting/application/drawing/drawing_state.dart';
import 'package:lama/features/inpainting/application/drawing/stroke.dart';
import 'package:lama/features/inpainting/application/image_pick_cubit.dart';
import 'package:lama/features/inpainting/application/inpainting_bloc/inpainting_bloc.dart';
import 'package:lama/features/inpainting/application/inpainting_bloc/inpainting_event.dart';
import 'package:lama/features/inpainting/presentation/widgets/ask_strokes_painter.dart';
import 'package:lama/features/inpainting/presentation/widgets/brush_cursor.dart';
import 'package:lama/features/inpainting/presentation/widgets/fixed_brush_magnifier.dart';
import 'package:lama/features/inpainting/presentation/widgets/image_painter.dart';
import 'package:lama/features/inpainting/presentation/widgets/inpainting_brush_controls.dart';
import 'package:lama/features/inpainting/presentation/widgets/inpainting_editor_toolbar.dart';
import 'package:lama/features/inpainting/presentation/widgets/inpainting_studio_chrome.dart';

part 'editor_page_ui_helpers.part.dart';
part 'editor_page_gestures.part.dart';
part 'editor_page_mask_render.part.dart';
part 'editor_page_mask_qa.part.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage>
    with SingleTickerProviderStateMixin {
  static const double _minViewportScale = 1.0;
  static const double _maxViewportScale = 6.0;

  final GlobalKey _stackKey = GlobalKey();
  final TransformationController _viewportController =
      TransformationController();

  bool _isPreparing = false;
  bool _showMaskOverlay = true;
  bool _showOriginalPreview = false;
  late AnimationController _glowController;

  Offset? _cursorPoint;
  Offset? _magnifierImagePoint;
  bool _isDrawingStroke = false;
  bool _isViewportGestureActive = false;
  int _activePointers = 0;
  double _gestureBaseScale = 1.0;
  Offset? _gestureSceneFocalPoint;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _viewportController.dispose();
    super.dispose();
  }

  void _updateEditorUi(VoidCallback updates) {
    if (!mounted) {
      return;
    }
    setState(updates);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<T>();
    final pickState = context.watch<ImagePickCubit>().state;

    if (pickState is! ImagePickReady) {
      return _buildErrorState(
        InpaintingStudioTheme.background,
        InpaintingStudioTheme.textPrimary,
        t,
        InpaintingStudioTheme.mint,
      );
    }

    final image = pickState.uiImage;

    return Scaffold(
      backgroundColor: InpaintingStudioTheme.background,
      body: StudioGlowBackground(
        animation: _glowController,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWideLayout = constraints.maxWidth >= 1040;
              final compactToolbar = constraints.maxWidth < 720;
              final horizontalPadding =
                  constraints.maxWidth < 460 ? 12.0 : 20.0;
              final verticalPadding = constraints.maxHeight < 760 ? 10.0 : 16.0;
              final sidePanelWidth =
                  math.min(386.0, constraints.maxWidth * 0.31);
              final bottomPanelHeight = math.min(
                340.0,
                math.max(248.0, constraints.maxHeight * 0.34),
              );

              return Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      verticalPadding,
                      horizontalPadding,
                      math.max(verticalPadding, 12),
                    ),
                    child: Column(
                      children: [
                        BlocBuilder<DrawingCubit, DrawingState>(
                          buildWhen: (previous, current) =>
                              previous.canUndo != current.canUndo ||
                              previous.canRedo != current.canRedo ||
                              previous.strokes.length != current.strokes.length,
                          builder: (context, drawingState) {
                            return InpaintingEditorToolbar(
                              title: t.of('magic_title'),
                              subtitle: drawingState.strokes.isEmpty
                                  ? t.of('editor_tip_run')
                                  : t.of('editor_tip_precision'),
                              statusLabel: drawingState.strokes.isEmpty
                                  ? t.of('editor_mask_pending')
                                  : t.of('editor_mask_ready'),
                              hasMask: drawingState.strokes.isNotEmpty,
                              compareEnabled: _showOriginalPreview,
                              canUndo: drawingState.canUndo,
                              canRedo: drawingState.canRedo,
                              compact: compactToolbar,
                              onBack: _handleBackNavigation,
                              onHelp: () => _showEditorHelpSheet(context, t),
                              onUndo: () => context.read<DrawingCubit>().undo(),
                              onRedo: () => context.read<DrawingCubit>().redo(),
                              onClear: () =>
                                  context.read<DrawingCubit>().clear(),
                              onToggleCompare: _toggleComparePreview,
                              undoLabel: t.of('undo'),
                              redoLabel: t.of('redo'),
                              clearLabel: t.of('clear'),
                              compareLabel: t.of('compare'),
                              compareActiveLabel: t.of('compare_live'),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: isWideLayout
                              ? Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _buildWorkspaceCard(
                                        context: context,
                                        t: t,
                                        image: image,
                                        compact: false,
                                      ),
                                    ),
                                    const SizedBox(width: 18),
                                    SizedBox(
                                      width: sidePanelWidth,
                                      child: _buildControlsPanel(
                                        context: context,
                                        t: t,
                                        layout:
                                            InpaintingControlsLayout.sideDock,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Expanded(
                                      child: _buildWorkspaceCard(
                                        context: context,
                                        t: t,
                                        image: image,
                                        compact: true,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: bottomPanelHeight,
                                      ),
                                      child: _buildControlsPanel(
                                        context: context,
                                        t: t,
                                        layout:
                                            InpaintingControlsLayout.bottomDock,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  if (_isPreparing) _buildPreparingOverlay(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspaceCard({
    required BuildContext context,
    required T t,
    required ui.Image image,
    required bool compact,
  }) {
    return BlocBuilder<DrawingCubit, DrawingState>(
      builder: (context, drawingState) {
        return StudioGlassPanel(
          radius: compact ? 28 : 34,
          padding: EdgeInsets.all(compact ? 12 : 16),
          fillColor: InpaintingStudioTheme.surfaceSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWorkspaceHeader(
                t: t,
                drawingState: drawingState,
                compact: compact,
              ),
              if (_showOriginalPreview || !_showMaskOverlay) ...[
                const SizedBox(height: 12),
                _buildWorkspaceNotice(t: t),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasSize = constraints.biggest;
                    final isCompactHud =
                        compact || canvasSize.shortestSide < 360;
                    final magnifierDiameter = math.min(
                      math.max(canvasSize.shortestSide * 0.3, 104.0),
                      isCompactHud ? 116.0 : 150.0,
                    );
                    final brushWidthImagePx = _brushWidgetPxToImagePx(
                      drawingState.brushSize,
                      canvasSize,
                      image.width,
                      image.height,
                    );

                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(compact ? 26 : 30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 34,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(compact ? 26 : 30),
                            child: Listener(
                              onPointerDown: (_) => _handlePointerDown(context),
                              onPointerUp: (_) => _handlePointerEnd(),
                              onPointerCancel: (_) => _handlePointerEnd(),
                              onPointerSignal: (event) =>
                                  _onPointerSignal(event, canvasSize),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onScaleStart: (details) =>
                                    _onScaleStart(context, details, canvasSize),
                                onScaleUpdate: (details) => _onScaleUpdate(
                                    context, details, canvasSize),
                                onScaleEnd: (_) => _onScaleEnd(context),
                                onDoubleTap: _resetViewport,
                                child: ColoredBox(
                                  color: const Color(0xFF061017),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: ValueListenableBuilder<Matrix4>(
                                          valueListenable: _viewportController,
                                          builder: (context, matrix, child) {
                                            return ClipRect(
                                              child: Transform(
                                                transform: matrix,
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: SizedBox(
                                            key: _stackKey,
                                            width: canvasSize.width,
                                            height: canvasSize.height,
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                RepaintBoundary(
                                                  child: CustomPaint(
                                                    painter: ImagePainter(
                                                      image,
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                ),
                                                Positioned.fill(
                                                  child: IgnorePointer(
                                                    child: AnimatedOpacity(
                                                      duration: const Duration(
                                                        milliseconds: 180,
                                                      ),
                                                      opacity: _showMaskOverlay &&
                                                              !_showOriginalPreview
                                                          ? 1
                                                          : 0,
                                                      child: RepaintBoundary(
                                                        child: CustomPaint(
                                                          painter:
                                                              MaskStrokesPainter(
                                                            strokes:
                                                                drawingState
                                                                    .strokes,
                                                            isPreview: true,
                                                            imageW: image.width,
                                                            imageH:
                                                                image.height,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: _buildEditorStatusCard(
                                          t: t,
                                          drawingState: drawingState,
                                          imageWidth: image.width,
                                          imageHeight: image.height,
                                          compact: isCompactHud,
                                        ),
                                      ),
                                      if (_cursorPoint != null &&
                                          !_isViewportGestureActive &&
                                          !_showOriginalPreview)
                                        BrushCursor(
                                          point: _cursorPoint,
                                          size: drawingState.brushSize,
                                          visible: true,
                                          kind: drawingState.brush.kind,
                                        ),
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            ValueListenableBuilder<Matrix4>(
                                              valueListenable:
                                                  _viewportController,
                                              builder:
                                                  (context, matrix, child) {
                                                return _buildZoomBadge(
                                                  scale: matrix
                                                      .getMaxScaleOnAxis(),
                                                  accentColor:
                                                      InpaintingStudioTheme
                                                          .mint,
                                                  compact: isCompactHud,
                                                );
                                              },
                                            ),
                                            if (_showOriginalPreview ||
                                                !_showMaskOverlay) ...[
                                              const SizedBox(height: 8),
                                              StudioPill(
                                                icon: _showOriginalPreview
                                                    ? Icons.compare_rounded
                                                    : Icons
                                                        .visibility_off_rounded,
                                                label: _showOriginalPreview
                                                    ? t.of('original_label')
                                                    : t.of('workflow_mask'),
                                                accent: _showOriginalPreview
                                                    ? InpaintingStudioTheme.cyan
                                                    : InpaintingStudioTheme
                                                        .amber,
                                                filled: true,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        left: 12,
                                        bottom: 12,
                                        child: _buildGestureHint(
                                          t: t,
                                          compact: isCompactHud,
                                        ),
                                      ),
                                      Positioned(
                                        right: 12,
                                        bottom: 12,
                                        child: _buildCanvasActionRail(
                                          compact: isCompactHud,
                                          onResetViewport: _resetViewport,
                                          fitTooltip:
                                              t.of('editor_workspace_fit'),
                                          onShowQa: !const bool.fromEnvironment(
                                            'dart.vm.product',
                                          )
                                              ? _testMaskRendering
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_magnifierImagePoint != null &&
                            !_isViewportGestureActive &&
                            !_showOriginalPreview)
                          Positioned(
                            top: 18,
                            left: 18,
                            child: IgnorePointer(
                              child: FixedBrushMagnifier(
                                image: image,
                                strokes: drawingState.strokes,
                                focusImagePoint: _magnifierImagePoint!,
                                brushWidthImagePx: brushWidthImagePx,
                                brushKind: drawingState.brush.kind,
                                diameter: magnifierDiameter,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkspaceHeader({
    required T t,
    required DrawingState drawingState,
    required bool compact,
  }) {
    final toolAccent = drawingState.brush.kind == BrushKind.eraser
        ? InpaintingStudioTheme.rose
        : InpaintingStudioTheme.mint;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.of('editor_title'),
                style: TextStyle(
                  color: InpaintingStudioTheme.textPrimary,
                  fontSize: compact ? 18 : 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _showOriginalPreview
                    ? t.of('compare_live')
                    : drawingState.strokes.isEmpty
                        ? t.of('editor_tip_run')
                        : t.of('editor_tip_precision'),
                style: TextStyle(
                  color: InpaintingStudioTheme.textSecondary,
                  fontSize: compact ? 12.5 : 13.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 160 : 250),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              StudioPill(
                icon: drawingState.brush.kind == BrushKind.eraser
                    ? Icons.auto_fix_off_rounded
                    : Icons.brush_rounded,
                label: drawingState.brush.kind == BrushKind.eraser
                    ? t.of('eraser')
                    : t.of('brush'),
                accent: toolAccent,
                filled: true,
              ),
              ValueListenableBuilder<Matrix4>(
                valueListenable: _viewportController,
                builder: (context, matrix, child) {
                  final zoom = matrix.getMaxScaleOnAxis();
                  return StudioPill(
                    icon: Icons.zoom_in_map_rounded,
                    label: 'x${zoom.toStringAsFixed(zoom < 2 ? 1 : 2)}',
                    accent: InpaintingStudioTheme.cyan,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspaceNotice({required T t}) {
    final accent = _showOriginalPreview
        ? InpaintingStudioTheme.cyan
        : InpaintingStudioTheme.amber;
    final icon = _showOriginalPreview
        ? Icons.compare_rounded
        : Icons.visibility_off_rounded;
    final message = _showOriginalPreview
        ? '${t.of('compare_live')} | ${t.of('original_label')}'
        : '${t.of('workflow_mask')} | ${t.of('compare_live')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: InpaintingStudioTheme.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsPanel({
    required BuildContext context,
    required T t,
    required InpaintingControlsLayout layout,
  }) {
    return ValueListenableBuilder<Matrix4>(
      valueListenable: _viewportController,
      builder: (context, matrix, child) {
        return BlocBuilder<DrawingCubit, DrawingState>(
          builder: (context, drawingState) {
            return InpaintingBrushControls(
              t: t,
              layout: layout,
              isEraser: drawingState.brush.kind == BrushKind.eraser,
              hasMask: drawingState.strokes.isNotEmpty,
              canUndo: drawingState.canUndo,
              canRedo: drawingState.canRedo,
              maskVisible: _showMaskOverlay,
              compareEnabled: _showOriginalPreview,
              brushPx: drawingState.brushSize,
              currentZoom: matrix.getMaxScaleOnAxis(),
              strokeCount: drawingState.strokes.length,
              onBrushMode: () =>
                  context.read<DrawingCubit>().setBrushKind(BrushKind.solid),
              onEraserMode: () =>
                  context.read<DrawingCubit>().setBrushKind(BrushKind.eraser),
              onUndo: () => context.read<DrawingCubit>().undo(),
              onRedo: () => context.read<DrawingCubit>().redo(),
              onClear: () => context.read<DrawingCubit>().clear(),
              onResetWorkspace: () => _resetWorkspace(context),
              onResetViewport: _resetViewport,
              onMagic: () =>
                  _runMagicPipeline(context, _imageFromPick(context), t),
              onToggleMaskVisibility: _toggleMaskVisibility,
              onToggleCompare: _toggleComparePreview,
              onBrushSizeChanged: (value) =>
                  context.read<DrawingCubit>().setBrush(value),
            );
          },
        );
      },
    );
  }

  ui.Image _imageFromPick(BuildContext context) {
    final pickState = context.read<ImagePickCubit>().state;
    return (pickState as ImagePickReady).uiImage;
  }

  void _toggleMaskVisibility() {
    _updateEditorUi(() {
      _showMaskOverlay = !_showMaskOverlay;
    });
  }

  void _toggleComparePreview() {
    if (_isDrawingStroke) {
      context.read<DrawingCubit>().endStroke();
    }
    _updateEditorUi(() {
      _showOriginalPreview = !_showOriginalPreview;
      _cursorPoint = null;
      _magnifierImagePoint = null;
      _isDrawingStroke = false;
    });
  }

  void _resetWorkspace(BuildContext context) {
    context.read<DrawingCubit>().clear();
    _resetViewport();
    _updateEditorUi(() {
      _showMaskOverlay = true;
      _showOriginalPreview = false;
      _cursorPoint = null;
      _magnifierImagePoint = null;
      _isDrawingStroke = false;
    });
  }

  void _handleBackNavigation() {
    context.read<ImagePickCubit>().reset();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.magicEraser);
    }
  }

  Future<void> _showEditorHelpSheet(BuildContext context, T t) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: StudioGlassPanel(
            radius: 30,
            padding: const EdgeInsets.all(20),
            fillColor: InpaintingStudioTheme.surfaceSoft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: InpaintingStudioTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.auto_fix_high_rounded,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.of('magic_title'),
                        style: const TextStyle(
                          color: InpaintingStudioTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _HelpStep(
                  index: '01',
                  accent: InpaintingStudioTheme.cyan,
                  title: t.of('workflow_upload'),
                  body: t.of('pick_hint'),
                ),
                const SizedBox(height: 12),
                _HelpStep(
                  index: '02',
                  accent: InpaintingStudioTheme.violet,
                  title: t.of('workflow_mask'),
                  body: t.of('editor_tip_precision'),
                ),
                const SizedBox(height: 12),
                _HelpStep(
                  index: '03',
                  accent: InpaintingStudioTheme.mint,
                  title: t.of('workflow_render'),
                  body: t.of('magic_pick_feature_quality'),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: StudioSecondaryButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: Icons.check_rounded,
                    label: t.of('cancel'),
                    accent: InpaintingStudioTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreparingOverlay() {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: InpaintingStudioTheme.background.withValues(alpha: 0.52),
            ),
            child: const Center(
              child: StudioGlassPanel(
                radius: 999,
                padding: EdgeInsets.all(24),
                gradient: InpaintingStudioTheme.accentGradient,
                borderColor: Colors.transparent,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpStep extends StatelessWidget {
  final String index;
  final Color accent;
  final String title;
  final String body;

  const _HelpStep({
    required this.index,
    required this.accent,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                index,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 11.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: InpaintingStudioTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    color: InpaintingStudioTheme.textSecondary,
                    fontSize: 12.5,
                    height: 1.45,
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
