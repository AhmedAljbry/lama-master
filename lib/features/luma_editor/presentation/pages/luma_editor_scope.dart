import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lama/core/error/error_reporter.dart';
import 'package:lama/core/logging/app_logger.dart';
import 'package:lama/core/performance/render_capture_service.dart';
import 'package:lama/features/luma_editor/data/repositories/gallery_editor_export_repository.dart';
import 'package:lama/features/luma_editor/data/repositories/image_package_editor_analysis_repository.dart';
import 'package:lama/features/luma_editor/data/repositories/shared_prefs_filter_library_repository.dart';
import 'package:lama/features/luma_editor/data/services/editor_image_analysis_service.dart';
import 'package:lama/features/luma_editor/data/services/editor_result_saver_service.dart';
import 'package:lama/features/luma_editor/domain/usecases/analyze_auto_enhance.dart';
import 'package:lama/features/luma_editor/domain/usecases/build_final_filter_matrix.dart';
import 'package:lama/features/luma_editor/domain/usecases/generate_ai_filter_insight.dart';
import 'package:lama/features/luma_editor/domain/usecases/generate_filter_catalog.dart';
import 'package:lama/features/luma_editor/domain/usecases/generate_random_filter_profile.dart';
import 'package:lama/features/luma_editor/domain/usecases/load_editor_library.dart';
import 'package:lama/features/luma_editor/domain/usecases/save_custom_filters.dart';
import 'package:lama/features/luma_editor/domain/usecases/save_editor_result.dart';
import 'package:lama/features/luma_editor/domain/usecases/save_favorite_filters.dart';
import 'package:lama/features/luma_editor/presentation/bloc/editor_bloc.dart';
import 'package:lama/features/luma_editor/presentation/bloc/editor_event.dart';
import 'package:lama/features/luma_editor/presentation/services/luma_editor_toolkit.dart';

class LumaEditorScope extends StatefulWidget {
  final Widget child;

  const LumaEditorScope({
    super.key,
    required this.child,
  });

  @override
  State<LumaEditorScope> createState() => _LumaEditorScopeState();
}

class _LumaEditorScopeState extends State<LumaEditorScope> {
  late final AppLogger _logger = const AppLogger();
  late final ErrorReporter _reporter = ErrorReporter(_logger);
  late final SharedPrefsFilterLibraryRepository _libraryRepository =
      SharedPrefsFilterLibraryRepository();
  late final ImagePackageEditorAnalysisRepository _analysisRepository =
      ImagePackageEditorAnalysisRepository(
    const EditorImageAnalysisService(),
  );
  late final LumaEditorToolkit _toolkit = LumaEditorToolkit(
    analyzeAutoEnhance: AnalyzeAutoEnhance(
      _analysisRepository,
    ),
    generateAiFilterInsight: GenerateAiFilterInsight(_analysisRepository),
    generateRandomFilterProfile: const GenerateRandomFilterProfile(),
    saveEditorResult: SaveEditorResult(
      const GalleryEditorExportRepository(
        EditorResultSaverService(),
      ),
    ),
    renderCaptureService: const RenderCaptureService(),
    reporter: _reporter,
  );

  @override
  Widget build(BuildContext context) {
    final filters = const GenerateFilterCatalog()();

    return RepositoryProvider<LumaEditorToolkit>.value(
      value: _toolkit,
      child: BlocProvider<EditorBloc>(
        create: (_) => EditorBloc(
          baseFilters: filters,
          repository: _libraryRepository,
          loadEditorLibrary: LoadEditorLibrary(_libraryRepository),
          saveCustomFilters: SaveCustomFilters(_libraryRepository),
          saveFavoriteFilters: SaveFavoriteFilters(_libraryRepository),
          buildFinalFilterMatrix: const BuildFinalFilterMatrix(),
          logger: _logger,
          reporter: _reporter,
        )..add(HydrateFromStorage()),
        child: widget.child,
      ),
    );
  }
}
