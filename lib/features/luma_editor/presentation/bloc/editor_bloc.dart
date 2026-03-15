import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lama/core/error/error_reporter.dart';
import 'package:lama/core/logging/app_logger.dart';
import 'package:lama/features/luma_editor/domain/entities/editor_snapshot.dart';
import 'package:lama/features/luma_editor/domain/entities/filter_item.dart';
import 'package:lama/features/luma_editor/domain/repositories/filter_library_repository.dart';
import 'package:lama/features/luma_editor/domain/usecases/build_final_filter_matrix.dart';
import 'package:lama/features/luma_editor/domain/usecases/load_editor_library.dart';
import 'package:lama/features/luma_editor/domain/usecases/save_custom_filters.dart';
import 'package:lama/features/luma_editor/domain/usecases/save_favorite_filters.dart';
import 'package:lama/features/luma_editor/presentation/bloc/editor_event.dart';
import 'package:lama/features/luma_editor/presentation/bloc/editor_state.dart';

class EditorBloc extends Bloc<EditorEvent, EditorState> {
  final FilterLibraryRepository repository;
  final LoadEditorLibrary loadEditorLibrary;
  final SaveCustomFilters saveCustomFilters;
  final SaveFavoriteFilters saveFavoriteFilters;
  final BuildFinalFilterMatrix buildFinalFilterMatrix;
  final AppLogger logger;
  final ErrorReporter reporter;

  EditorBloc({
    required List<FilterItem> baseFilters,
    required this.repository,
    required this.loadEditorLibrary,
    required this.saveCustomFilters,
    required this.saveFavoriteFilters,
    required this.buildFinalFilterMatrix,
    required this.logger,
    required this.reporter,
  }) : super(EditorState.initial(baseFilters: baseFilters)) {
    on<HydrateFromStorage>(_onHydrate);
    on<ImageLoaded>(_onImageLoaded);
    on<SelectFilter>(_onSelectFilter);
    on<SetIntensity>(_onSetIntensity);
    on<SetAdjustments>(_onSetAdjustments);
    on<ResetAdjustments>(_onResetAdjustments);
    on<ResetAll>(_onResetAll);
    on<ToggleFavorite>(_onToggleFavorite);
    on<Undo>(_onUndo);
    on<Redo>(_onRedo);
    on<CopySettings>(_onCopy);
    on<PasteSettings>(_onPaste);
    on<ToggleCompare>(_onToggleCompare);
    on<AddCustomFilter>(_onAddCustom);
    on<RenameCustomFilter>(_onRenameCustom);
    on<DeleteCustomFilter>(_onDeleteCustom);
  }

  Future<void> _onHydrate(
    HydrateFromStorage event,
    Emitter<EditorState> emit,
  ) async {
    try {
      final library = await loadEditorLibrary(state.filters);
      emit(
        state.copyWith(
          filters: library.filters,
          favoriteIds: library.favoriteIds,
        ).withSortedFromFilters(),
      );

      final selectedId = buildFinalFilterMatrix.ensureSelectedId(
        state.snapshot.selectedId,
        library.filters,
      );
      if (selectedId != state.snapshot.selectedId) {
        emit(state.copyWith(snapshot: state.snapshot.copyWith(selectedId: selectedId)));
      }
    } catch (error, stack) {
      reporter.capture(error, stack, context: 'HydrateFromStorage');
    }
  }

  void _onImageLoaded(ImageLoaded event, Emitter<EditorState> emit) {
    emit(
      state.copyWith(
        imagePath: event.path,
        imageBytes: Uint8List.fromList(event.bytes),
        undo: <EditorSnapshot>[],
        redo: <EditorSnapshot>[],
        snapshot: const EditorSnapshot(
          selectedId: 'base_original',
          filterIntensity: 1.0,
          brightness: 0.0,
          contrast: 0.0,
          saturation: 0.0,
          warmth: 0.0,
          fade: 0.0,
        ),
      ),
    );
    HapticFeedback.selectionClick();
  }

  void _pushUndo(Emitter<EditorState> emit) {
    final undo = List<EditorSnapshot>.from(state.undo)..add(state.snapshot);
    if (undo.length > 50) {
      undo.removeAt(0);
    }
    emit(state.copyWith(undo: undo, redo: <EditorSnapshot>[]));
  }

  void _onSelectFilter(SelectFilter event, Emitter<EditorState> emit) {
    if (!state.filters.any((filter) => filter.id == event.id)) {
      return;
    }
    if (event.id == state.snapshot.selectedId) {
      return;
    }

    _pushUndo(emit);
    emit(
      state.copyWith(
        snapshot: state.snapshot.copyWith(
          selectedId: event.id,
          filterIntensity: 1.0,
        ),
      ),
    );
    HapticFeedback.selectionClick();
  }

  void _onSetIntensity(SetIntensity event, Emitter<EditorState> emit) {
    _pushUndo(emit);
    emit(
      state.copyWith(
        snapshot: state.snapshot.copyWith(
          filterIntensity: event.value.clamp(0.0, 1.0),
        ),
      ),
    );
  }

  void _onSetAdjustments(SetAdjustments event, Emitter<EditorState> emit) {
    _pushUndo(emit);
    emit(
      state.copyWith(
        snapshot: state.snapshot.copyWith(
          brightness: event.brightness ?? state.snapshot.brightness,
          contrast: event.contrast ?? state.snapshot.contrast,
          saturation: event.saturation ?? state.snapshot.saturation,
          warmth: event.warmth ?? state.snapshot.warmth,
          fade: event.fade ?? state.snapshot.fade,
        ),
      ),
    );
  }

  void _onResetAdjustments(
    ResetAdjustments event,
    Emitter<EditorState> emit,
  ) {
    _pushUndo(emit);
    emit(
      state.copyWith(
        snapshot: state.snapshot.copyWith(
          brightness: 0,
          contrast: 0,
          saturation: 0,
          warmth: 0,
          fade: 0,
        ),
      ),
    );
  }

  void _onResetAll(ResetAll event, Emitter<EditorState> emit) {
    _pushUndo(emit);
    emit(
      state.copyWith(
        snapshot: const EditorSnapshot(
          selectedId: 'base_original',
          filterIntensity: 1.0,
          brightness: 0.0,
          contrast: 0.0,
          saturation: 0.0,
          warmth: 0.0,
          fade: 0.0,
        ),
      ),
    );
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<EditorState> emit,
  ) async {
    final id = event.item.id;
    final isFavorite = state.favoriteIds.contains(id);

    final favorites = Set<String>.from(state.favoriteIds);
    if (isFavorite) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }

    final updatedFilters = state.filters
        .map(
          (filter) => filter.id == id
              ? filter.copyWith(isFavorite: !isFavorite)
              : filter,
        )
        .toList();

    emit(
      state.copyWith(
        filters: updatedFilters,
        favoriteIds: favorites,
      ).withSortedFromFilters(),
    );

    try {
      await saveFavoriteFilters(favorites);
      HapticFeedback.selectionClick();
    } catch (error, stack) {
      reporter.capture(error, stack, context: 'saveFavorites');
    }
  }

  void _onUndo(Undo event, Emitter<EditorState> emit) {
    if (state.undo.isEmpty) {
      return;
    }

    final redo = List<EditorSnapshot>.from(state.redo)..add(state.snapshot);
    final undo = List<EditorSnapshot>.from(state.undo);
    final previous = undo.removeLast();

    emit(state.copyWith(snapshot: previous, undo: undo, redo: redo));
    HapticFeedback.selectionClick();
  }

  void _onRedo(Redo event, Emitter<EditorState> emit) {
    if (state.redo.isEmpty) {
      return;
    }

    final undo = List<EditorSnapshot>.from(state.undo)..add(state.snapshot);
    final redo = List<EditorSnapshot>.from(state.redo);
    final next = redo.removeLast();

    emit(state.copyWith(snapshot: next, undo: undo, redo: redo));
    HapticFeedback.selectionClick();
  }

  void _onCopy(CopySettings event, Emitter<EditorState> emit) {
    emit(state.copyWith(clipboard: state.snapshot));
  }

  void _onPaste(PasteSettings event, Emitter<EditorState> emit) {
    final clipboard = state.clipboard;
    if (clipboard == null) {
      return;
    }

    _pushUndo(emit);
    emit(
      state.copyWith(
        snapshot: state.snapshot.copyWith(
          brightness: clipboard.brightness,
          contrast: clipboard.contrast,
          saturation: clipboard.saturation,
          warmth: clipboard.warmth,
          fade: clipboard.fade,
          filterIntensity: clipboard.filterIntensity,
        ),
      ),
    );
  }

  void _onToggleCompare(ToggleCompare event, Emitter<EditorState> emit) {
    emit(state.copyWith(compareMode: !state.compareMode));
  }

  Future<void> _onAddCustom(
    AddCustomFilter event,
    Emitter<EditorState> emit,
  ) async {
    final updated = List<FilterItem>.from(state.filters)..add(event.item);
    emit(state.copyWith(filters: updated).withSortedFromFilters());

    try {
      await saveCustomFilters(updated.where((filter) => filter.isCustom).toList());
    } catch (error, stack) {
      reporter.capture(error, stack, context: 'saveCustomFilters');
    }
  }

  Future<void> _onRenameCustom(
    RenameCustomFilter event,
    Emitter<EditorState> emit,
  ) async {
    final updated = state.filters
        .map(
          (filter) => filter.id == event.id
              ? filter.copyWith(name: event.newName)
              : filter,
        )
        .toList();
    emit(state.copyWith(filters: updated).withSortedFromFilters());

    try {
      await saveCustomFilters(updated.where((filter) => filter.isCustom).toList());
    } catch (error, stack) {
      reporter.capture(error, stack, context: 'renameCustom');
    }
  }

  Future<void> _onDeleteCustom(
    DeleteCustomFilter event,
    Emitter<EditorState> emit,
  ) async {
    final updated = List<FilterItem>.from(state.filters)
      ..removeWhere((filter) => filter.id == event.id);
    final favorites = Set<String>.from(state.favoriteIds)..remove(event.id);
    final selectedId = buildFinalFilterMatrix.ensureSelectedId(
      state.snapshot.selectedId,
      updated,
    );

    emit(
      state.copyWith(
        filters: updated,
        favoriteIds: favorites,
        snapshot: state.snapshot.copyWith(selectedId: selectedId),
      ).withSortedFromFilters(),
    );

    try {
      await saveCustomFilters(updated.where((filter) => filter.isCustom).toList());
      await saveFavoriteFilters(favorites);
    } catch (error, stack) {
      reporter.capture(error, stack, context: 'deleteCustom');
    }
  }

  List<double> buildFinalMatrix() {
    return buildFinalFilterMatrix(
      filters: state.filters,
      snapshot: state.snapshot,
    );
  }
}
