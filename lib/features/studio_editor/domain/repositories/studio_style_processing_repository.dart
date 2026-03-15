import 'package:lama/features/studio_editor/domain/entities/studio_processing_request.dart';
import 'package:lama/features/studio_editor/domain/entities/studio_processing_result.dart';

abstract class StudioStyleProcessingRepository {
  Future<StudioProcessingResult> process(StudioProcessingRequest request);
}
