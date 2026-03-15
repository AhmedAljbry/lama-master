import 'package:lama/features/luma_editor/domain/entities/editor_library_data.dart';
import 'package:lama/features/luma_editor/domain/entities/filter_item.dart';
import 'package:lama/features/luma_editor/domain/repositories/filter_library_repository.dart';

class LoadEditorLibrary {
  final FilterLibraryRepository repository;

  const LoadEditorLibrary(this.repository);

  Future<EditorLibraryData> call(List<FilterItem> baseFilters) async {
    final customs = await repository.loadCustomFilters();
    final favorites = await repository.loadFavorites();

    final merged = <FilterItem>[
      ...baseFilters.where((filter) => !filter.isCustom),
      ...customs,
    ].map((filter) {
      return filter.copyWith(isFavorite: favorites.contains(filter.id));
    }).toList();

    return EditorLibraryData(
      filters: merged,
      favoriteIds: favorites,
    );
  }
}
