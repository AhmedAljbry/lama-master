import 'package:lama/features/luma_editor/domain/entities/filter_item.dart';

class EditorLibraryData {
  final List<FilterItem> filters;
  final Set<String> favoriteIds;

  const EditorLibraryData({
    required this.filters,
    required this.favoriteIds,
  });
}
