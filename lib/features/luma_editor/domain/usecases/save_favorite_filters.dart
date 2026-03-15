import 'package:lama/features/luma_editor/domain/repositories/filter_library_repository.dart';

class SaveFavoriteFilters {
  final FilterLibraryRepository repository;

  const SaveFavoriteFilters(this.repository);

  Future<void> call(Set<String> ids) {
    return repository.saveFavorites(ids);
  }
}
