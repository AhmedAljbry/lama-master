import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/t.dart';
import '../../../../core/routing/app_routes.dart';
import '../../application/image_pick_cubit.dart';
import '../../application/inpainting_bloc/inpainting_bloc.dart';
import '../../application/inpainting_bloc/inpainting_state.dart';
import '../../application/result_cubit.dart';
import '../widgets/before_after_slider.dart';
import '../widgets/inpainting_studio_chrome.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<T>();
    final inpaintingState = context.watch<InpaintingBloc>().state;
    final pickState = context.watch<ImagePickCubit>().state;
    final resultBytes = inpaintingState.result;
    final sourceBytes = pickState is ImagePickReady ? pickState.bytes : null;
    final sourceImage = pickState is ImagePickReady ? pickState.uiImage : null;

    if (resultBytes == null) {
      return _buildErrorState(context, t);
    }

    return Scaffold(
      backgroundColor: InpaintingStudioTheme.background,
      body: StudioGlowBackground(
        animation: _glowController,
        primaryGlow: InpaintingStudioTheme.mint,
        secondaryGlow: InpaintingStudioTheme.cyan,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1024;
              final padding = constraints.maxWidth < 460 ? 16.0 : 24.0;

              return SingleChildScrollView(
                padding: EdgeInsetsDirectional.fromSTEB(
                  padding,
                  14,
                  padding,
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(context, t),
                        const SizedBox(height: 22),
                        isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 7,
                                    child: _buildCompareCard(
                                      t: t,
                                      sourceBytes: sourceBytes,
                                      resultBytes: resultBytes,
                                      sourceImage: sourceImage,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 5,
                                    child: _buildSummaryPanel(
                                      t: t,
                                      sourceImage: sourceImage,
                                      state: inpaintingState,
                                      resultBytes: resultBytes,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildCompareCard(
                                    t: t,
                                    sourceBytes: sourceBytes,
                                    resultBytes: resultBytes,
                                    sourceImage: sourceImage,
                                  ),
                                  const SizedBox(height: 18),
                                  _buildSummaryPanel(
                                    t: t,
                                    sourceImage: sourceImage,
                                    state: inpaintingState,
                                    resultBytes: resultBytes,
                                  ),
                                ],
                              ),
                        const SizedBox(height: 18),
                        _buildActionDock(context, t, resultBytes),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, T t) {
    return StudioGlassPanel(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      fillColor: InpaintingStudioTheme.surfaceSoft,
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => context.go(AppRoutes.editor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.of('result_title'),
                  style: const TextStyle(
                    color: InpaintingStudioTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.of('result_body'),
                  style: const TextStyle(
                    color: InpaintingStudioTheme.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          StudioPill(
            icon: Icons.download_done_rounded,
            label: t.of('studio_quality'),
            accent: InpaintingStudioTheme.mint,
            filled: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCompareCard({
    required T t,
    required Uint8List? sourceBytes,
    required Uint8List resultBytes,
    required dynamic sourceImage,
  }) {
    final aspectRatio =
        sourceImage == null ? 1.0 : sourceImage.width / sourceImage.height;

    return StudioGlassPanel(
      radius: 34,
      padding: const EdgeInsets.all(20),
      gradient: InpaintingStudioTheme.heroGradient,
      borderColor: InpaintingStudioTheme.cyan.withValues(alpha: 0.16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudioSectionLabel(
            title: t.of('result_headline'),
            subtitle: t.of('result_body'),
          ),
          const SizedBox(height: 18),
          AspectRatio(
            aspectRatio: aspectRatio.clamp(0.65, 1.4).toDouble(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: sourceBytes == null
                  ? Image.memory(resultBytes, fit: BoxFit.cover)
                  : BeforeAfterSlider(
                      before: Image.memory(sourceBytes, fit: BoxFit.cover),
                      after: Image.memory(resultBytes, fit: BoxFit.cover),
                      beforeLabel: t.of('original_label'),
                      afterLabel: t.of('result_title'),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPanel({
    required T t,
    required dynamic sourceImage,
    required InpaintingState state,
    required Uint8List resultBytes,
  }) {
    final resolution = sourceImage == null
        ? '--'
        : '${sourceImage.width} x ${sourceImage.height}';
    final fileSizeKb = (resultBytes.length / 1024).toStringAsFixed(0);

    return StudioGlassPanel(
      radius: 34,
      padding: const EdgeInsets.all(24),
      fillColor: InpaintingStudioTheme.surfaceSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              StudioStatTile(
                label: t.of('resolution'),
                value: resolution,
                accent: InpaintingStudioTheme.cyan,
              ),
              StudioStatTile(
                label: 'PNG',
                value: '$fileSizeKb KB',
                accent: InpaintingStudioTheme.mint,
              ),
              StudioStatTile(
                label: t.of('processing'),
                value: state.serverStage ?? t.of('ai_ready_short'),
                accent: InpaintingStudioTheme.amber,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SummaryBlock(
            icon: Icons.compare_arrows_rounded,
            accent: InpaintingStudioTheme.cyan,
            title: t.of('compare_live'),
            body: t.of('result_compare_body'),
          ),
          const SizedBox(height: 14),
          _SummaryBlock(
            icon: Icons.auto_fix_high_rounded,
            accent: InpaintingStudioTheme.mint,
            title: t.of('studio_quality'),
            body: t.of('magic_pick_feature_quality'),
          ),
          const SizedBox(height: 14),
          _SummaryBlock(
            icon: Icons.edit_rounded,
            accent: InpaintingStudioTheme.violet,
            title: t.of('edit_again'),
            body: t.of('editor_tip_precision'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionDock(BuildContext context, T t, Uint8List resultBytes) {
    return BlocConsumer<ResultCubit, ResultState>(
      listener: (context, state) {
        if (state is ResultSaved) {
          _toast(context, t.of('saved_ok'), isSuccess: true);
        }
        if (state is ResultError) {
          _toast(context, t.of(state.messageKey), isSuccess: false);
        }
      },
      builder: (context, state) {
        final saving = state is ResultSaving;

        return StudioGlassPanel(
          radius: 32,
          padding: const EdgeInsets.all(16),
          fillColor: InpaintingStudioTheme.surfaceSoft,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 180,
                child: StudioSecondaryButton(
                  onPressed: () => context.go(AppRoutes.editor),
                  icon: Icons.edit_rounded,
                  label: t.of('edit_again'),
                  accent: InpaintingStudioTheme.textPrimary,
                ),
              ),
              SizedBox(
                width: 180,
                child: StudioSecondaryButton(
                  onPressed: () =>
                      context.read<ResultCubit>().shareBytes(resultBytes),
                  icon: Icons.ios_share_rounded,
                  label: t.of('share'),
                  accent: InpaintingStudioTheme.textPrimary,
                ),
              ),
              SizedBox(
                width: 180,
                child: StudioSecondaryButton(
                  onPressed: () => context.go(AppRoutes.magicEraser),
                  icon: Icons.add_photo_alternate_outlined,
                  label: t.of('new_project'),
                  accent: InpaintingStudioTheme.textPrimary,
                ),
              ),
              SizedBox(
                width: 220,
                child: StudioPrimaryButton(
                  onPressed: saving
                      ? null
                      : () => context.read<ResultCubit>().save(resultBytes),
                  icon: saving
                      ? Icons.downloading_rounded
                      : Icons.download_rounded,
                  label: saving ? t.of('loading') : t.of('save'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, T t) {
    return Scaffold(
      backgroundColor: InpaintingStudioTheme.background,
      body: Center(
        child: StudioGlassPanel(
          radius: 30,
          padding: const EdgeInsets.all(26),
          fillColor: InpaintingStudioTheme.surfaceSoft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.broken_image_rounded,
                size: 52,
                color: InpaintingStudioTheme.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                t.of('failed'),
                style: const TextStyle(
                  color: InpaintingStudioTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                t.of('result_body'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: InpaintingStudioTheme.textSecondary,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              StudioPrimaryButton(
                onPressed: () => context.go(AppRoutes.home),
                icon: Icons.home_rounded,
                label: t.of('return_home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(BuildContext context, String msg, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: (isSuccess
                ? InpaintingStudioTheme.mint
                : InpaintingStudioTheme.danger)
            .withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: InpaintingStudioTheme.textPrimary, size: 18),
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String body;

  const _SummaryBlock({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: InpaintingStudioTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    color: InpaintingStudioTheme.textSecondary,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
