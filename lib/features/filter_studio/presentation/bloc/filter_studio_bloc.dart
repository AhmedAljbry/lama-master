import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lama/core/error/error_reporter.dart';
import 'package:lama/core/error/failure.dart';
import 'package:lama/core/logging/app_logger.dart';
import 'package:lama/features/filter_studio/domain/entities/app_preset.dart';
import 'package:lama/features/filter_studio/domain/entities/filter_params.dart';
import 'package:lama/features/filter_studio/domain/entities/preset_config.dart';
import 'package:lama/features/filter_studio/domain/repositories/person_mask_repository.dart';
import 'package:lama/features/filter_studio/domain/usecases/generate_person_mask.dart';
import 'package:lama/features/filter_studio/domain/usecases/save_filter_studio_result.dart';
import 'package:lama/features/filter_studio/presentation/bloc/filter_studio_event.dart';
import 'package:lama/features/filter_studio/presentation/services/filter_params_calibrator.dart';
import 'package:lama/features/filter_studio/presentation/bloc/filter_studio_state.dart';

class FilterStudioBloc extends Bloc<FilterStudioEvent, FilterStudioState> {
  final PersonMaskRepository personMaskRepository;
  final GeneratePersonMask generatePersonMask;
  final SaveFilterStudioResult saveFilterStudioResult;
  final ErrorReporter reporter;
  final AppLogger logger;
  final Map<AppPreset, PresetConfig> presets;

  final List<FilterParams> _adjustStack = <FilterParams>[];
  int _adjustIndex = -1;

  bool get _canUndo => _adjustIndex > 0;
  bool get _canRedo =>
      _adjustIndex >= 0 && _adjustIndex < _adjustStack.length - 1;

  FilterStudioBloc({
    required this.personMaskRepository,
    required this.generatePersonMask,
    required this.saveFilterStudioResult,
    required this.reporter,
    required this.logger,
    required this.presets,
  }) : super(FilterStudioState.initial(presets: presets)) {
    on<ImagePicked>(_onImagePicked);
    on<ClearImage>(_onClearImage);
    on<ApplyPreset>(_onApplyPreset);
    on<ApplyRecipe>(_onApplyRecipe);
    on<TabChanged>(_onTabChanged);
    on<FilterParamChanged>(_onParamChanged);
    on<SaveRequested>(_onSaveRequested);
    on<AdjustResetRequested>(_onAdjustReset);
    on<AdjustUndoRequested>(_onAdjustUndo);
    on<AdjustRedoRequested>(_onAdjustRedo);
    on<CompareHoldChanged>(_onCompareHoldChanged);

    _seedHistory(state.params);
  }

  void _seedHistory(FilterParams params) {
    _adjustStack
      ..clear()
      ..add(params);
    _adjustIndex = 0;
  }

  void _pushHistory(FilterParams params) {
    if (_adjustIndex < _adjustStack.length - 1) {
      _adjustStack.removeRange(_adjustIndex + 1, _adjustStack.length);
    }
    _adjustStack.add(params);
    _adjustIndex++;
  }

  void _emitFailure(
    Emitter<FilterStudioState> emit,
    Failure failure, {
    bool? isProcessing,
    bool? isSaving,
  }) {
    emit(
      state.copyWith(
        isProcessing: isProcessing,
        isSaving: isSaving,
        lastFailure: failure,
        failureTick: state.failureTick + 1,
      ),
    );
  }

  void _emitParams(FilterParams next, Emitter<FilterStudioState> emit) {
    final safe = FilterParamsCalibrator.sanitize(
      next,
      hasPersonMask: state.personMask != null,
    );
    _pushHistory(safe);
    emit(
      state.copyWith(
        params: safe,
        canUndoAdjust: _canUndo,
        canRedoAdjust: _canRedo,
      ),
    );
  }

  Future<void> _onImagePicked(
    ImagePicked event,
    Emitter<FilterStudioState> emit,
  ) async {
    emit(
      state.copyWith(
        imageFile: event.imageFile,
        isProcessing: true,
        personMask: null,
        lastFailure: null,
        isComparingHold: false,
      ),
    );

    _applyPresetInternal(AppPreset.original, emit);

    try {
      final bytes = await event.imageFile.readAsBytes();
      final mask = await generatePersonMask(
        filePath: event.imageFile.path,
        originalBytes: bytes,
      );

      logger.log('Generated person mask for filter studio',
          level: LogLevel.debug);
      emit(
        state.copyWith(
          personMask: mask,
          isProcessing: false,
        ),
      );

      _applyPresetInternal(AppPreset.editorial, emit);
    } catch (error, stack) {
      reporter.report(error, stack, context: 'segmentation');
      _emitFailure(
        emit,
        const SegmentationFailure('Segmentation failed'),
        isProcessing: false,
      );
    }
  }

  void _onClearImage(ClearImage event, Emitter<FilterStudioState> emit) {
    final nextState = FilterStudioState.initial(presets: presets);
    emit(nextState);
    _seedHistory(nextState.params);
  }

  void _onApplyPreset(ApplyPreset event, Emitter<FilterStudioState> emit) {
    _applyPresetInternal(event.preset, emit);
  }

  void _onApplyRecipe(ApplyRecipe event, Emitter<FilterStudioState> emit) {
    final next = FilterParamsCalibrator.sanitize(
      event.params.copyWith(
        selectedTabIndex: state.params.selectedTabIndex,
      ),
      hasPersonMask: state.personMask != null,
    );

    _pushHistory(next);
    emit(
      state.copyWith(
        selectedPreset: event.preset ?? state.selectedPreset,
        params: next,
        lastFailure: null,
        canUndoAdjust: _canUndo,
        canRedoAdjust: _canRedo,
      ),
    );
  }

  void _applyPresetInternal(AppPreset preset, Emitter<FilterStudioState> emit) {
    final config = presets[preset]!;
    final next = FilterParamsCalibrator.sanitize(
      _paramsFromPresetConfig(config).copyWith(
        selectedTabIndex: state.params.selectedTabIndex,
      ),
      hasPersonMask: state.personMask != null,
    );

    _pushHistory(next);
    emit(
      state.copyWith(
        selectedPreset: preset,
        params: next,
        lastFailure: null,
        canUndoAdjust: _canUndo,
        canRedoAdjust: _canRedo,
      ),
    );
  }

  FilterParams _paramsFromPresetConfig(PresetConfig config) {
    return FilterParams(
      contrast: config.contrast,
      saturation: config.saturation,
      exposure: config.exposure,
      brightness: config.brightness,
      warmth: config.warmth,
      tint: config.tint,
      blur: config.blur,
      aura: config.aura,
      auraColor: config.auraColor ?? state.params.auraColor,
      grain: config.grain,
      scanlines: config.scanlines,
      glitch: config.glitch,
      ghost: config.ghost,
      colorPop: config.colorPop,
      overlayColor: config.colorOverlay,
      replaceBackground: config.replaceBackground,
      showDateStamp: config.showDateStamp,
      cinemaMode: config.cinemaMode,
      polaroidFrame: config.polaroidFrame,
      vignette: config.vignette,
      lightLeakIndex: config.lightLeakIndex,
      prismOverlay: config.prismOverlay,
      dustOverlay: config.dustOverlay,
    );
  }

  void _onTabChanged(TabChanged event, Emitter<FilterStudioState> emit) {
    emit(
      state.copyWith(
        params: state.params.copyWith(selectedTabIndex: event.index),
      ),
    );
  }

  void _onParamChanged(
    FilterParamChanged event,
    Emitter<FilterStudioState> emit,
  ) {
    final params = state.params;

    switch (event.key) {
      case 'contrast':
        _emitParams(params.copyWith(contrast: event.value as double), emit);
        return;
      case 'saturation':
        _emitParams(params.copyWith(saturation: event.value as double), emit);
        return;
      case 'replaceBackground':
        _emitParams(
          params.copyWith(replaceBackground: event.value as bool),
          emit,
        );
        return;
      case 'blur':
        _emitParams(params.copyWith(blur: event.value as double), emit);
        return;
      case 'aura':
        _emitParams(params.copyWith(aura: event.value as double), emit);
        return;
      case 'auraColor':
        _emitParams(params.copyWith(auraColor: event.value as Color), emit);
        return;
      case 'grain':
        _emitParams(params.copyWith(grain: event.value as double), emit);
        return;
      case 'scanlines':
        _emitParams(params.copyWith(scanlines: event.value as double), emit);
        return;
      case 'glitch':
        _emitParams(params.copyWith(glitch: event.value as double), emit);
        return;
      case 'ghost':
        _emitParams(params.copyWith(ghost: event.value as bool), emit);
        return;
      case 'colorPop':
        _emitParams(params.copyWith(colorPop: event.value as bool), emit);
        return;
      case 'showDateStamp':
        _emitParams(
          params.copyWith(showDateStamp: event.value as bool),
          emit,
        );
        return;
      case 'cinemaMode':
        _emitParams(params.copyWith(cinemaMode: event.value as bool), emit);
        return;
      case 'polaroidFrame':
        _emitParams(
          params.copyWith(polaroidFrame: event.value as bool),
          emit,
        );
        return;
      case 'vignette':
        _emitParams(params.copyWith(vignette: event.value as double), emit);
        return;
      case 'lightLeakIndex':
        _emitParams(
          params.copyWith(lightLeakIndex: event.value as int),
          emit,
        );
        return;
      case 'prismOverlay':
        _emitParams(
          params.copyWith(prismOverlay: event.value as double),
          emit,
        );
        return;
      case 'dustOverlay':
        _emitParams(
          params.copyWith(dustOverlay: event.value as double),
          emit,
        );
        return;
      case 'exposure':
        _emitParams(params.copyWith(exposure: event.value as double), emit);
        return;
      case 'brightness':
        _emitParams(params.copyWith(brightness: event.value as double), emit);
        return;
      case 'warmth':
        _emitParams(params.copyWith(warmth: event.value as double), emit);
        return;
      case 'tint':
        _emitParams(params.copyWith(tint: event.value as double), emit);
        return;
      case 'highlights':
        _emitParams(params.copyWith(highlights: event.value as double), emit);
        return;
      case 'shadows':
        _emitParams(params.copyWith(shadows: event.value as double), emit);
        return;
      case 'clarity':
        _emitParams(params.copyWith(clarity: event.value as double), emit);
        return;
      case 'dehaze':
        _emitParams(params.copyWith(dehaze: event.value as double), emit);
        return;
      case 'sharpen':
        _emitParams(params.copyWith(sharpen: event.value as double), emit);
        return;
      case 'vignetteSize':
        _emitParams(
          params.copyWith(vignetteSize: event.value as double),
          emit,
        );
        return;
      default:
        return;
    }
  }

  void _onAdjustReset(
    AdjustResetRequested event,
    Emitter<FilterStudioState> emit,
  ) {
    final next = FilterParamsCalibrator.sanitize(
      const FilterParams(),
      hasPersonMask: state.personMask != null,
    );
    _pushHistory(next);
    emit(
      state.copyWith(
        params: next,
        canUndoAdjust: _canUndo,
        canRedoAdjust: _canRedo,
      ),
    );
  }

  void _onAdjustUndo(
    AdjustUndoRequested event,
    Emitter<FilterStudioState> emit,
  ) {
    if (!_canUndo) {
      return;
    }

    _adjustIndex--;
    emit(
      state.copyWith(
        params: _adjustStack[_adjustIndex],
        canUndoAdjust: _canUndo,
        canRedoAdjust: _canRedo,
      ),
    );
  }

  void _onAdjustRedo(
    AdjustRedoRequested event,
    Emitter<FilterStudioState> emit,
  ) {
    if (!_canRedo) {
      return;
    }

    _adjustIndex++;
    emit(
      state.copyWith(
        params: _adjustStack[_adjustIndex],
        canUndoAdjust: _canUndo,
        canRedoAdjust: _canRedo,
      ),
    );
  }

  void _onCompareHoldChanged(
    CompareHoldChanged event,
    Emitter<FilterStudioState> emit,
  ) {
    emit(state.copyWith(isComparingHold: event.isHolding));
  }

  Future<void> _onSaveRequested(
    SaveRequested event,
    Emitter<FilterStudioState> emit,
  ) async {
    if (state.imageFile == null) {
      return;
    }

    final pngBytes = event.pngBytes;
    if (pngBytes == null || pngBytes.isEmpty) {
      _emitFailure(
        emit,
        const SaveFailure('Canvas not ready'),
        isSaving: false,
      );
      return;
    }

    emit(state.copyWith(isSaving: true, lastFailure: null));
    await Future<void>.delayed(const Duration(milliseconds: 60));

    try {
      final ok = await saveFilterStudioResult(pngBytes);
      if (!ok) {
        _emitFailure(
          emit,
          const SaveFailure('Save failed'),
          isSaving: false,
        );
        return;
      }

      logger.log('Saved filter studio result', level: LogLevel.info);
      emit(state.copyWith(isSaving: false));
    } catch (error, stack) {
      reporter.report(error, stack, context: 'save');
      _emitFailure(
        emit,
        const SaveFailure('Save error'),
        isSaving: false,
      );
    }
  }

  @override
  Future<void> close() async {
    await personMaskRepository.dispose();
    return super.close();
  }
}
