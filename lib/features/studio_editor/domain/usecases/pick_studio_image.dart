import 'package:lama/features/studio_editor/domain/entities/studio_image_asset.dart';
import 'package:lama/features/studio_editor/domain/repositories/studio_image_repository.dart';

class PickStudioImage {
  final StudioImageRepository repository;

  const PickStudioImage(this.repository);

  Future<StudioImageAsset?> call() {
    return repository.pickFromGallery();
  }
}
