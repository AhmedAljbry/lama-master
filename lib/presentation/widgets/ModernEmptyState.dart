import 'package:flutter/material.dart';
import 'package:lama/core/Responsive_Helper/ResponsiveHelper.dart';
import 'package:lama/core/Stayl/Them.dart';

class ModernEmptyState extends StatefulWidget {
  final VoidCallback onTap;
  const ModernEmptyState({super.key, required this.onTap});

  @override
  State<ModernEmptyState> createState() => _ModernEmptyStateState();
}

class _ModernEmptyStateState extends State<ModernEmptyState> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final r = R.radius(context, 26);

    return Center(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _pressed ? 0.98 : 1.0,
          child: Container(
            width: (R.w(context) * 0.82).clamp(280, 460),
            padding: EdgeInsets.all(R.pad(context, 18)),
            decoration: BoxDecoration(
              color: AppUI.card.withOpacity(0.75),
              borderRadius: BorderRadius.circular(r),
              border: Border.all(color: AppUI.stroke),
              boxShadow: AppUI.softShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: R.sp(context, 54),
                  height: R.sp(context, 54),
                  decoration: BoxDecoration(
                    color: AppUI.accent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(R.radius(context, 18)),
                    border: Border.all(color: AppUI.accent.withOpacity(0.25)),
                  ),
                  child: Icon(Icons.add_photo_alternate, color: AppUI.text, size: R.sp(context, 26)),
                ),
                SizedBox(width: R.pad(context, 14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Start editing", style: R.t(context, 14, w: FontWeight.w800, color: AppUI.text)),
                      SizedBox(height: R.sp(context, 6)),
                      Text(
                        "Pick an image to apply presets and cinematic effects.",
                        style: R.t(context, 12, w: FontWeight.w600, color: AppUI.sub, height: 1.2),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppUI.sub, size: R.sp(context, 26)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}