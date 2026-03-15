import 'package:lama/features/studio_editor/domain/entities/studio_image_asset.dart';

abstract class StudioImageRepository {
  Future<StudioImageAsset?> pickFromGallery();
}
