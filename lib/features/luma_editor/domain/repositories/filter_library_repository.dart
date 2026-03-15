import 'package:lama/features/luma_editor/domain/entities/filter_item.dart';

abstract interface class FilterLibraryRepository {
  Future<List<FilterItem>> loadCustomFilters();

  Future<Set<String>> loadFavorites();

  Future<void> saveCustomFilters(List<FilterItem> customs);

  Future<void> saveFavorites(Set<String> ids);
}
