import 'package:lama/features/luma_editor/domain/entities/editor_snapshot.dart';
import 'package:lama/features/luma_editor/domain/entities/filter_item.dart';
import 'package:lama/features/luma_editor/domain/services/filter_matrix_service.dart';

class BuildFinalFilterMatrix {
  const BuildFinalFilterMatrix();

  List<double> call({
    required List<FilterItem> filters,
    required EditorSnapshot snapshot,
  }) {
    if (filters.isEmpty) {
      return FilterMatrixService.identity;
    }

    final selectedId = ensureSelectedId(snapshot.selectedId, filters);
    final selected = filters.firstWhere(
      (filter) => filter.id == selectedId,
      orElse: () => filters.first,
    );

    final applied = FilterMatrixService.lerpMatrix(
      selected.matrix,
      snapshot.filterIntensity,
    );
    final brightness = FilterMatrixService.brightness(snapshot.brightness);
    final contrast = FilterMatrixService.contrast(snapshot.contrast);
    final saturation = FilterMatrixService.saturation(snapshot.saturation);
    final warmth = FilterMatrixService.warmth(snapshot.warmth);
    final fade = FilterMatrixService.fade(snapshot.fade);

    var out = applied;
    out = FilterMatrixService.multiply(warmth, out);
    out = FilterMatrixService.multiply(saturation, out);
    out = FilterMatrixService.multiply(contrast, out);
    out = FilterMatrixService.multiply(brightness, out);
    out = FilterMatrixService.multiply(fade, out);
    return out;
  }

  String ensureSelectedId(String id, List<FilterItem> filters) {
    if (filters.any((filter) => filter.id == id)) {
      return id;
    }
    return filters.isNotEmpty ? filters.first.id : 'base_original';
  }
}
