import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/core/ui/AppTokens.dart';
import 'package:lama/features/studio_editor/presentation/pages/studio_editor_main_screen.dart';
import 'package:lama/presentation/widgets/Steal/CinematicProcessingOverlay.dart';

import 'components/workspace_components.dart';

class StudioCanvasWorkspace extends StatelessWidget {
  final EditorState state;
  final Uint8List? targetBytes;
  final Uint8List? outputBytes;
  final String? refPath;
  final bool isComparing;
  final bool useAI;
  final bool hasManualMask;
  final String selectedStyle;
  final VoidCallback onTapFullScreen;
  final VoidCallback onPickTarget;
  final VoidCallback onPickReference;
  final ValueChanged<bool> onCompareToggle;
  final VoidCallback onCompareToggleEnd;

  const StudioCanvasWorkspace({
    super.key,
    required this.state,
    required this.targetBytes,
    required this.outputBytes,
    required this.refPath,
    required this.isComparing,
    required this.useAI,
    required this.hasManualMask,
    required this.selectedStyle,
    required this.onTapFullScreen,
    required this.onPickTarget,
    required this.onPickReference,
    required this.onCompareToggle,
    required this.onCompareToggleEnd,
  });

  Uint8List? get _displayBytes {
    if (targetBytes == null) return null;
    if (isComparing) return targetBytes;
    return outputBytes ?? targetBytes;
  }

  bool get _hasResult => state == EditorState.result && outputBytes != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final isDesktop = AppTokens.isDesktop(context);
    final displayBytes = _displayBytes;
    final guidance = _buildGuidance(l10n);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF090C10),
        borderRadius: BorderRadius.circular(AppTokens.r24),
        border: Border.all(
          color: AppTokens.border.withValues(alpha: 0.32),
          width: 1.0,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.r24),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Subtle grid background
            Positioned.fill(
              child: CustomPaint(
                painter: GridPainter(
                  color: Colors.white.withValues(alpha: 0.02),
                  spacing: 32,
                ),
              ),
            ),

            // Main image display
            if (displayBytes != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: InteractiveViewer(
                  key: ValueKey<int>(displayBytes.hashCode),
                  minScale: 0.5,
                  maxScale: 6.0,
                  clipBehavior: Clip.none,
                  child: GestureDetector(
                    onDoubleTap: onTapFullScreen,
                    child: Hero(
                      tag: 'studio_image_workspace',
                      child: Image.memory(
                        displayBytes,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              )
            else
              EmptyWorkspaceState(
                onTap: onPickTarget,
                label: l10n.get('add_photo_hint'),
                subtitle: l10n.get('workspace_hero_sub'),
              ),

            // Edge vignette
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: <Color>[
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.22),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Top gradient behind reference thumbnail
            if (refPath != null && state != EditorState.processing)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 100,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Reference thumbnail
            if (refPath != null && state != EditorState.processing)
              Positioned(
                top: AppTokens.s12,
                right: AppTokens.s12,
                child: ReferenceThumbnail(refPath: refPath!),
              ),

            // BEFORE badge when comparing
            if (isComparing)
              Positioned(
                top: AppTokens.s12,
                left: AppTokens.s12,
                child: WorkspaceBadge(
                  label: l10n.get('original_label'),
                  color: AppTokens.warning,
                  icon: Icons.history_rounded,
                ),
              ),

            // Guidance card — positioned above the floating toolbar
            if (guidance != null)
              Positioned(
                left: AppTokens.s16,
                bottom: targetBytes != null ? 120 : AppTokens.s20,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: guidance,
                ),
              ),

            // Floating context toolbar at the bottom
            if (targetBytes != null && state != EditorState.processing)
              Positioned(
                bottom: AppTokens.s20,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingContextToolbar(
                    isComparing: isComparing,
                    onCompareToggle: onCompareToggle,
                    onCompareToggleEnd: onCompareToggleEnd,
                    onTapFullScreen: onTapFullScreen,
                    l10n: l10n,
                    isDesktop: isDesktop,
                  ),
                ),
              ),

            // Processing overlay
            if (state == EditorState.processing)
              const CinematicProcessingOverlay(),
          ],
        ),
      ),
    );
  }

  WorkspaceGuidanceCard? _buildGuidance(AppL10n l10n) {
    if (targetBytes == null || state == EditorState.processing || isComparing) {
      return null;
    }

    if (refPath == null) {
      return WorkspaceGuidanceCard(
        icon: Icons.add_photo_alternate_rounded,
        accent: AppTokens.info,
        title: l10n.get('workspace_need_reference_title'),
        subtitle: l10n.get('workspace_need_reference_desc'),
        actionLabel: l10n.get('filter_ref'),
        onAction: onPickReference,
      );
    }

    if (_hasResult) {
      return WorkspaceGuidanceCard(
        icon: Icons.verified_rounded,
        accent: AppTokens.success,
        title: l10n.get('workspace_result_ready_title'),
        subtitle: l10n.get('workspace_result_ready_desc'),
      );
    }

    return WorkspaceGuidanceCard(
      icon: Icons.auto_awesome_mosaic_rounded,
      accent: AppTokens.primary,
      title: selectedStyle,
      subtitle: l10n.get('workspace_style_hint'),
    );
  }
}
