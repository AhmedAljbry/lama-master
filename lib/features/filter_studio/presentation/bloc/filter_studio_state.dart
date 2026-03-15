import 'dart:io';
import 'dart:ui' as ui;

import 'package:lama/core/error/failure.dart';
import 'package:lama/features/filter_studio/domain/entities/app_preset.dart';
import 'package:lama/features/filter_studio/domain/entities/filter_params.dart';
import 'package:lama/features/filter_studio/domain/entities/preset_config.dart';

class FilterStudioState {
  static const Object _unset = Object();

  final File? imageFile;
  final ui.Image? personMask;
  final bool isProcessing;
  final bool isSaving;
  final bool isComparingHold;
  final bool canUndoAdjust;
  final bool canRedoAdjust;
  final AppPreset selectedPreset;
  final Map<AppPreset, PresetConfig> presets;
  final FilterParams params;
  final Failure? lastFailure;
  final int failureTick;

  const FilterStudioState({
    required this.imageFile,
    required this.personMask,
    required this.isProcessing,
    required this.isSaving,
    required this.isComparingHold,
    required this.canUndoAdjust,
    required this.canRedoAdjust,
    required this.selectedPreset,
    required this.presets,
    required this.params,
    required this.lastFailure,
    required this.failureTick,
  });

  factory FilterStudioState.initial({
    required Map<AppPreset, PresetConfig> presets,
  }) {
    return FilterStudioState(
      imageFile: null,
      personMask: null,
      isProcessing: false,
      isSaving: false,
      isComparingHold: false,
      canUndoAdjust: false,
      canRedoAdjust: false,
      selectedPreset: AppPreset.original,
      presets: presets,
      params: const FilterParams(),
      lastFailure: null,
      failureTick: 0,
    );
  }

  FilterStudioState copyWith({
    Object? imageFile = _unset,
    Object? personMask = _unset,
    bool? isProcessing,
    bool? isSaving,
    bool? isComparingHold,
    bool? canUndoAdjust,
    bool? canRedoAdjust,
    AppPreset? selectedPreset,
    Map<AppPreset, PresetConfig>? presets,
    FilterParams? params,
    Object? lastFailure = _unset,
    int? failureTick,
  }) {
    return FilterStudioState(
      imageFile: identical(imageFile, _unset) ? this.imageFile : imageFile as File?,
      personMask: identical(personMask, _unset) ? this.personMask : personMask as ui.Image?,
      isProcessing: isProcessing ?? this.isProcessing,
      isSaving: isSaving ?? this.isSaving,
      isComparingHold: isComparingHold ?? this.isComparingHold,
      canUndoAdjust: canUndoAdjust ?? this.canUndoAdjust,
      canRedoAdjust: canRedoAdjust ?? this.canRedoAdjust,
      selectedPreset: selectedPreset ?? this.selectedPreset,
      presets: presets ?? this.presets,
      params: params ?? this.params,
      lastFailure: identical(lastFailure, _unset) ? this.lastFailure : lastFailure as Failure?,
      failureTick: failureTick ?? this.failureTick,
    );
  }
}
