import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lama/core/error/error_reporter.dart';
import 'package:lama/core/logging/app_logger.dart';
import 'package:lama/features/studio_editor/data/repositories/gallery_studio_image_repository.dart';
import 'package:lama/features/studio_editor/data/repositories/isolate_studio_style_processing_repository.dart';
import 'package:lama/features/studio_editor/data/repositories/platform_studio_result_repository.dart';
import 'package:lama/features/studio_editor/data/services/ai_mask_generator_service.dart';
import 'package:lama/features/studio_editor/data/services/studio_filter_engine_service.dart';
import 'package:lama/features/studio_editor/data/services/studio_image_picker_service.dart';
import 'package:lama/features/studio_editor/data/services/studio_result_service.dart';
import 'package:lama/features/studio_editor/domain/usecases/pick_studio_image.dart';
import 'package:lama/features/studio_editor/domain/usecases/process_studio_style.dart';
import 'package:lama/features/studio_editor/domain/usecases/save_studio_result.dart';
import 'package:lama/features/studio_editor/domain/usecases/share_studio_result.dart';
import 'package:lama/features/studio_editor/presentation/services/studio_editor_toolkit.dart';

class StudioEditorScope extends StatefulWidget {
  final Widget child;

  const StudioEditorScope({
    super.key,
    required this.child,
  });

  @override
  State<StudioEditorScope> createState() => _StudioEditorScopeState();
}

class _StudioEditorScopeState extends State<StudioEditorScope> {
  late final AppLogger _logger = const AppLogger();
  late final ErrorReporter _reporter = ErrorReporter(_logger);
  late final StudioEditorToolkit _toolkit = StudioEditorToolkit(
    pickStudioImage: PickStudioImage(
      GalleryStudioImageRepository(
        StudioImagePickerService(),
      ),
    ),
    processStudioStyle: ProcessStudioStyle(
      const IsolateStudioStyleProcessingRepository(
        aiMaskGeneratorService: AiMaskGeneratorService(),
        filterEngineService: StudioFilterEngineService(),
      ),
    ),
    saveStudioResult: SaveStudioResult(
      const PlatformStudioResultRepository(
        StudioResultService(),
      ),
    ),
    shareStudioResult: ShareStudioResult(
      const PlatformStudioResultRepository(
        StudioResultService(),
      ),
    ),
    reporter: _reporter,
  );

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<StudioEditorToolkit>.value(
      value: _toolkit,
      child: widget.child,
    );
  }
}
