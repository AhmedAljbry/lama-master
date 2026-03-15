import 'package:lama/features/studio_editor/domain/entities/studio_processing_request.dart';
import 'package:lama/features/studio_editor/domain/entities/studio_processing_result.dart';
import 'package:lama/features/studio_editor/domain/repositories/studio_style_processing_repository.dart';

class ProcessStudioStyle {
  final StudioStyleProcessingRepository repository;

  const ProcessStudioStyle(this.repository);

  Future<StudioProcessingResult> call(StudioProcessingRequest request) {
    return repository.process(request);
  }
}
