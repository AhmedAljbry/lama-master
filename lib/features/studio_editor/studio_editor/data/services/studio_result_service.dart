import 'dart:io';
import 'dart:typed_data';

import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class StudioResultService {
  const StudioResultService();

  Future<bool> save(Uint8List bytes) async {
    final result = await ImageGallerySaverPlus.saveImage(
      bytes,
      quality: 100,
      name: 'StudioPro_${DateTime.now().millisecondsSinceEpoch}',
    );
    return result['isSuccess'] == true;
  }

  Future<bool> share(Uint8List bytes, {String text = 'Studio Pro'}) async {
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/StudioPro_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: '$text ✨',
      ),
    );
    return true;
  }
}
