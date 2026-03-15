import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/t.dart';
import '../../../../core/routing/app_routes.dart';
import '../../application/image_pick_cubit.dart';
import '../../application/inpainting_bloc/inpainting_bloc.dart';
import '../../application/inpainting_bloc/inpainting_event.dart';
import '../../application/inpainting_bloc/inpainting_state.dart';
import '../../domain/inpainting_status.dart';
import '../widgets/inpainting_studio_chrome.dart';

class ProcessingPage extends StatefulWidget {
  const ProcessingPage({super.key});

  @override
  State<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage>
    with TickerProviderStateMixin {
  late final AnimationController _glowController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  late final AnimationController _scannerController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _glowController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<T>();
    final pickState = context.watch<ImagePickCubit>().state;
    final rawImage = pickState is ImagePickReady ? pickState.uiImage : null;

    return Scaffold(
      backgroundColor: InpaintingStudioTheme.background,
      body: BlocConsumer<InpaintingBloc, InpaintingState>(
        listener: (context, state) {
          if (state.status == InpaintingStatus.success) {
            context.go(AppRoutes.result);
          }
        },
        builder: (context, state) {
          final isFailed = state.status == InpaintingStatus.failed ||
              state.status == InpaintingStatus.timeout;
          final isCancelled = state.status == InpaintingStatus.cancelled;
          final isQueued = state.status == InpaintingStatus.queued;

          if (isFailed || isCancelled) {
            _scannerController.stop();
            _glowController.stop();
          } else {
            if (!_scannerController.isAnimating) {
              _scannerController.repeat(reverse: true);
            }
            if (!_glowController.isAnimating) {
              _glowController.repeat(reverse: true);
            }
          }

          final progress = _progressValueFromServerOrFallback(state);
          final activeStep = _stepFromStatus(state.status);
          final headline = _primaryMessage(t, state);
          final elapsed = _elapsedText(state.startedAt);

          return StudioGlowBackground(
            animation: _glowController,
            primaryGlow: isFailed || isCancelled
                ? InpaintingStudioTheme.rose
                : InpaintingStudioTheme.mint,
            secondaryGlow: isFailed || isCancelled
                ? InpaintingStudioTheme.danger
                : InpaintingStudioTheme.violet,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 960;
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
                            _buildTopBar(context, t, state),
                            const SizedBox(height: 22),
                            isWide
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: _buildPreviewCard(
                                          t: t,
                                          rawImage: rawImage,
                                          state: state,
                                          isFailed: isFailed,
                                          isCancelled: isCancelled,
                                          isQueued: isQueued,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        flex: 6,
                                        child: _buildStatusCard(
                                          t: t,
                                          state: state,
                                          headline: headline,
                                          progress: progress,
                                          activeStep: activeStep,
                                          elapsed: elapsed,
                                          isFailed: isFailed,
                                          isCancelled: isCancelled,
                                          isQueued: isQueued,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _buildPreviewCard(
                                        t: t,
                                        rawImage: rawImage,
                                        state: state,
                                        isFailed: isFailed,
                                        isCancelled: isCancelled,
                                        isQueued: isQueued,
                                      ),
                                      const SizedBox(height: 18),
                                      _buildStatusCard(
                                        t: t,
                                        state: state,
                                        headline: headline,
                                        progress: progress,
                                        activeStep: activeStep,
                                        elapsed: elapsed,
                                        isFailed: isFailed,
                                        isCancelled: isCancelled,
                                        isQueued: isQueued,
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, T t, InpaintingState state) {
    return StudioGlassPanel(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      fillColor: InpaintingStudioTheme.surfaceSoft,
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.close_rounded,
            onTap: () {
              context.read<InpaintingBloc>().add(InpaintingCancel());
              context.pop();
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.of('processing'),
                  style: const TextStyle(
                    color: InpaintingStudioTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.of('processing_body'),
                  style: const TextStyle(
                    color: InpaintingStudioTheme.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          StudioPill(
            icon: Icons.memory_rounded,
            label: state.serverStage ?? t.of('processing'),
            accent: InpaintingStudioTheme.cyan,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard({
    required T t,
    required ui.Image? rawImage,
    required InpaintingState state,
    required bool isFailed,
    required bool isCancelled,
    required bool isQueued,
  }) {
    final accent = isFailed || isCancelled
        ? InpaintingStudioTheme.rose
        : InpaintingStudioTheme.mint;

    return StudioGlassPanel(
      radius: 34,
      padding: const EdgeInsets.all(20),
      gradient: InpaintingStudioTheme.heroGradient,
      borderColor: accent.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudioSectionLabel(
            title: t.of('processing_headline'),
            subtitle: t.of('processing_body'),
          ),
          const SizedBox(height: 18),
          AspectRatio(
            aspectRatio: 0.9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (rawImage != null)
                    RawImage(image: rawImage, fit: BoxFit.cover)
                  else
                    Container(color: InpaintingStudioTheme.surfaceStrong),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                  if (!(isFailed || isCancelled))
                    AnimatedBuilder(
                      animation: _scannerController,
                      builder: (context, child) {
                        final top = -80 + (_scannerController.value * 360);
                        return Positioned(
                          top: top,
                          left: 0,
                          right: 0,
                          child: Opacity(
                            opacity: isQueued ? 0.28 : 1,
                            child: Container(
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    accent.withValues(alpha: 0),
                                    accent.withValues(alpha: 0.28),
                                    accent.withValues(alpha: 0.8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  Center(
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Icon(
                        isFailed || isCancelled
                            ? Icons.error_outline_rounded
                            : Icons.auto_fix_high_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: 16,
                    start: 16,
                    child: StudioPill(
                      icon: Icons.bolt_rounded,
                      label: t.of('compare_live'),
                      accent: accent,
                      filled: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required T t,
    required InpaintingState state,
    required String headline,
    required double progress,
    required int activeStep,
    required String elapsed,
    required bool isFailed,
    required bool isCancelled,
    required bool isQueued,
  }) {
    final accent = isFailed || isCancelled
        ? InpaintingStudioTheme.rose
        : InpaintingStudioTheme.mint;
    final jobLabel = state.jobId == null
        ? '...'
        : state.jobId!.substring(
            0,
            state.jobId!.length > 8 ? 8 : state.jobId!.length,
          );

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
                label: t.of('elapsed'),
                value: elapsed,
                accent: InpaintingStudioTheme.textPrimary,
              ),
              StudioStatTile(
                label: t.of('job_id'),
                value: jobLabel,
                accent: InpaintingStudioTheme.cyan,
              ),
              StudioStatTile(
                label: t.of('queue_position'),
                value: state.queuePosition?.toString() ?? '--',
                accent: InpaintingStudioTheme.amber,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            headline,
            style: const TextStyle(
              color: InpaintingStudioTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            state.serverMessage?.trim().isNotEmpty == true
                ? state.serverMessage!.trim()
                : t.of('processing_body'),
            style: const TextStyle(
              color: InpaintingStudioTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          _ProgressDial(progress: progress, accent: accent),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          if (isQueued) ...[
            const SizedBox(height: 16),
            _InfoBanner(
              icon: Icons.queue_rounded,
              accent: InpaintingStudioTheme.amber,
              text: '${t.of('queue_position')}: ${state.queuePosition ?? '--'}',
            ),
          ],
          if (isFailed || isCancelled) ...[
            const SizedBox(height: 16),
            _InfoBanner(
              icon: Icons.warning_amber_rounded,
              accent: InpaintingStudioTheme.rose,
              text: _errorText(t, state),
            ),
          ],
          const SizedBox(height: 22),
          _buildTimeline(t, activeStep, accent),
          const SizedBox(height: 22),
          if (isFailed)
            StudioPrimaryButton(
              onPressed: () => context.pop(),
              icon: Icons.refresh_rounded,
              label: t.of('retry'),
            )
          else
            StudioSecondaryButton(
              onPressed: () {
                context.read<InpaintingBloc>().add(InpaintingCancel());
                context.go(AppRoutes.editor);
              },
              icon: Icons.arrow_back_rounded,
              label: t.of('return_editor'),
              accent: InpaintingStudioTheme.textPrimary,
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline(T t, int activeStep, Color accent) {
    final items = [
      t.of('queued'),
      t.of('uploading'),
      t.of('processing'),
      t.of('downloading'),
    ];

    return Column(
      children: List.generate(items.length, (index) {
        final done = index < activeStep;
        final active = index == activeStep;
        final dotColor = done
            ? accent
            : active
                ? accent.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.08);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  border: Border.all(
                    color: active ? accent : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.black)
                    : active
                        ? Center(
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  items[index],
                  style: TextStyle(
                    color: active || done
                        ? InpaintingStudioTheme.textPrimary
                        : InpaintingStudioTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _errorText(T t, InpaintingState state) {
    final messageKey = state.failure?.messageKey;
    if (messageKey != null) {
      return t.of(messageKey);
    }
    if (state.serverMessage?.trim().isNotEmpty == true) {
      return state.serverMessage!.trim();
    }
    return t.of('failed');
  }

  int _stepFromStatus(InpaintingStatus status) {
    return switch (status) {
      InpaintingStatus.queued => 0,
      InpaintingStatus.uploading => 1,
      InpaintingStatus.processing => 2,
      InpaintingStatus.downloading => 3,
      InpaintingStatus.success => 4,
      _ => 2,
    };
  }

  String _primaryMessage(T t, InpaintingState state) {
    final serverMsg = state.serverMessage;
    if (serverMsg != null && serverMsg.trim().isNotEmpty) {
      return serverMsg.trim();
    }

    return switch (state.status) {
      InpaintingStatus.queued => t.of('queued'),
      InpaintingStatus.uploading => t.of('uploading'),
      InpaintingStatus.processing => t.of('processing'),
      InpaintingStatus.downloading => t.of('downloading'),
      InpaintingStatus.timeout => t.of('timeout'),
      InpaintingStatus.failed => t.of('failed'),
      InpaintingStatus.cancelled => t.of('cancelled'),
      _ => t.of('processing'),
    };
  }

  double _progressValueFromServerOrFallback(InpaintingState state) {
    final serverProgress = state.serverProgress;
    if (serverProgress != null) {
      return (serverProgress.clamp(0, 100) / 100.0).toDouble();
    }

    return switch (state.status) {
      InpaintingStatus.queued => 0.08,
      InpaintingStatus.uploading => 0.18,
      InpaintingStatus.processing =>
        (0.24 + ((state.pollCount * 0.03).clamp(0.0, 0.52))).clamp(0.0, 0.84),
      InpaintingStatus.downloading => 0.92,
      InpaintingStatus.success => 1.0,
      InpaintingStatus.failed => 1.0,
      InpaintingStatus.timeout => 1.0,
      InpaintingStatus.cancelled => 1.0,
      _ => 0.2,
    };
  }

  String _elapsedText(DateTime? startedAt) {
    if (startedAt == null) {
      return '--:--';
    }
    final elapsed = DateTime.now().difference(startedAt);
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
        child: Icon(icon, color: InpaintingStudioTheme.textPrimary, size: 20),
      ),
    );
  }
}

class _ProgressDial extends StatelessWidget {
  final double progress;
  final Color accent;

  const _ProgressDial({
    required this.progress,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final label = '${(progress * 100).round()}%';

    return Center(
      child: SizedBox(
        width: 128,
        height: 128,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 11,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: InpaintingStudioTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'AI',
                    style: TextStyle(
                      color: InpaintingStudioTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String text;

  const _InfoBanner({
    required this.icon,
    required this.accent,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: InpaintingStudioTheme.textPrimary,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
