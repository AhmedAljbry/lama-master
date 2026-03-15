import 'dart:typed_data';

import 'package:lama/features/luma_editor/domain/entities/editor_snapshot.dart';
import 'package:lama/features/luma_editor/domain/entities/filter_item.dart';

class EditorState {
  final String? imagePath;
  final Uint8List? imageBytes;
  final List<FilterItem> filters;
  final List<FilterItem> filtersSorted;
  final Set<String> favoriteIds;
  final EditorSnapshot snapshot;
  final List<EditorSnapshot> undo;
  final List<EditorSnapshot> redo;
  final bool compareMode;
  final bool isSaving;
  final EditorSnapshot? clipboard;

  const EditorState({
    required this.imagePath,
    required this.imageBytes,
    required this.filters,
    required this.filtersSorted,
    required this.favoriteIds,
    required this.snapshot,
    required this.undo,
    required this.redo,
    required this.compareMode,
    required this.isSaving,
    required this.clipboard,
  });

  bool get hasImage => imagePath != null;

  EditorState copyWith({
    String? imagePath,
    Uint8List? imageBytes,
    List<FilterItem>? filters,
    List<FilterItem>? filtersSorted,
    Set<String>? favoriteIds,
    EditorSnapshot? snapshot,
    List<EditorSnapshot>? undo,
    List<EditorSnapshot>? redo,
    bool? compareMode,
    bool? isSaving,
    EditorSnapshot? clipboard,
  }) {
    return EditorState(
      imagePath: imagePath ?? this.imagePath,
      imageBytes: imageBytes ?? this.imageBytes,
      filters: filters ?? this.filters,
      filtersSorted: filtersSorted ?? this.filtersSorted,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      snapshot: snapshot ?? this.snapshot,
      undo: undo ?? this.undo,
      redo: redo ?? this.redo,
      compareMode: compareMode ?? this.compareMode,
      isSaving: isSaving ?? this.isSaving,
      clipboard: clipboard ?? this.clipboard,
    );
  }

  static EditorState initial({
    required List<FilterItem> baseFilters,
  }) {
    const snapshot = EditorSnapshot(
      selectedId: 'base_original',
      filterIntensity: 1.0,
      brightness: 0.0,
      contrast: 0.0,
      saturation: 0.0,
      warmth: 0.0,
      fade: 0.0,
    );

    return EditorState(
      imagePath: null,
      imageBytes: null,
      filters: baseFilters,
      filtersSorted: _sortFilters(baseFilters),
      favoriteIds: <String>{},
      snapshot: snapshot,
      undo: const [],
      redo: const [],
      compareMode: false,
      isSaving: false,
      clipboard: null,
    );
  }

  EditorState withSortedFromFilters() {
    return copyWith(filtersSorted: _sortFilters(filters));
  }

  static List<FilterItem> _sortFilters(List<FilterItem> filters) {
    final sorted = List<FilterItem>.from(filters);
    sorted.sort((a, b) {
      final aFavorite = a.isFavorite ? 0 : 1;
      final bFavorite = b.isFavorite ? 0 : 1;
      if (aFavorite != bFavorite) {
        return aFavorite.compareTo(bFavorite);
      }

      final aCustom = a.isCustom ? 1 : 0;
      final bCustom = b.isCustom ? 1 : 0;
      if (aCustom != bCustom) {
        return aCustom.compareTo(bCustom);
      }

      return a.name.compareTo(b.name);
    });
    return sorted;
  }
}
