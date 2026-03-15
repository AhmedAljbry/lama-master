import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lama/core/routing/app_routes.dart';

enum Lang { ar, en }

class _DashboardCopy {
  final Lang lang;

  const _DashboardCopy(this.lang);

  bool get isArabic => lang == Lang.ar;

  String text(String key) {
    const ar = <String, String>{
      'welcome': 'مرحباً، صانع المحتوى',
      'subtitle':
          'اختر الاستوديو المناسب وابدأ بسرعة من شاشة رئيسية واحدة واضحة وسهلة.',
      'eyebrow': 'لوحة الاستوديوهات',
      'stats_title': 'كل أدواتك جاهزة في مكان واحد',
      'stats_subtitle':
          'تصميم متجاوب، وصول أسرع، وتجربة أوضح بين التحرير والذكاء الاصطناعي والرسم.',
      'lang': 'EN',
      'open': 'فتح الآن',
      'ai_badge': 'جديد',
      'luma_title': 'Luma Color',
      'luma_desc':
          'تصحيح ألوان متقدم، فلاتر، وتحكمات احترافية للصور بأسلوب منسق.',
      'ai_title': 'AI Studio',
      'ai_desc':
          'نقل أسلوب ذكي مع قناع AI ورسّام تحسين للحواف داخل صفحة مستقلة.',
      'pro_title': 'Pro Studio',
      'pro_desc':
          'تأثيرات احترافية ولمسات سينمائية بطابع قوي مناسب للمشاهد الإبداعية.',
      'intel_title': 'تحليل موقع الصورة',
      'intel_desc':
          'افحص EXIF وGPS واستخرج النصوص والوجوه وافتح الإحداثيات مباشرة على الخريطة.',
      'intel_badge': 'GPS',
      'magic_title': 'Magic Eraser',
      'magic_desc':
          'إزالة العناصر غير المرغوبة والرسم على القناع لمعالجة الصورة بسهولة.',
      'pill_responsive': 'متجاوب',
      'pill_fast': 'سريع',
      'pill_ai': 'ذكاء اصطناعي',
    };

    const en = <String, String>{
      'welcome': 'Welcome, Creator',
      'subtitle':
          'Choose the right studio and jump in quickly from one clean, easy home screen.',
      'eyebrow': 'Studio Dashboard',
      'stats_title': 'Everything is ready in one place',
      'stats_subtitle':
          'A more responsive layout, faster access, and a clearer flow across editing, AI, and painting.',
      'lang': 'AR',
      'open': 'Open Now',
      'ai_badge': 'New',
      'luma_title': 'Luma Color',
      'luma_desc':
          'Advanced color grading, filters, and polished photo controls in one workspace.',
      'ai_title': 'AI Studio',
      'ai_desc':
          'Smart style transfer with AI masking and a dedicated edge-refine painter in its own page.',
      'pro_title': 'Pro Studio',
      'pro_desc':
          'Bold cinematic effects and premium looks for more stylized creative work.',
      'intel_title': 'Image Intel',
      'intel_desc':
          'Inspect EXIF and GPS, extract text and faces, and open coordinates directly on the map.',
      'intel_badge': 'GPS',
      'magic_title': 'Magic Eraser',
      'magic_desc':
          'Remove unwanted objects and paint on the mask to repair your image with ease.',
      'pill_responsive': 'Responsive',
      'pill_fast': 'Fast',
      'pill_ai': 'AI Powered',
    };

    return (isArabic ? ar : en)[key] ?? key;
  }
}

class _StudioItem {
  final String title;
  final String description;
  final String route;
  final String badge;
  final IconData icon;
  final Color accent;

  const _StudioItem({
    required this.title,
    required this.description,
    required this.route,
    required this.badge,
    required this.icon,
    required this.accent,
  });
}

class PremiumDashboardPage extends StatefulWidget {
  const PremiumDashboardPage({super.key});

  @override
  State<PremiumDashboardPage> createState() => _PremiumDashboardPageState();
}

class _PremiumDashboardPageState extends State<PremiumDashboardPage>
    with SingleTickerProviderStateMixin {
  Lang _currentLang = Lang.en;
  bool _seededLang = false;
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seededLang) {
      return;
    }

    _seededLang = true;
    _currentLang = Localizations.localeOf(context).languageCode == 'ar'
        ? Lang.ar
        : Lang.en;
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = _DashboardCopy(_currentLang);
    final direction = copy.isArabic ? TextDirection.rtl : TextDirection.ltr;

    final items = <_StudioItem>[
      _StudioItem(
        title: copy.text('luma_title'),
        description: copy.text('luma_desc'),
        route: AppRoutes.lumaEditor,
        badge: 'Color',
        icon: Icons.palette_outlined,
        accent: const Color(0xFF2EE59D),
      ),
      _StudioItem(
        title: copy.text('ai_title'),
        description: copy.text('ai_desc'),
        route: AppRoutes.aiStudio,
        badge: copy.text('ai_badge'),
        icon: Icons.auto_awesome_rounded,
        accent: const Color(0xFFFFB84D),
      ),
      _StudioItem(
        title: copy.text('pro_title'),
        description: copy.text('pro_desc'),
        route: AppRoutes.proStudio,
        badge: 'Pro',
        icon: Icons.camera_enhance_rounded,
        accent: const Color(0xFF00D1FF),
      ),
      _StudioItem(
        title: copy.text('intel_title'),
        description: copy.text('intel_desc'),
        route: AppRoutes.imageIntel,
        badge: copy.text('intel_badge'),
        icon: Icons.location_searching_rounded,
        accent: const Color(0xFFFF7A18),
      ),
      _StudioItem(
        title: copy.text('magic_title'),
        description: copy.text('magic_desc'),
        route: AppRoutes.magicEraser,
        badge: 'LLaMA',
        icon: Icons.draw_rounded,
        accent: const Color(0xFF8B5CF6),
      ),
    ];

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        backgroundColor: const Color(0xFF09111A),
        body: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0A111A),
                      Color(0xFF071017),
                      Color(0xFF06111B),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _ambientController,
              builder: (context, _) {
                return Stack(
                  children: [
                    Positioned(
                      top: -120 + (_ambientController.value * 50),
                      left: -40,
                      child: const _AmbientGlow(
                        color: Color(0xFF2EE59D),
                        size: 260,
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.sizeOf(context).height * 0.28,
                      right: -70,
                      child: const _AmbientGlow(
                        color: Color(0xFF00D1FF),
                        size: 320,
                      ),
                    ),
                    Positioned(
                      bottom: -120 + ((1 - _ambientController.value) * 40),
                      left: MediaQuery.sizeOf(context).width * 0.25,
                      child: const _AmbientGlow(
                        color: Color(0xFF8B5CF6),
                        size: 280,
                      ),
                    ),
                  ],
                );
              },
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding =
                      constraints.maxWidth < 700 ? 20.0 : 32.0;
                  final gap = constraints.maxWidth < 900 ? 16.0 : 20.0;
                  final cardWidth = constraints.maxWidth >= 760
                      ? (constraints.maxWidth - (horizontalPadding * 2) - gap) /
                          2
                      : constraints.maxWidth - (horizontalPadding * 2);

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      18,
                      horizontalPadding,
                      28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(copy),
                        const SizedBox(height: 20),
                        _buildHero(copy),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: items
                              .map(
                                (item) => SizedBox(
                                  width: cardWidth,
                                  child: _StudioCard(
                                    item: item,
                                    openLabel: copy.text('open'),
                                    onTap: () => context.push(item.route),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(_DashboardCopy copy) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2EE59D), Color(0xFF00D1FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D1FF).withOpacity(0.35),
                      blurRadius: 24,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: Colors.black,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy.text('eyebrow'),
                      style: const TextStyle(
                        color: Color(0xFF9EB1C4),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      copy.text('welcome'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _GlassButton(
                label: copy.text('lang'),
                icon: Icons.language_rounded,
                onTap: () {
                  setState(() {
                    _currentLang = _currentLang == Lang.en ? Lang.ar : Lang.en;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(_DashboardCopy copy) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.03),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.text('stats_title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Text(
                  copy.text('stats_subtitle'),
                  style: const TextStyle(
                    color: Color(0xFFA5B8CA),
                    fontSize: 14,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _FeaturePill(
                    label: copy.text('pill_responsive'),
                    color: const Color(0xFF2EE59D),
                  ),
                  _FeaturePill(
                    label: copy.text('pill_fast'),
                    color: const Color(0xFF00D1FF),
                  ),
                  _FeaturePill(
                    label: copy.text('pill_ai'),
                    color: const Color(0xFFFFB84D),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                copy.text('subtitle'),
                style: const TextStyle(
                  color: Color(0xFFD9E3ED),
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudioCard extends StatelessWidget {
  final _StudioItem item;
  final String openLabel;
  final VoidCallback onTap;

  const _StudioCard({
    required this.item,
    required this.openLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.09),
              Colors.white.withOpacity(0.03),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: item.accent.withOpacity(0.12),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.accent.withOpacity(0.14),
                      boxShadow: [
                        BoxShadow(
                          color: item.accent.withOpacity(0.32),
                          blurRadius: 20,
                          spreadRadius: -6,
                        ),
                      ],
                    ),
                    child: Icon(item.icon, color: item.accent, size: 28),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: item.accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: item.accent.withOpacity(0.4)),
                    ),
                    child: Text(
                      item.badge,
                      style: TextStyle(
                        color: item.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFA6B7C7),
                  fontSize: 13.5,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: item.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: item.accent.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        openLabel,
                        style: TextStyle(
                          color: item.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_back_rounded
                        : Icons.arrow_forward_rounded,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String label;
  final Color color;

  const _FeaturePill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _AmbientGlow({
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
          color: color.withOpacity(0.16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.22),
              blurRadius: math.max(size * 0.26, 60),
              spreadRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}
