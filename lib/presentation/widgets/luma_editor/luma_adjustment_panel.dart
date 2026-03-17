import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/core/ui/tokens.dart';
import 'package:lama/features/luma_editor/presentation/bloc/editor_bloc.dart';
import 'package:lama/features/luma_editor/presentation/bloc/editor_event.dart';
import 'package:lama/features/luma_editor/presentation/bloc/editor_state.dart';
import 'package:lama/presentation/widgets/luma_editor/luma_editor_components.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LumaAdjustmentPanel
//
// Redesigned from a flat list of 6 sliders into three expandable groups:
//   • Quick Adjust  — filterIntensity (Magic), brightness, contrast
//   • Color         — saturation, warmth
//   • Light         — fade  +  Auto Enhance shortcut
//
// All slider onChanged callbacks wire to the same bloc events as before.
// ─────────────────────────────────────────────────────────────────────────────

class LumaAdjustmentPanel extends StatefulWidget {
  final EditorState s;
  final AppL10n l10n;
  final bool enhancing;
  final VoidCallback onAutoEnhance;

  const LumaAdjustmentPanel({
    super.key,
    required this.s,
    required this.l10n,
    required this.enhancing,
    required this.onAutoEnhance,
  });

  @override
  State<LumaAdjustmentPanel> createState() =>
      _LumaAdjustmentPanelState();
}

class _LumaAdjustmentPanelState extends State<LumaAdjustmentPanel> {
  // Which sections are expanded — Quick Adjust is open by default
  final _expanded = <_AdjSection, bool>{
    _AdjSection.quick: true,
    _AdjSection.color: false,
    _AdjSection.light: false,
  };

  void _toggle(_AdjSection s) =>
      setState(() => _expanded[s] = !(_expanded[s] ?? false));

  bool _is(_AdjSection s) => _expanded[s] ?? false;

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final l10n = widget.l10n;
    final bloc = context.read<EditorBloc>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Quick Adjust ──────────────────────────────────────────────
          LumaGroupHeader(
            icon: Icons.tune_rounded,
            title: l10n.get('studio_control'),
            color: AppTokens.info,
            expanded: _is(_AdjSection.quick),
            onTap: () => _toggle(_AdjSection.quick),
            l10n: l10n,
          ),
          _AnimatedSection(
            visible: _is(_AdjSection.quick),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Column(children: [
                PremiumLumaSlider(
                  label: l10n.get('magic'),
                  icon: Icons.auto_fix_high_rounded,
                  value: s.snapshot.filterIntensity,
                  min: 0,
                  max: 1,
                  onChanged: (v) => bloc.add(SetIntensity(v)),
                ),
                PremiumLumaSlider(
                  label: l10n.get('brightness'),
                  icon: Icons.light_mode_rounded,
                  value: s.snapshot.brightness,
                  min: -.3,
                  max: .3,
                  onChanged: (v) =>
                      bloc.add(SetAdjustments(brightness: v)),
                ),
                PremiumLumaSlider(
                  label: l10n.get('contrast'),
                  icon: Icons.contrast_rounded,
                  value: s.snapshot.contrast,
                  min: -.25,
                  max: .4,
                  onChanged: (v) =>
                      bloc.add(SetAdjustments(contrast: v)),
                ),
                // Quick Enhance + Reset row
                const SizedBox(height: 4),
                _ActionRow(
                  onReset: () => bloc.add(ResetAdjustments()),
                  onEnhance: widget.enhancing ? null : widget.onAutoEnhance,
                  enhancing: widget.enhancing,
                  l10n: l10n,
                ),
              ]),
            ),
          ),

          _LumaDivider(accent: AppTokens.info),

          // ── Color ─────────────────────────────────────────────────────
          LumaGroupHeader(
            icon: Icons.color_lens_outlined,
            title: l10n.get('saturation'),
            color: AppTokens.warning,
            expanded: _is(_AdjSection.color),
            onTap: () => _toggle(_AdjSection.color),
            l10n: l10n,
          ),
          _AnimatedSection(
            visible: _is(_AdjSection.color),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Column(children: [
                PremiumLumaSlider(
                  label: l10n.get('saturation'),
                  icon: Icons.color_lens_outlined,
                  value: s.snapshot.saturation,
                  min: -.25,
                  max: .45,
                  onChanged: (v) =>
                      bloc.add(SetAdjustments(saturation: v)),
                ),
                PremiumLumaSlider(
                  label: l10n.get('warmth'),
                  icon: Icons.wb_sunny_outlined,
                  value: s.snapshot.warmth,
                  min: -.3,
                  max: .3,
                  onChanged: (v) =>
                      bloc.add(SetAdjustments(warmth: v)),
                ),
              ]),
            ),
          ),

          _LumaDivider(accent: AppTokens.warning),

          // ── Light ─────────────────────────────────────────────────────
          LumaGroupHeader(
            icon: Icons.wb_sunny_outlined,
            title: l10n.get('fade'),
            color: AppTokens.primary,
            expanded: _is(_AdjSection.light),
            onTap: () => _toggle(_AdjSection.light),
            l10n: l10n,
          ),
          _AnimatedSection(
            visible: _is(_AdjSection.light),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Column(children: [
                PremiumLumaSlider(
                  label: l10n.get('fade'),
                  icon: Icons.blur_on_outlined,
                  value: s.snapshot.fade,
                  min: 0,
                  max: .18,
                  onChanged: (v) =>
                      bloc.add(SetAdjustments(fade: v)),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────────────────────

enum _AdjSection { quick, color, light }

/// Smooth expand / collapse animation wrapper
class _AnimatedSection extends StatelessWidget {
  final bool visible;
  final Widget child;
  const _AnimatedSection({required this.visible, required this.child});

  @override
  Widget build(BuildContext context) => AnimatedCrossFade(
        duration: AppTokens.normal,
        crossFadeState:
            visible ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        firstChild: child,
        secondChild: const SizedBox.shrink(),
        sizeCurve: Curves.easeInOutCubic,
      );
}

/// Thin separator between sections
class _LumaDivider extends StatelessWidget {
  final Color accent;
  const _LumaDivider({required this.accent});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Divider(
          color: accent.withValues(alpha: .10),
          thickness: 1,
          height: 1,
        ),
      );
}

/// Reset + Auto Enhance row at the bottom of Quick Adjust
class _ActionRow extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback? onEnhance;
  final bool enhancing;
  final AppL10n l10n;

  const _ActionRow({
    required this.onReset,
    required this.onEnhance,
    required this.enhancing,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt_rounded, size: 15),
            label: Text(l10n.get('reset'),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTokens.text2,
              side: BorderSide(
                  color: Colors.white.withValues(alpha: .15)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding:
                  const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: onEnhance,
            icon: Icon(
              enhancing
                  ? Icons.hourglass_top_rounded
                  : Icons.auto_fix_high_rounded,
              size: 15,
            ),
            label: Text(
              enhancing ? l10n.get('loading') : l10n.get('enhance'),
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTokens.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding:
                  const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ]);
}
