import 'package:flutter/material.dart';
import 'package:lama/core/ui/AppL10n.dart';

class PremiumEmptyState extends StatelessWidget {
  final Color primaryColor;
  final Color surfaceColor;
  final Color textColor;
  final Color text2Color;
  final AppL10n l10n;
  final VoidCallback onPick;

  const PremiumEmptyState({
    super.key,
    required this.primaryColor,
    required this.surfaceColor,
    required this.textColor,
    required this.text2Color,
    required this.l10n,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onPick,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 12,
              left: 30,
              child:
                  _Halo(color: primaryColor.withValues(alpha: 0.16), size: 180),
            ),
            Positioned(
              bottom: 0,
              right: 18,
              child:
                  _Halo(color: text2Color.withValues(alpha: 0.10), size: 140),
            ),
            Container(
              width: 320,
              padding: EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    surfaceColor.withValues(alpha: 0.78),
                    surfaceColor.withValues(alpha: 0.58),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.22),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.08),
                    blurRadius: 46,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withValues(alpha: 0.22),
                          primaryColor.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 48,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniBadge(label: 'AI', color: primaryColor),
                      _MiniBadge(
                          label: 'COLOR',
                          color: textColor.withValues(alpha: 0.85)),
                      _MiniBadge(
                          label: 'PRO',
                          color: text2Color.withValues(alpha: 0.85)),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    l10n.get('tap_to_open'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    l10n.get('welcome_sub'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: text2Color,
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                  SizedBox(height: 18),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: primaryColor.withValues(alpha: 0.24)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_upward_rounded,
                          size: 18,
                          color: primaryColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          l10n.get('pick_hint'),
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
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

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _Halo extends StatelessWidget {
  final Color color;
  final double size;

  const _Halo({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
