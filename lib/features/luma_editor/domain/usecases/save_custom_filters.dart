import 'package:lama/features/luma_editor/domain/entities/filter_item.dart';
import 'package:lama/features/luma_editor/domain/repositories/filter_library_repository.dart';

class SaveCustomFilters {
  final FilterLibraryRepository repository;

  const SaveCustomFilters(this.repository);

  Future<void> call(List<FilterItem> customs) {
    return repository.saveCustomFilters(customs);
  }
}
