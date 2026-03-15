import 'package:lama/features/studio_editor/data/services/studio_image_picker_service.dart';
import 'package:lama/features/studio_editor/domain/entities/studio_image_asset.dart';
import 'package:lama/features/studio_editor/domain/repositories/studio_image_repository.dart';

class GalleryStudioImageRepository implements StudioImageRepository {
  final StudioImagePickerService service;

  const GalleryStudioImageRepository(this.service);

  @override
  Future<StudioImageAsset?> pickFromGallery() {
    return service.pickFromGallery();
  }
}
