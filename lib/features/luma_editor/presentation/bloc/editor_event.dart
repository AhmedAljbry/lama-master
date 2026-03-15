import 'package:lama/features/luma_editor/domain/entities/filter_item.dart';

sealed class EditorEvent {}

class ImageLoaded extends EditorEvent {
  final String path;
  final List<int> bytes;

  ImageLoaded({
    required this.path,
    required this.bytes,
  });
}

class SelectFilter extends EditorEvent {
  final String id;

  SelectFilter(this.id);
}

class SetIntensity extends EditorEvent {
  final double value;

  SetIntensity(this.value);
}

class SetAdjustments extends EditorEvent {
  final double? brightness;
  final double? contrast;
  final double? saturation;
  final double? warmth;
  final double? fade;

  SetAdjustments({
    this.brightness,
    this.contrast,
    this.saturation,
    this.warmth,
    this.fade,
  });
}

class ResetAdjustments extends EditorEvent {}

class ResetAll extends EditorEvent {}

class ToggleFavorite extends EditorEvent {
  final FilterItem item;

  ToggleFavorite(this.item);
}

class Undo extends EditorEvent {}

class Redo extends EditorEvent {}

class CopySettings extends EditorEvent {}

class PasteSettings extends EditorEvent {}

class ToggleCompare extends EditorEvent {}

class HydrateFromStorage extends EditorEvent {}

class AddCustomFilter extends EditorEvent {
  final FilterItem item;

  AddCustomFilter(this.item);
}

class RenameCustomFilter extends EditorEvent {
  final String id;
  final String newName;

  RenameCustomFilter(this.id, this.newName);
}

class DeleteCustomFilter extends EditorEvent {
  final String id;

  DeleteCustomFilter(this.id);
}
