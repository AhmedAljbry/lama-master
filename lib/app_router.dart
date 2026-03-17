import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lama/core/routing/app_routes.dart';
import 'package:lama/features/image_location_intel/presentation/pages/image_location_intel_page.dart';
import 'package:lama/features/inpainting/presentation/pages/editor/editor_page.dart';
import 'package:lama/features/inpainting/presentation/pages/home_pick_page.dart';
import 'package:lama/features/inpainting/presentation/pages/processing_page.dart';
import 'package:lama/features/inpainting/presentation/pages/result_page.dart';
import 'package:lama/presentation/pages/PremiumDashboardPage.dart';
import 'package:lama/presentation/pages/ai_studio_page.dart';
import 'package:lama/presentation/pages/luma_ultimate_editor_page.dart';
import 'package:lama/presentation/pages/pro_filter_studio_page.dart';
import 'package:lama/presentation/pages/splash_page.dart';
import 'package:lama/presentation/pages/onboarding_page.dart';
import 'package:lama/presentation/pages/forced_update_page.dart';

CustomTransitionPage<void> _fade(Widget child) => CustomTransitionPage<void>(
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final slide = Tween(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved);

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );

final router = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (_, __) => _fade(const SplashPage())),
    GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (_, __) => _fade(const OnboardingPage())),
    GoRoute(
        path: AppRoutes.forcedUpdate,
        pageBuilder: (_, __) => _fade(const ForcedUpdatePage())),
    GoRoute(
        path: AppRoutes.home,
        pageBuilder: (_, __) => _fade(const PremiumDashboardPage())),
    GoRoute(
        path: AppRoutes.magicEraser,
        pageBuilder: (_, __) => _fade(const HomePickPage())),
    GoRoute(
        path: AppRoutes.lumaEditor,
        pageBuilder: (_, __) => _fade(const LumaUltimateEditorPage())),
    GoRoute(
        path: AppRoutes.aiStudio,
        pageBuilder: (_, __) => _fade(const AiStudioPage())),
    GoRoute(
        path: AppRoutes.proStudio,
        pageBuilder: (_, __) => _fade(const ProFilterStudioPage())),
    GoRoute(
        path: AppRoutes.imageIntel,
        pageBuilder: (_, __) => _fade(const ImageLocationIntelPage())),
    GoRoute(
        path: AppRoutes.editor,
        pageBuilder: (_, __) => _fade(const EditorPage())),
    GoRoute(
        path: AppRoutes.processing,
        pageBuilder: (_, __) => _fade(const ProcessingPage())),
    GoRoute(
        path: AppRoutes.result,
        pageBuilder: (_, __) => _fade(const ResultPage())),
  ],
);
