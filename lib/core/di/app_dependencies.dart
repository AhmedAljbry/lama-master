import 'package:lama/core/config/app_config.dart';
import 'package:lama/core/feature_flags/feature_flags.dart';
import 'package:lama/core/i18n/t.dart';
import 'package:lama/features/inpainting/data/inpainting_api.dart';
import 'package:lama/features/inpainting/data/inpainting_repository.dart';

class AppDependencies {
  final AppConfig config;
  final FeatureFlags flags;
  final Lang lang;

  AppDependencies({
    required this.config,
    required this.flags,
    required this.lang,
  });

  late final InpaintingApi inpaintingApi = InpaintingApi(baseUrl: config.baseUrl);
  late final InpaintingRepository inpaintingRepository = InpaintingRepository(
    inpaintingApi,
    apiKey: config.apiKey,
    lang: lang.name,
  );
  late final T translations = T(lang);
}
