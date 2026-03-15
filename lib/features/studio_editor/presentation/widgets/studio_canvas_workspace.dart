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
    if (targetBytes == null) {
      return null;
    }
    if (isComparing) {
      return targetBytes;
    }
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
        color: Colors.black87,
        borderRadius: BorderRadius.circular(AppTokens.r24),
        border: Border.all(
          color: AppTokens.border.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: AppTokens.primary.withValues(alpha: 0.05),
            blurRadius: 80,
            spreadRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.r24),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(
                painter: GridPainter(
                  color: Colors.white.withValues(alpha: 0.03),
                  spacing: 24,
                ),
              ),
            ),
            if (displayBytes != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: InteractiveViewer(
                  key: ValueKey<int>(displayBytes.hashCode),
                  minScale: 0.5,
                  maxScale: 5.0,
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
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.45,
                      colors: <Color>[
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.38),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (refPath != null && state != EditorState.processing)
              Positioned(
                top: AppTokens.s16,
                right: AppTokens.s16,
                child: ReferenceThumbnail(refPath: refPath!),
              ),
            if (guidance != null)
              Positioned(
                left: AppTokens.s16,
                right: isDesktop ? null : AppTokens.s16,
                bottom: targetBytes != null ? 108 : AppTokens.s24,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: guidance,
                ),
              ),
            if (targetBytes != null && state != EditorState.processing)
              Positioned(
                bottom: AppTokens.s28,
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
        icon: Icons.image_search_rounded,
        accent: AppTokens.info,
        title: l10n.get('workspace_need_reference_title'),
        subtitle: l10n.get('workspace_need_reference_desc'),
        actionLabel: l10n.get('filter_ref'),
        onAction: onPickReference,
      );
    }

    if (_hasResult) {
      return WorkspaceGuidanceCard(
        icon: Icons.check_circle_rounded,
        accent: AppTokens.success,
        title: l10n.get('workspace_result_ready_title'),
        subtitle: l10n.get('workspace_result_ready_desc'),
      );
    }

    return WorkspaceGuidanceCard(
      icon: Icons.style_rounded,
      accent: AppTokens.primary,
      title: selectedStyle,
      subtitle: l10n.get('workspace_style_hint'),
    );
  }
}
