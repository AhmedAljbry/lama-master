import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/core/ui/AppTokens.dart';

/// Premium result screen — polished reveal with actions
class StudioResultScreen extends StatefulWidget {
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
  State<StudioResultScreen> createState() => _StudioResultScreenState();
}

class _StudioResultScreenState extends State<StudioResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<Offset> _panelSlide;
  late Animation<double> _panelFade;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _panelSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _panelFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.1, 1.0)),
    );
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final isDesktop = AppTokens.isDesktop(context);
    final safePad = MediaQuery.of(context).padding;

    return Stack(
      children: <Widget>[
        // Subtle background glow
        Positioned(
          top: -80,
          left: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTokens.primary.withValues(alpha: 0.05),
            ),
          ),
        ),

        Column(
          children: <Widget>[
            // ── Result Header ──────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppTokens.s20,
                safePad.top + AppTokens.s12,
                AppTokens.s20,
                AppTokens.s12,
              ),
              child: Row(
                children: <Widget>[
                  // AI Result Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          AppTokens.primary.withValues(alpha: 0.22),
                          AppTokens.primary.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(AppTokens.rFull),
                      border: Border.all(
                        color: AppTokens.primary.withValues(alpha: 0.32),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color: AppTokens.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.get('result_title').toUpperCase(),
                          style: const TextStyle(
                            color: AppTokens.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Try Another Style button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onEdit();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.s12,
                        vertical: AppTokens.s8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTokens.card2,
                        borderRadius:
                            BorderRadius.circular(AppTokens.rFull),
                        border: Border.all(
                          color: AppTokens.border.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.style_rounded,
                            size: 13,
                            color: AppTokens.text2,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Try Style',
                            style: AppTokens.caption.copyWith(
                              color: AppTokens.text2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  // Edit Again button
                  GestureDetector(
                    onTap: widget.onEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.s12,
                        vertical: AppTokens.s8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTokens.surface,
                        borderRadius:
                            BorderRadius.circular(AppTokens.rFull),
                        border: Border.all(
                          color: AppTokens.border.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.edit_rounded,
                            size: 13,
                            color: AppTokens.text2,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            l10n.get('btn_edit'),
                            style: AppTokens.caption.copyWith(
                              color: AppTokens.text2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Image Hero ─────────────────────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      isDesktop ? AppTokens.s32 : AppTokens.s20,
                ),
                child: Hero(
                  tag: 'studio_image_workspace',
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppTokens.r24),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppTokens.r24),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 44,
                            offset: const Offset(0, 22),
                          ),
                        ],
                      ),
                      child: Image.memory(
                        widget.imageBytes,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom Action Panel ─────────────────────────
            SlideTransition(
              position: _panelSlide,
              child: FadeTransition(
                opacity: _panelFade,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? AppTokens.s32 : AppTokens.s20,
                    AppTokens.s24,
                    isDesktop ? AppTokens.s32 : AppTokens.s20,
                    safePad.bottom + AppTokens.s20,
                  ),
                  decoration: BoxDecoration(
                    color: AppTokens.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTokens.r32),
                    ),
                    border: Border.all(
                      color: AppTokens.border.withValues(alpha: 0.22),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.38),
                        blurRadius: 44,
                        offset: const Offset(0, -12),
                      ),
                      // Inner top shadow for depth
                      BoxShadow(
                        color: AppTokens.primary.withValues(alpha: 0.03),
                        blurRadius: 1,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // ── Metadata badges ──
                      Wrap(
                        spacing: AppTokens.s8,
                        runSpacing: AppTokens.s8,
                        alignment: WrapAlignment.center,
                        children: <Widget>[
                          _ResultBadge(
                            label: l10n.get(widget.selectedStyle),
                            icon: Icons.auto_awesome_rounded,
                            color: AppTokens.primary,
                          ),
                          if (widget.useAI)
                            _ResultBadge(
                              label: l10n.get('ai_mode_label'),
                              icon: Icons.psychology_rounded,
                              color: AppTokens.info,
                            ),
                          if (widget.hasManualMask)
                            _ResultBadge(
                              label: l10n.get('manual_select'),
                              icon: Icons.brush_rounded,
                              color: AppTokens.warning,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.s12),
                      Text(
                        l10n.get('result_desc'),
                        textAlign: TextAlign.center,
                        style: AppTokens.bodyM.copyWith(
                          color: AppTokens.text2,
                          height: 1.5,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: AppTokens.s20),
                      // ── Actions ──
                      Row(
                        children: <Widget>[
                          // Share button with label
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              widget.onShare();
                            },
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppTokens.s16),
                              decoration: BoxDecoration(
                                color: AppTokens.card,
                                borderRadius:
                                    BorderRadius.circular(AppTokens.r16),
                                border: Border.all(
                                  color: AppTokens.border
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: <Widget>[
                                  const Icon(
                                    Icons.ios_share_rounded,
                                    size: 18,
                                    color: AppTokens.text,
                                  ),
                                  const SizedBox(width: AppTokens.s8),
                                  Text(
                                    l10n.get('btn_share'),
                                    style: AppTokens.labelBold.copyWith(
                                      color: AppTokens.text,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTokens.s12),
                          // Save button — primary CTA
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.heavyImpact();
                                widget.onSave();
                              },
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: AppTokens.primaryGradient,
                                  borderRadius: BorderRadius.circular(
                                      AppTokens.r16),
                                  boxShadow:
                                      AppTokens.primaryGlow(0.24),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Icon(
                                      Icons.download_done_rounded,
                                      color: Colors.black,
                                      size: 19,
                                    ),
                                    const SizedBox(width: AppTokens.s8),
                                    Text(
                                      l10n.get('btn_save').toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _ResultBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppTokens.rFull),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
