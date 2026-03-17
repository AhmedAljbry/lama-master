import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_router.dart';
import 'core/config/app_config.dart';
import 'core/di/app_dependencies.dart';
import 'core/feature_flags/feature_flags.dart';
import 'core/ui/AppL10n.dart';
import 'core/ui/app_theme.dart';
import 'features/inpainting/application/drawing/drawing_cubit.dart';
import 'features/inpainting/application/image_pick_cubit.dart';
import 'features/inpainting/application/inpainting_bloc/inpainting_bloc.dart';
import 'features/inpainting/application/result_cubit.dart';
import 'features/inpainting/data/inpainting_repository.dart';

import 'core/i18n/locale_controller.dart';

class App extends StatefulWidget {
  final AppConfig config;
  final FeatureFlags flags;
  final LocaleController localeController;

  const App({
    super.key,
    required this.config,
    required this.flags,
    required this.localeController,
  });

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.localeController,
      builder: (context, _) {
        final dependencies = AppDependencies(
          config: widget.config,
          flags: widget.flags,
          langCode: widget.localeController.locale.languageCode,
        );

        return MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: widget.config),
            RepositoryProvider.value(value: widget.flags),
            RepositoryProvider.value(value: dependencies.inpaintingRepository),
          ],
          child: ChangeNotifierProvider<LocaleController>.value(
            value: widget.localeController,
            child: MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => ImagePickCubit()),
                BlocProvider(create: (_) => DrawingCubit()),
                BlocProvider(
                  create: (ctx) => InpaintingBloc(
                    repo: ctx.read<InpaintingRepository>(),
                  ),
                ),
                BlocProvider(create: (_) => ResultCubit()),
              ],
              child: MaterialApp.router(
              title: 'Luma Inpainting AI',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark(),
              routerConfig: router,
              locale: widget.localeController.locale,
              supportedLocales: const [
                Locale('en'),
                Locale('ar'),
              ],
              localizationsDelegates: const [
                AppL10nDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            ),
          ),
        ),
      );
      },
    );
  }
}
