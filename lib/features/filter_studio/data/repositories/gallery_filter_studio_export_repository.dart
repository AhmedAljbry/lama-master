import 'dart:typed_data';

import 'package:lama/features/filter_studio/data/services/gallery_saver_service.dart';
import 'package:lama/features/filter_studio/domain/repositories/filter_studio_export_repository.dart';

class GalleryFilterStudioExportRepository
    implements FilterStudioExportRepository {
  final GallerySaverService gallerySaverService;

  const GalleryFilterStudioExportRepository(this.gallerySaverService);

  @override
  Future<bool> savePng(Uint8List bytes, {required String name}) {
    return gallerySaverService.savePng(bytes, name: name);
  }
}
