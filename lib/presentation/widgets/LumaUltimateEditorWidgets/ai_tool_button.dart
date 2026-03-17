import 'package:flutter/material.dart';

class AIToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color surface;
  final Color textColor;
  final VoidCallback? onTap;

  const AIToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.surface,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              enabled
                  ? iconColor.withValues(alpha: 0.14)
                  : surface.withValues(alpha: 0.48),
              surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: iconColor.withValues(alpha: enabled ? 0.30 : 0.14)),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: enabled ? 0.10 : 0.04),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: enabled ? 0.16 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 18,
                color: enabled ? iconColor : iconColor.withValues(alpha: 0.4),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: enabled ? textColor : textColor.withValues(alpha: 0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: enabled ? iconColor : iconColor.withValues(alpha: 0.28),
            ),
          ],
        ),
      ),
    );
  }
}
