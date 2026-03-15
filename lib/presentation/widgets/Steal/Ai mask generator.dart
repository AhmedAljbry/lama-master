import 'package:image/image.dart' as img;
import 'package:lama/features/studio_editor/data/services/ai_mask_generator_service.dart';

Future<img.Image?> generateAiMask(String imagePath) async {
  final result = await const AiMaskGeneratorService().generate(imagePath);
  return result?.maskImage;
}
