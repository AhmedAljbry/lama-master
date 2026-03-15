import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lama/core/error/error_reporter.dart';
import 'package:lama/core/logging/app_logger.dart';
import 'package:lama/features/filter_studio/data/repositories/gallery_filter_studio_export_repository.dart';
import 'package:lama/features/filter_studio/data/repositories/mlkit_person_mask_repository.dart';
import 'package:lama/features/filter_studio/data/services/gallery_saver_service.dart';
import 'package:lama/features/filter_studio/data/services/selfie_segmentation_service.dart';
import 'package:lama/features/filter_studio/domain/entities/app_preset.dart';
import 'package:lama/features/filter_studio/domain/entities/preset_config.dart';
import 'package:lama/features/filter_studio/domain/usecases/generate_person_mask.dart';
import 'package:lama/features/filter_studio/domain/usecases/save_filter_studio_result.dart';
import 'package:lama/features/filter_studio/presentation/bloc/filter_studio_bloc.dart';

class FilterStudioScope extends StatelessWidget {
  final Map<AppPreset, PresetConfig> presets;
  final Widget child;

  const FilterStudioScope({
    super.key,
    required this.presets,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FilterStudioBloc>(
      create: (_) {
        final logger = const AppLogger();
        final personMaskRepository = MlkitPersonMaskRepository(
          SelfieSegmentationService(),
        );

        return FilterStudioBloc(
          personMaskRepository: personMaskRepository,
          generatePersonMask: GeneratePersonMask(personMaskRepository),
          saveFilterStudioResult: SaveFilterStudioResult(
            GalleryFilterStudioExportRepository(GallerySaverService()),
          ),
          reporter: ErrorReporter(logger),
          logger: logger,
          presets: presets,
        );
      },
      child: child,
    );
  }
}
