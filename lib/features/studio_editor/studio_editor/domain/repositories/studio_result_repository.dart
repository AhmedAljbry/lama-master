import 'dart:typed_data';

abstract class StudioResultRepository {
  Future<bool> save(Uint8List bytes);
  Future<bool> share(Uint8List bytes, {String text = 'Studio Pro'});
}
