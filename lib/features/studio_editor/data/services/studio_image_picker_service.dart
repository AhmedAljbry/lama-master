import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lama/features/studio_editor/domain/entities/studio_image_asset.dart';
import 'package:lama/features/studio_editor/domain/entities/studio_editor_exceptions.dart';
import 'package:path_provider/path_provider.dart';

class StudioImagePickerService {
  final ImagePicker _picker;

  StudioImagePickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<StudioImageAsset?> pickFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return null;
    }

    final originalPath = picked.path;
    final lower = originalPath.toLowerCase();

    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      final result = await FlutterImageCompress.compressWithFile(
        originalPath,
        format: CompressFormat.jpeg,
        quality: 100,
      );
      if (result == null) {
        throw const StudioImageConvertException();
      }

      final tempDirectory = await getTemporaryDirectory();
      final file = File(
        '${tempDirectory.path}/conv_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(result, flush: true);

      return StudioImageAsset(
        path: file.path,
        bytes: Uint8List.fromList(result),
      );
    }

    final bytes = await File(originalPath).readAsBytes();
    return StudioImageAsset(
      path: originalPath,
      bytes: Uint8List.fromList(bytes),
    );
  }
}
