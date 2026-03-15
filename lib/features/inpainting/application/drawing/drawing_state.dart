import 'package:flutter/material.dart';
import 'stroke.dart';

class DrawingState {
  final List<Stroke> strokes;
  final List<Stroke> redoStack;

  final StrokeMode mode;

  // UI
  final double brushSize; // px
  final bool showCursor;
  final Offset? cursorPoint;

  // ✅ NEW: الفرشة الموحدة للنظام الجديد
  final BrushSettings brush;

  const DrawingState({
    required this.strokes,
    required this.redoStack,
    required this.mode,
    required this.brushSize,
    required this.showCursor,
    required this.cursorPoint,
    required this.brush,
  });

  bool get canUndo => strokes.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  DrawingState copyWith({
    List<Stroke>? strokes,
    List<Stroke>? redoStack,
    StrokeMode? mode,
    double? brushSize,
    bool? showCursor,
    Offset? cursorPoint,
    BrushSettings? brush,
  }) {
    return DrawingState(
      strokes: strokes ?? this.strokes,
      redoStack: redoStack ?? this.redoStack,
      mode: mode ?? this.mode,
      brushSize: brushSize ?? this.brushSize,
      showCursor: showCursor ?? this.showCursor,
      cursorPoint: cursorPoint ?? this.cursorPoint,
      brush: brush ?? this.brush,
    );
  }

  factory DrawingState.initial() => DrawingState(
        strokes: const [],
        redoStack: const [],
        mode: StrokeMode.brush,
        brushSize: 32,
        showCursor: false,
        cursorPoint: null,

        // ✅ default brush (اختيار منطقي)
        brush: const BrushSettings(
          kind: BrushKind.solid,
          width01: 0.05,
          color: Color.fromARGB(180, 255, 64, 129),
          softness: 0.0,
        ),
      );
}
