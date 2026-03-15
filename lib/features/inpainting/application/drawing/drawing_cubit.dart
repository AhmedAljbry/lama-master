import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'drawing_state.dart';
import 'stroke.dart';

class DrawingCubit extends Cubit<DrawingState> {
  DrawingCubit() : super(DrawingState.initial());

  // ── Mode ────────────────────────────────────────────────────
  void setMode(StrokeMode mode) {
    emit(state.copyWith(
      mode: mode,
      brush: state.brush.copyWith(
        kind: mode == StrokeMode.eraser
            ? BrushKind.eraser
            : _nonEraserKind(state.brush.kind),
      ),
    ));
  }

  void setBrushKind(BrushKind kind) {
    emit(state.copyWith(
      mode: kind == BrushKind.eraser ? StrokeMode.eraser : StrokeMode.brush,
      brush: state.brush.copyWith(kind: kind),
    ));
  }

  // ── Brush size ───────────────────────────────────────────────
  void setBrush(double screenPx) {
    emit(state.copyWith(
      brushSize: screenPx,
      brush: state.brush.copyWith(width01: _px2w01(screenPx)),
    ));
  }

  void setBrushWidth01(double width01) {
    final w = width01.clamp(0.001, 0.5);
    emit(state.copyWith(
      brushSize: _w012px(w),
      brush: state.brush.copyWith(width01: w),
    ));
  }

  // ── Cursor ───────────────────────────────────────────────────
  void showCursorAt(Offset p) =>
      emit(state.copyWith(showCursor: true, cursorPoint: p));
  void hideCursor() => emit(state.copyWith(showCursor: false));

  // ── Strokes (IMAGE-PIXEL coordinates) ───────────────────────

  /// Start a new stroke. [widthPx] is in IMAGE pixels (not screen pixels).
  void startStrokeImagePx(Offset imagePoint, {required double widthPx}) {
    final s = Stroke(
      pts: [imagePoint],
      // ✅ raised cap to 600 (was 400 → still caused issues for large images)
      width: widthPx.clamp(1.0, 600.0),
      mode: state.mode,
    );
    emit(state.copyWith(
      strokes: [...state.strokes, s],
      redoStack: const [],
    ));
  }

  void addPointImagePx(Offset imagePoint) {
    if (state.strokes.isEmpty) return;
    final list = List<Stroke>.from(state.strokes);
    final last = list.removeLast();

    final previousPoint = last.pts.last;
    final dx = previousPoint.dx - imagePoint.dx;
    final dy = previousPoint.dy - imagePoint.dy;
    final minDistance = (last.width * 0.08).clamp(1.2, 4.0);
    if ((dx * dx) + (dy * dy) < (minDistance * minDistance)) {
      return;
    }

    list.add(last.copyWith(pts: [...last.pts, imagePoint]));
    emit(state.copyWith(strokes: list));
  }

  void endStroke() => emit(state.copyWith(showCursor: false));

  // ── Undo / Redo / Clear ──────────────────────────────────────
  void undo() {
    if (state.strokes.isEmpty) return;
    final list = List<Stroke>.from(state.strokes);
    final last = list.removeLast();
    emit(state.copyWith(
      strokes: list,
      redoStack: [...state.redoStack, last],
    ));
  }

  void redo() {
    if (state.redoStack.isEmpty) return;
    final redo = List<Stroke>.from(state.redoStack);
    final last = redo.removeLast();
    emit(state.copyWith(
      strokes: [...state.strokes, last],
      redoStack: redo,
    ));
  }

  void clear() => emit(state.copyWith(
        strokes: const [],
        redoStack: const [],
        showCursor: false,
        cursorPoint: null,
      ));

  // ── Helpers ──────────────────────────────────────────────────
  BrushKind _nonEraserKind(BrushKind k) =>
      k == BrushKind.eraser ? BrushKind.solid : k;

  double _px2w01(double px) {
    const minPx = 8.0, maxPx = 120.0;
    const min01 = 0.01, max01 = 0.25;
    final t = ((px - minPx) / (maxPx - minPx)).clamp(0.0, 1.0);
    return (min01 + (max01 - min01) * t).clamp(min01, max01);
  }

  double _w012px(double w01) {
    const minPx = 8.0, maxPx = 120.0;
    const min01 = 0.01, max01 = 0.25;
    final t = ((w01 - min01) / (max01 - min01)).clamp(0.0, 1.0);
    return (minPx + (maxPx - minPx) * t).clamp(minPx, maxPx);
  }
}
