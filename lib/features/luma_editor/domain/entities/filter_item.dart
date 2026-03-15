import 'package:flutter/material.dart';

class FilterItem {
  final String id;
  final String name;
  final List<double> matrix;
  final Color indicatorColor;
  final bool isCustom;
  final bool isFavorite;
  final int createdAtMs;

  const FilterItem({
    required this.id,
    required this.name,
    required this.matrix,
    required this.indicatorColor,
    this.isCustom = false,
    this.isFavorite = false,
    this.createdAtMs = 0,
  });

  FilterItem copyWith({
    String? id,
    String? name,
    List<double>? matrix,
    Color? indicatorColor,
    bool? isCustom,
    bool? isFavorite,
    int? createdAtMs,
  }) {
    return FilterItem(
      id: id ?? this.id,
      name: name ?? this.name,
      matrix: matrix ?? this.matrix,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      isCustom: isCustom ?? this.isCustom,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'matrix': matrix,
        'indicatorColor': _colorToArgb(indicatorColor),
        'isCustom': isCustom,
        'isFavorite': isFavorite,
        'createdAtMs': createdAtMs,
      };

  static FilterItem fromJson(Map<String, dynamic> json) {
    return FilterItem(
      id: json['id'] as String,
      name: json['name'] as String,
      matrix: (json['matrix'] as List).map((e) => (e as num).toDouble()).toList(),
      indicatorColor: Color(json['indicatorColor'] as int),
      isCustom: (json['isCustom'] as bool?) ?? true,
      isFavorite: (json['isFavorite'] as bool?) ?? false,
      createdAtMs: (json['createdAtMs'] as int?) ?? 0,
    );
  }

  static int _colorToArgb(Color color) {
    final alpha = (color.a * 255).round();
    final red = (color.r * 255).round();
    final green = (color.g * 255).round();
    final blue = (color.b * 255).round();
    return (alpha << 24) | (red << 16) | (green << 8) | blue;
  }
}
