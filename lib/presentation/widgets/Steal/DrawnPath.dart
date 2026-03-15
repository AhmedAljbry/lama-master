import 'package:flutter/painting.dart';

/// Represents a single drawn brush stroke in the mask editor.
class DrawnPath {
  final Path   path;
  final bool   isEraser;
  final double width;
  bool isFinished;

  DrawnPath({
    required this.path,
    required this.isEraser,
    required this.width,
    this.isFinished = false,
  });
}
