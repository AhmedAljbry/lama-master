import 'package:flutter/material.dart';
import 'package:lama/core/ui/tokens.dart';
import 'package:lama/core/ui/AppL10n.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Atoms
// ─────────────────────────────────────────────────────────────────────────────

class LumaTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const LumaTag({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: .26))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w800)),
        ]),
      );
}

class LumaTinyIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback? onTap;

  const LumaTinyIcon({
    super.key,
    required this.icon,
    required this.active,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: active
                  ? color.withValues(alpha: .14)
                  : Colors.white.withValues(alpha: .05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: active
                      ? color.withValues(alpha: .48)
                      : Colors.white10)),
          child: Icon(icon, color: active ? color : AppTokens.text2, size: 18),
        ),
      );
}

class LumaCapsuleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const LumaCapsuleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
              color: color.withValues(alpha: onTap == null ? .05 : .14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: color.withValues(alpha: onTap == null ? .10 : .34))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                size: 14, color: onTap == null ? AppTokens.text3 : color),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: onTap == null ? AppTokens.text3 : color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900)),
          ]),
        ),
      );
}

class LumaGlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const LumaGlowBlob({
    super.key,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  RadialGradient(colors: [color, color.withValues(alpha: 0)]))));
}

// ─────────────────────────────────────────────────────────────────────────────
// Panel Tab Enum  (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

enum LumaPanelTab { ai, filters, adjust, tools }

// ─────────────────────────────────────────────────────────────────────────────
// Section widgets
// ─────────────────────────────────────────────────────────────────────────────

class LumaSectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accentColor;

  const LumaSectionLabel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: accentColor.withValues(alpha: .24)),
            ),
            child: Icon(Icons.dashboard_customize_rounded,
                color: accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      color: AppTokens.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppTokens.text2, fontSize: 11, height: 1.45)),
            ]),
          ),
        ],
      );
}

class LumaSectionShell extends StatelessWidget {
  final Color accentColor;
  final Widget child;

  const LumaSectionShell({
    super.key,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: .08),
              AppTokens.card.withValues(alpha: .94),
              Colors.white.withValues(alpha: .03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: accentColor.withValues(alpha: .18)),
        ),
        child: child,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// NEW: Group Header for expandable sections
// ─────────────────────────────────────────────────────────────────────────────

class LumaGroupHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback? onReset;
  final AppL10n? l10n;

  const LumaGroupHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.expanded,
    required this.onTap,
    this.onReset,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: expanded ? .18 : .08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: color.withValues(
                        alpha: expanded ? .38 : .16)),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      color: expanded ? AppTokens.text : AppTokens.text2,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ),
            if (onReset != null)
              GestureDetector(
                onTap: onReset,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(l10n?.get('reset') ?? 'Reset',
                      style: TextStyle(
                          color: color.withValues(alpha: .80),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: AppTokens.normal,
              child: Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: AppTokens.text2),
            ),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats & Misc
// ─────────────────────────────────────────────────────────────────────────────

class LumaOverviewStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const LumaOverviewStat({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: color.withValues(alpha: .18)),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppTokens.text2,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ]),
      );
}

class LumaSearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const LumaSearchBox(
      {super.key, required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        cursorColor: AppTokens.primary,
        style: const TextStyle(color: AppTokens.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTokens.text3),
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppTokens.text3),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: controller.clear,
                  icon: const Icon(Icons.close_rounded,
                      color: AppTokens.text3),
                ),
          filled: true,
          fillColor: AppTokens.card.withValues(alpha: .78),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: .08))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: AppTokens.primary.withValues(alpha: .70),
                  width: 1.2)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// IMPROVED: PremiumLumaSlider
//   • Shows signed integer value (+37, 0, -12) for symmetric sliders
//   • Shows green center-mark on the track when min < 0 < max
// ─────────────────────────────────────────────────────────────────────────────

class PremiumLumaSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const PremiumLumaSlider({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  String _displayValue() {
    final symmetric = min < 0 && max > 0;
    if (!symmetric) {
      // non-symmetric (e.g. filterIntensity 0–1, fade 0–0.18): percent
      final pct = max == min
          ? 0
          : (((value - min) / (max - min)) * 100).round();
      return '$pct%';
    }
    // symmetric: show signed integer scaled to ±100
    final range = max - min; // total range
    final scaled = ((value / (range / 2)) * 100).round();
    if (scaled == 0) return '0';
    return scaled > 0 ? '+$scaled' : '$scaled';
  }

  bool get _symmetric => min < 0 && max > 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 15, color: AppTokens.text2),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppTokens.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w700))),
          AnimatedSwitcher(
            duration: AppTokens.fast,
            child: Text(
              _displayValue(),
              key: ValueKey(_displayValue()),
              style: TextStyle(
                  color: _symmetric && value.abs() > 0.001
                      ? AppTokens.primary
                      : AppTokens.text2,
                  fontSize: 12,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.center,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTokens.primary,
                  inactiveTrackColor: Colors.white.withValues(alpha: .10),
                  thumbColor: AppTokens.primary,
                  overlayColor:
                      AppTokens.primary.withValues(alpha: .12),
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7),
                  overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16)),
              child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  onChanged: onChanged),
            ),
            // Centre-mark for symmetric sliders
            if (_symmetric)
              IgnorePointer(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 2,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTokens.primary.withValues(alpha: .35),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ]),
    );
  }
}
