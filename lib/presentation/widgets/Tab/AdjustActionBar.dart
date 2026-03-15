import 'package:flutter/material.dart';

import 'package:lama/core/Responsive_Helper/ResponsiveHelper.dart';
import 'package:lama/core/Stayl/Them.dart';
import 'package:lama/core/i18n/t.dart';

class AdjustActionBar extends StatelessWidget {
  final Lang lang;
  final VoidCallback? onReset;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;
  final bool advanced;
  final VoidCallback onToggleAdvanced;
  final VoidCallback? onCompareHoldStart;
  final VoidCallback? onCompareHoldEnd;

  const AdjustActionBar({
    super.key,
    required this.lang,
    required this.canUndo,
    required this.canRedo,
    required this.advanced,
    required this.onToggleAdvanced,
    this.onReset,
    this.onUndo,
    this.onRedo,
    this.onCompareHoldStart,
    this.onCompareHoldEnd,
  });

  @override
  Widget build(BuildContext context) {
    final t = T(lang);

    return Row(
      children: [
        Expanded(
          child: _ActionPill(
            label: advanced
                ? '${t.of('advanced')}: ON'
                : '${t.of('advanced')}: OFF',
            onTap: onToggleAdvanced,
            active: advanced,
          ),
        ),
        SizedBox(width: R.sp(context, 8)),
        Expanded(
          child: _ActionPill(
            label: t.of('undo'),
            onTap: onUndo,
            disabled: !canUndo,
          ),
        ),
        SizedBox(width: R.sp(context, 8)),
        Expanded(
          child: _ActionPill(
            label: t.of('redo'),
            onTap: onRedo,
            disabled: !canRedo,
          ),
        ),
        SizedBox(width: R.sp(context, 8)),
        Expanded(
          child: GestureDetector(
            onLongPressStart: (_) => onCompareHoldStart?.call(),
            onLongPressEnd: (_) => onCompareHoldEnd?.call(),
            child: _ActionPill(
              label: t.of('compare_hold'),
              onTap: null,
            ),
          ),
        ),
        SizedBox(width: R.sp(context, 8)),
        Expanded(
          child: _ActionPill(
            label: t.of('reset'),
            onTap: onReset,
          ),
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool disabled;
  final bool active;

  const _ActionPill({
    required this.label,
    required this.onTap,
    this.disabled = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = active ? AppUI.text : AppUI.sub;
    final borderColor = active ? AppUI.text.withOpacity(0.18) : AppUI.stroke;

    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(R.radius(context, 999)),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: R.sp(context, 12),
            vertical: R.sp(context, 10),
          ),
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(R.radius(context, 999)),
            border: Border.all(color: borderColor),
          ),
          child: Center(
            child: Text(
              label,
              style: R.t(
                context,
                11,
                w: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
