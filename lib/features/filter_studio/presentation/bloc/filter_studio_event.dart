import 'dart:io';
import 'dart:typed_data';

import 'package:lama/features/filter_studio/domain/entities/app_preset.dart';
import 'package:lama/features/filter_studio/domain/entities/filter_params.dart';

sealed class FilterStudioEvent {
  const FilterStudioEvent();
}

class ImagePicked extends FilterStudioEvent {
  final File imageFile;

  const ImagePicked(this.imageFile);
}

class ClearImage extends FilterStudioEvent {
  const ClearImage();
}

class ApplyPreset extends FilterStudioEvent {
  final AppPreset preset;

  const ApplyPreset(this.preset);
}

class TabChanged extends FilterStudioEvent {
  final int index;

  const TabChanged(this.index);
}

class FilterParamChanged extends FilterStudioEvent {
  final String key;
  final Object value;

  const FilterParamChanged(this.key, this.value);
}

class SaveRequested extends FilterStudioEvent {
  final Object? payload;

  const SaveRequested(this.payload);

  Uint8List? get pngBytes => payload is Uint8List ? payload as Uint8List : null;
}

class AdjustResetRequested extends FilterStudioEvent {
  const AdjustResetRequested();
}

class AdjustUndoRequested extends FilterStudioEvent {
  const AdjustUndoRequested();
}

class AdjustRedoRequested extends FilterStudioEvent {
  const AdjustRedoRequested();
}

class CompareHoldChanged extends FilterStudioEvent {
  final bool isHolding;

  const CompareHoldChanged(this.isHolding);
}

class ApplyRecipe extends FilterStudioEvent {
  final FilterParams params;
  final AppPreset? preset;

  const ApplyRecipe({
    required this.params,
    this.preset,
  });
}
