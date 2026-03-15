import 'package:lama/features/luma_editor/domain/entities/filter_item.dart';
import 'package:lama/features/luma_editor/domain/services/filter_matrix_service.dart';

class GenerateFilterCatalog {
  const GenerateFilterCatalog();

  List<FilterItem> call() {
    return [
      ...FilterMatrixService.generateBaseFilters(),
      ...FilterMatrixService.generateProPack100(),
    ];
  }
}
