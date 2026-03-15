import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/core/ui/AppTokens.dart';
import 'package:lama/presentation/widgets/Steal/Ai%20mask%20generator.dart';
import 'package:lama/presentation/widgets/Steal/DrawnPath.dart';

class MaskEditorScreen extends StatefulWidget {
  final String imagePath;

  const MaskEditorScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<MaskEditorScreen> createState() => _MaskEditorScreenState();
}

class _MaskEditorScreenState extends State<MaskEditorScreen> {
  final List<DrawnPath> _paths = [];
  final List<DrawnPath> _redoStack = [];
  final GlobalKey _imageKey = GlobalKey();

  double _strokeWidth = 30.0;
  bool _isEraser = false;
  bool _isPan = false;
  bool _isProcessingAI = false;
  bool _hasActivatedAi = false;
  Offset? _cursorPos;
  ui.Image? _autoMask;

  bool get _painterUnlocked => _hasActivatedAi && !_isProcessingAI;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _runAI(autoTriggered: true);
      }
    });
  }

  void _undo() {
    if (_paths.isEmpty) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _redoStack.add(_paths.removeLast()));
  }

  void _redo() {
    if (_redoStack.isEmpty) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _paths.add(_redoStack.removeLast()));
  }

  Future<void> _runAI({bool autoTriggered = false}) async {
    if (_isProcessingAI) {
      return;
    }

    if (!autoTriggered) {
      HapticFeedback.heavyImpact();
    }

    setState(() {
      _isProcessingAI = true;
      _hasActivatedAi = true;
    });

    try {
      final aiImg = await generateAiMask(widget.imagePath);
      if (!mounted) {
        return;
      }

      if (aiImg != null) {
        final pngBytes = img.encodePng(aiImg);
        final codec = await ui.instantiateImageCodec(pngBytes);
        final frame = await codec.getNextFrame();
        if (!mounted) {
          return;
        }
        setState(() {
          _autoMask = frame.image;
          _isProcessingAI = false;
        });
        _snack(AppL10n.of(context).get('mask_ai_hint'));
        return;
      }

      setState(() => _isProcessingAI = false);
      _snack(AppL10n.of(context).get('mask_not_found'), isError: true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isProcessingAI = false);
      _snack(AppL10n.of(context).get('mask_not_found'), isError: true);
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_isPan) {
      return;
    }
    if (!_painterUnlocked) {
      _snack(AppL10n.of(context).get('mask_ai_required'), isError: true);
      return;
    }

    final box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }

    final point = box.globalToLocal(details.globalPosition);
    HapticFeedback.lightImpact();
    setState(() {
      _redoStack.clear();
      _cursorPos = details.localPosition;
      _paths.add(
        DrawnPath(
          path: Path()..moveTo(point.dx, point.dy),
          isEraser: _isEraser,
          width: _strokeWidth,
        ),
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isPan || !_painterUnlocked || _paths.isEmpty) {
      return;
    }
    final box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }

    final point = box.globalToLocal(details.globalPosition);
    setState(() {
      _cursorPos = details.localPosition;
      _paths.last.path.lineTo(point.dx, point.dy);
    });
  }

  void _onPanEnd(DragEndDetails _) {
    if (_isPan || !_painterUnlocked) {
      return;
    }
    setState(() {
      _cursorPos = null;
      if (_paths.isNotEmpty) {
        _paths.last.isFinished = true;
      }
    });
  }

  Future<void> _save() async {
    if (_paths.isEmpty && _autoMask == null) {
      _snack(AppL10n.of(context).get('mask_no_draw'), isError: true);
      return;
    }

    _snack(AppL10n.of(context).get('mask_saving'));
    HapticFeedback.heavyImpact();

    try {
      final box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) {
        return;
      }
      final originalBytes = await File(widget.imagePath).readAsBytes();
      final originalImage = img.decodeImage(originalBytes);
      if (originalImage == null) {
        if (mounted) {
          _snack(AppL10n.of(context).get('mask_error'), isError: true);
        }
        return;
      }

      final size = box.size;
      final outputWidth = originalImage.width;
      final outputHeight = originalImage.height;
      final scaleX = outputWidth / size.width;
      final scaleY = outputHeight / size.height;
      final strokeScale = (scaleX + scaleY) * 0.5;
      final transform = Matrix4.diagonal3Values(scaleX, scaleY, 1).storage;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
      );

      canvas.drawRect(
        Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
        Paint()..color = Colors.black,
      );

      if (_autoMask != null) {
        paintImage(
          canvas: canvas,
          rect: Rect.fromLTWH(
              0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
          image: _autoMask!,
          fit: BoxFit.contain,
        );
      }

      for (final path in _paths) {
        final scaledPath = path.path.transform(transform);
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = path.width * strokeScale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        if (path.isEraser) {
          paint.color = Colors.black;
          paint.blendMode = BlendMode.srcOver;
        } else {
          paint.color = Colors.white;
        }
        canvas.drawPath(scaledPath, paint);
      }

      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(outputWidth, outputHeight);
      final byteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);

      if (mounted && byteData != null) {
        final rawBytes = byteData.buffer.asUint8List();
        final decodedMask = img.decodePng(rawBytes);
        if (decodedMask != null) {
          final softenedMask = img.gaussianBlur(decodedMask, radius: 1);
          Navigator.pop(
              context, Uint8List.fromList(img.encodePng(softenedMask)));
          return;
        }
        Navigator.pop(context, rawBytes);
      }
    } catch (e) {
      if (mounted) {
        _snack('${AppL10n.of(context).get('mask_error')}: $e', isError: true);
      }
    }
  }

  void _clearAll() {
    HapticFeedback.mediumImpact();
    setState(() {
      _paths.clear();
      _redoStack.clear();
      _autoMask = null;
    });
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(
            color: isError ? AppTokens.danger : AppTokens.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTokens.surface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final canUndo = _paths.isNotEmpty;
    final canRedo = _redoStack.isNotEmpty;
    final canSave = _paths.isNotEmpty || _autoMask != null;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        title: Text(
          l10n.get('mask_title'),
          style: AppTokens.headingM.copyWith(fontWeight: FontWeight.w900),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppTokens.s12),
            child: InkWell(
              onTap: canSave ? _save : null,
              borderRadius: BorderRadius.circular(AppTokens.rFull),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: canSave ? AppTokens.primaryGradient : null,
                  color: canSave ? null : AppTokens.card,
                  borderRadius: BorderRadius.circular(AppTokens.rFull),
                ),
                child: Text(
                  l10n.get('btn_save'),
                  style: TextStyle(
                    color: canSave ? Colors.black : AppTokens.text2,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppTokens.s16,
                AppTokens.s16,
                AppTokens.s16,
                bottomInset + 166,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTokens.surfaceGradient,
                  borderRadius: BorderRadius.circular(AppTokens.r24),
                  border: Border.all(color: AppTokens.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.r24),
                  child: InteractiveViewer(
                    panEnabled: _isPan,
                    scaleEnabled: _isPan,
                    minScale: 0.8,
                    maxScale: 6.0,
                    child: Center(
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.file(
                              File(widget.imagePath),
                              key: _imageKey,
                              fit: BoxFit.contain,
                            ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _MaskPainter(
                                  paths: _paths,
                                  autoMask: _autoMask,
                                ),
                              ),
                            ),
                            if (_cursorPos != null &&
                                !_isPan &&
                                _painterUnlocked)
                              Positioned(
                                left: _cursorPos!.dx - _strokeWidth / 2,
                                top: _cursorPos!.dy - _strokeWidth / 2,
                                child: IgnorePointer(
                                  child: Container(
                                    width: _strokeWidth,
                                    height: _strokeWidth,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                      color: _isEraser
                                          ? Colors.black.withOpacity(0.55)
                                          : AppTokens.warning.withOpacity(0.35),
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
            ),
          ),
          Positioned(
            top: AppTokens.s16,
            left: AppTokens.s16,
            right: AppTokens.s16,
            child: _GuideCard(
              title: _isProcessingAI
                  ? l10n.get('mask_booting')
                  : _painterUnlocked
                      ? l10n.get('mask_ready')
                      : l10n.get('mask_unlock_hint'),
              subtitle: l10n.get('workspace_tip'),
              active: _painterUnlocked,
              processing: _isProcessingAI,
            ),
          ),
          if (_isProcessingAI)
            const ColoredBox(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: AppTokens.primary),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppTokens.s16,
                AppTokens.s16,
                AppTokens.s16,
                bottomInset + AppTokens.s16,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.r24),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTokens.s14),
                    decoration: BoxDecoration(
                      color: AppTokens.surface.withOpacity(0.88),
                      borderRadius: BorderRadius.circular(AppTokens.r24),
                      border: Border.all(color: AppTokens.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _painterUnlocked
                                  ? Icons.brush_rounded
                                  : Icons.auto_awesome_rounded,
                              color: _painterUnlocked
                                  ? AppTokens.warning
                                  : AppTokens.primary,
                              size: 18,
                            ),
                            const SizedBox(width: AppTokens.s8),
                            Expanded(
                              child: Text(
                                _painterUnlocked
                                    ? l10n.get('mask_ready')
                                    : l10n.get('mask_unlock_hint'),
                                style: AppTokens.caption.copyWith(
                                  color: AppTokens.text,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.s10),
                        Row(
                          children: [
                            const Icon(
                              Icons.circle,
                              color: AppTokens.text2,
                              size: 10,
                            ),
                            Expanded(
                              child: Slider(
                                value: _strokeWidth,
                                min: 5,
                                max: 80,
                                onChanged: (value) =>
                                    setState(() => _strokeWidth = value),
                              ),
                            ),
                            const Icon(
                              Icons.circle,
                              color: AppTokens.text2,
                              size: 22,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.s8),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppTokens.s8,
                          runSpacing: AppTokens.s8,
                          children: [
                            _ToolBtn(
                              icon: Icons.auto_fix_high_rounded,
                              color: AppTokens.primary,
                              active: _hasActivatedAi || _isProcessingAI,
                              tooltip: 'AI Auto',
                              onTap: () => _runAI(),
                            ),
                            _ToolBtn(
                              icon: Icons.undo_rounded,
                              color: AppTokens.primary,
                              active: canUndo,
                              tooltip: l10n.get('btn_undo'),
                              onTap: canUndo ? _undo : null,
                            ),
                            _ToolBtn(
                              icon: Icons.redo_rounded,
                              color: AppTokens.primary,
                              active: canRedo,
                              tooltip: l10n.get('btn_redo'),
                              onTap: canRedo ? _redo : null,
                            ),
                            _ToolBtn(
                              icon: Icons.brush_rounded,
                              color: AppTokens.warning,
                              active: !_isEraser && !_isPan && _painterUnlocked,
                              tooltip: 'Brush',
                              onTap: _painterUnlocked
                                  ? () => setState(() {
                                        _isEraser = false;
                                        _isPan = false;
                                      })
                                  : () => _snack(
                                        l10n.get('mask_ai_required'),
                                        isError: true,
                                      ),
                            ),
                            _ToolBtn(
                              icon: Icons.cleaning_services_rounded,
                              color: AppTokens.danger,
                              active: _isEraser && !_isPan && _painterUnlocked,
                              tooltip: 'Eraser',
                              onTap: _painterUnlocked
                                  ? () => setState(() {
                                        _isEraser = true;
                                        _isPan = false;
                                      })
                                  : () => _snack(
                                        l10n.get('mask_ai_required'),
                                        isError: true,
                                      ),
                            ),
                            _ToolBtn(
                              icon: Icons.pan_tool_rounded,
                              color: AppTokens.info,
                              active: _isPan,
                              tooltip: 'Pan',
                              onTap: () => setState(() => _isPan = !_isPan),
                            ),
                            _ToolBtn(
                              icon: Icons.delete_sweep_rounded,
                              color: AppTokens.danger,
                              active: false,
                              tooltip: 'Clear',
                              onTap: _clearAll,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool active;
  final bool processing;

  const _GuideCard({
    required this.title,
    required this.subtitle,
    required this.active,
    required this.processing,
  });

  @override
  Widget build(BuildContext context) {
    final color = processing
        ? AppTokens.primary
        : active
            ? AppTokens.warning
            : AppTokens.text2;

    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(AppTokens.r20),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
            child: Icon(
              processing ? Icons.auto_awesome_rounded : Icons.brush_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTokens.s10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTokens.labelBold.copyWith(
                    color: AppTokens.text,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTokens.caption.copyWith(
                    color: AppTokens.text2,
                    fontSize: 11.5,
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

class _MaskPainter extends CustomPainter {
  final List<DrawnPath> paths;
  final ui.Image? autoMask;

  const _MaskPainter({
    required this.paths,
    this.autoMask,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    if (autoMask != null) {
      paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(0, 0, size.width, size.height),
        image: autoMask!,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(
          AppTokens.warning.withOpacity(0.55),
          BlendMode.srcIn,
        ),
      );
    }

    for (final path in paths) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = path.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (path.isEraser) {
        paint.blendMode = BlendMode.clear;
      } else {
        paint.color = AppTokens.warning.withOpacity(0.68);
      }
      canvas.drawPath(path.path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MaskPainter oldDelegate) => true;
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool active;
  final String tooltip;
  final VoidCallback? onTap;

  const _ToolBtn({
    required this.icon,
    required this.color,
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r16),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.15) : AppTokens.card,
            borderRadius: BorderRadius.circular(AppTokens.r16),
            border: Border.all(
              color: active ? color.withOpacity(0.35) : AppTokens.border,
            ),
          ),
          child: Icon(
            icon,
            color:
                enabled ? (active ? color : AppTokens.text2) : AppTokens.border,
            size: 22,
          ),
        ),
      ),
    );
  }
}
