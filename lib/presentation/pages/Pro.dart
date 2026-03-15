// pro_responsive.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

enum Device { phone, tablet, desktop }

class Pro {
  Pro._();

  static Device device(BuildContext ctx) {
    final w = MediaQuery.sizeOf(ctx).width;
    if (w >= 1100) return Device.desktop;
    if (w >= 650) return Device.tablet;
    return Device.phone;
  }

  static bool isPhone(BuildContext ctx) => device(ctx) == Device.phone;
  static bool isTablet(BuildContext ctx) => device(ctx) == Device.tablet;
  static bool isDesktop(BuildContext ctx) => device(ctx) == Device.desktop;

  static T val<T>(
    BuildContext ctx, {
    required T phone,
    T? tablet,
    T? desktop,
  }) {
    switch (device(ctx)) {
      case Device.desktop:
        return desktop ?? tablet ?? phone;
      case Device.tablet:
        return tablet ?? phone;
      case Device.phone:
        return phone;
    }
  }

  static double _scale(BuildContext ctx) {
    final s = math.min(
      MediaQuery.sizeOf(ctx).width,
      MediaQuery.sizeOf(ctx).height,
    );
    return (s / 390.0).clamp(0.8, 1.3);
  }

  static double sp(BuildContext ctx, double v) => v * _scale(ctx);

  static EdgeInsets pad(BuildContext ctx) => val(
        ctx,
        phone: const EdgeInsets.symmetric(horizontal: 16),
        tablet: const EdgeInsets.symmetric(horizontal: 28),
        desktop: const EdgeInsets.symmetric(horizontal: 48),
      );

  static double sheetH(BuildContext ctx) => val(
        ctx,
        phone: 340.0,
        tablet: 360.0,
        desktop: 380.0,
      );

  static double canvasW(BuildContext ctx) => val(
        ctx,
        phone: double.infinity,
        tablet: 540.0,
        desktop: 660.0,
      );

  static EdgeInsets topPad(BuildContext ctx) => val(
        ctx,
        phone: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tablet: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        desktop: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      );
}

class AdaptiveLayout extends StatelessWidget {
  final Widget phone;
  final Widget? tablet;
  final Widget? desktop;

  const AdaptiveLayout({
    super.key,
    required this.phone,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      if (c.maxWidth >= 1100 && desktop != null) return desktop!;
      if (c.maxWidth >= 650 && tablet != null) return tablet!;
      return phone;
    });
  }
}
