// pro_tokens.dart
import 'package:flutter/material.dart';

class PT {
  PT._();

  static const bg = Color(0xFF080C10);
  static const surface = Color(0xFF0D1520);
  static const card = Color(0xFF111A27);
  static const card2 = Color(0xFF16202E);

  static const mint = Color(0xFF2EE59D);
  static const cyan = Color(0xFF00D4FF);
  static const purple = Color(0xFF9B6DFF);
  static const gold = Color(0xFFFFD166);
  static const coral = Color(0xFFFF6B7A);

  static const t1 = Color(0xFFF4F6FB);
  static const t2 = Color(0xFFB0B8C8);
  static const t3 = Color(0xFF5A6578);

  static const danger = Color(0xFFFF6B7A);
  static const warning = Color(0xFFFFD166);

  static const gradMint = LinearGradient(
    colors: [Color(0xFF2EE59D), Color(0xFF00D4FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const gradPurple = LinearGradient(
    colors: [Color(0xFF9B6DFF), Color(0xFFE040FB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradMintV = LinearGradient(
    colors: [Color(0xFF2EE59D), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Radius
  static const r8 = 8.0;
  static const r12 = 12.0;
  static const r16 = 16.0;
  static const r20 = 20.0;
  static const r24 = 24.0;
  static const r32 = 32.0;
  static const rFull = 999.0;

  // Spacing
  static const s4 = 4.0;
  static const s6 = 6.0;
  static const s7 = 7.0;
  static const s8 = 8.0;
  static const s10 = 10.0;
  static const s12 = 12.0;
  static const s14 = 14.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;

  // Durations
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 480);

  // Shadows
  static List<BoxShadow> glow(Color c, {double spread = 0, double blur = 24}) =>
      [
        BoxShadow(
            color: c.withOpacity(0.35), blurRadius: blur, spreadRadius: spread),
      ];

  static const elevation = [
    BoxShadow(color: Colors.black45, blurRadius: 24, offset: Offset(0, 8)),
  ];

  // Dynamic (theme-aware)
  static Color bgOf(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? bg
          : const Color(0xFFF2F4F7);

  static Color cardOf(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark ? card : Colors.white;

  static Color textOf(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? t1
          : const Color(0xFF1A1F2E);

  static Color strokeOf(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? Colors.white12
          : Colors.black12;
}
