import 'dart:typed_data';

import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class GallerySaverService {
  Future<bool> savePng(Uint8List bytes, {required String name}) async {
    var status = await Permission.storage.request();
    if (status.isDenied) {
      await Permission.photos.request();
    }

    final result = await ImageGallerySaverPlus.saveImage(
      bytes,
      quality: 100,
      name: name,
    );

    return (result is Map) && (result['isSuccess'] == true);
  }
}
