import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/core/ui/AppTokens.dart';
import 'package:lama/features/studio_editor/presentation/widgets/components/sidebar_components.dart';

class StudioResultScreen extends StatelessWidget {
  final Uint8List imageBytes;
  final String selectedStyle;
  final bool useAI;
  final bool hasManualMask;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onShare;

  const StudioResultScreen({
    super.key,
    required this.imageBytes,
    required this.selectedStyle,
    required this.useAI,
    required this.hasManualMask,
    required this.onEdit,
    required this.onSave,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final isDesktop = AppTokens.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.black, // Dark immersive background
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Image Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.s24),
                child: Hero(
                  tag: 'studio_result_image',
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTokens.r24),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppTokens.primary.withValues(alpha: 0.15),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            // Details and Actions Panel
            Container(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? AppTokens.s32 : AppTokens.s24,
                AppTokens.s32,
                isDesktop ? AppTokens.s32 : AppTokens.s24,
                AppTokens.s32,
              ),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTokens.r32),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppTokens.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppTokens.primaryGlow(0.28),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 32,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: AppTokens.s20),
                  Text(
                    l10n.get('result_title'),
                    style: AppTokens.headingL.copyWith(color: AppTokens.text),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTokens.s8),
                  Text(
                    l10n.get('result_desc'),
                    textAlign: TextAlign.center,
                    style: AppTokens.bodyM.copyWith(
                      height: 1.6,
                      color: AppTokens.text2,
                    ),
                  ),
                  const SizedBox(height: AppTokens.s20),
                  Wrap(
                    spacing: AppTokens.s8,
                    runSpacing: AppTokens.s8,
                    alignment: WrapAlignment.center,
                    children: <Widget>[
                      StatusInfoPill(
                        label: selectedStyle,
                        color: AppTokens.info,
                      ),
                      if (useAI)
                        StatusInfoPill(
                          label: l10n.get('ai_mode_label'),
                          color: AppTokens.primary,
                        ),
                      if (hasManualMask)
                        StatusInfoPill(
                          label: l10n.get('manual_tag'),
                          color: AppTokens.warning,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s32),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            onEdit();
                          },
                          icon: const Icon(Icons.tune_rounded),
                          label: Text(l10n.get('btn_edit')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTokens.text,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: AppTokens.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTokens.r16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.s12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            onSave();
                          },
                          icon: const Icon(Icons.download_rounded, color: Colors.black),
                          label: Text(
                            l10n.get('btn_save'),
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTokens.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTokens.r16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onShare();
                      },
                      icon: Icon(Icons.share_rounded, color: AppTokens.text),
                      label: Text(
                        l10n.get('btn_share'),
                        style: TextStyle(color: AppTokens.text),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.r16),
                        ),
                      ),
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
