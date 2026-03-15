import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/feature_flags/feature_flags.dart';
import 'core/i18n/t.dart';
import 'core/logging/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const logger = AppLogger();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    logger.log(
      'Flutter framework error',
      level: LogLevel.error,
      error: details.exception,
      stack: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.log(
      'Uncaught platform error',
      level: LogLevel.error,
      error: error,
      stack: stack,
    );
    return false;
  };

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0B0F14),
  ));

  final flags = const bool.fromEnvironment('dart.vm.product')
      ? FeatureFlags.prod
      : FeatureFlags.dev;

  final deviceLanguage = PlatformDispatcher.instance.locale.languageCode;
  final appLanguage =
      deviceLanguage.toLowerCase().startsWith('ar') ? Lang.ar : Lang.en;

  runApp(
    App(
      config: AppConfig.fromEnvironment(),
      flags: flags,
      lang: appLanguage,
    ),
  );
}
