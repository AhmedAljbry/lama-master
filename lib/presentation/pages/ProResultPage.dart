// pro_result_page.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lama/core/i18n/t.dart';
import 'package:lama/presentation/pages/PT.dart';
import 'package:lama/presentation/pages/Pro.dart'; // ← T, Lang (real import — NO stubs)


// ─────────────────────────────────────────────────────────────────
class ProResultPage extends StatefulWidget {
  final File imageFile;
  final Widget Function(File) canvasBuilder;
  final T t;
  final VoidCallback onEditAgain;
  final VoidCallback onNewImage;
  final Future<void> Function() onSave;

  const ProResultPage({
    super.key,
    required this.imageFile,
    required this.canvasBuilder,
    required this.t,
    required this.onEditAgain,
    required this.onNewImage,
    required this.onSave,
  });

  @override
  State<ProResultPage> createState() => _ProResultPageState();
}

class _ProResultPageState extends State<ProResultPage>
    with TickerProviderStateMixin {

  bool _isSaving   = false;
  bool _comparing  = false;
  bool _showBadge  = true;

  late final AnimationController _enterCtrl;
  late final AnimationController _badgeCtrl;
  late final Animation<double> _enterScale;
  late final Animation<double> _enterFade;
  late final Animation<double> _badgeFade;

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _badgeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    _enterScale = CurvedAnimation(
        parent: _enterCtrl, curve: Curves.easeOutCubic)
        .drive(Tween(begin: 0.94, end: 1.0));
    _enterFade = CurvedAnimation(
        parent: _enterCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _badgeFade = CurvedAnimation(
        parent: _badgeCtrl, curve: Curves.easeInOut)
        .drive(Tween(begin: 1.0, end: 0.0));

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _badgeCtrl.forward().then((_) {
          if (mounted) setState(() => _showBadge = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _badgeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    try {
      await widget.onSave();
      if (mounted) _showSnack(widget.t.of('saved'), PT.mint);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PT.r16)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Directionality(
      textDirection: t.isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: PT.bg,
        body: SafeArea(
          child: AdaptiveLayout(
            phone:   _phone(context, t),
            tablet:  _wide(context, t, panelW: 260),
            desktop: _wide(context, t, panelW: 300),
          ),
        ),
      ),
    );
  }

  // ─── Phone ──────────────────────────────────────────────────────
  Widget _phone(BuildContext ctx, T t) {
    return Column(
      children: [
        _TopBar(t: t, onBack: widget.onEditAgain),
        Expanded(
          child: AnimatedBuilder(
            animation: _enterCtrl,
            builder: (_, child) => Transform.scale(
              scale: _enterScale.value,
              child: Opacity(
                  opacity: _enterFade.value, child: child),
            ),
            child: _ImageArea(
              imageFile: widget.imageFile,
              canvasBuilder: widget.canvasBuilder,
              comparing: _comparing,
              showBadge: _showBadge,
              badgeFade: _badgeFade,
              t: t,
              onCompareStart: () =>
                  setState(() => _comparing = true),
              onCompareEnd: () =>
                  setState(() => _comparing = false),
            ),
          ),
        ),
        _ActionBar(
          t: t,
          isSaving: _isSaving,
          onSave: _handleSave,
          onEdit: widget.onEditAgain,
          onNew: widget.onNewImage,
        ),
      ],
    );
  }

  // ─── Tablet / Desktop (side panel) ──────────────────────────────
  Widget _wide(BuildContext ctx, T t, {required double panelW}) {
    final sizeKB =
    (widget.imageFile.lengthSync() / 1024).toStringAsFixed(0);

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _TopBar(t: t, onBack: widget.onEditAgain),
              Expanded(
                child: _ImageArea(
                  imageFile: widget.imageFile,
                  canvasBuilder: widget.canvasBuilder,
                  comparing: _comparing,
                  showBadge: _showBadge,
                  badgeFade: _badgeFade,
                  t: t,
                  onCompareStart: () =>
                      setState(() => _comparing = true),
                  onCompareEnd: () =>
                      setState(() => _comparing = false),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: panelW,
          color: PT.surface,
          padding: const EdgeInsets.all(PT.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: PT.s32),
              // Info card
              Container(
                padding: const EdgeInsets.all(PT.s16),
                decoration: BoxDecoration(
                  color: PT.card,
                  borderRadius: BorderRadius.circular(PT.r16),
                  border: Border.all(
                      color: PT.mint.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    _InfoRow(label: 'Format', value: 'JPEG'),
                    _InfoRow(label: 'Size', value: '$sizeKB KB'),
                    _InfoRow(label: 'Quality', value: 'Max'),
                  ],
                ),
              ),
              const Spacer(),
              _GradBtn(
                label: _isSaving
                    ? t.of('loading')
                    : t.of('result_save'),
                icon: Icons.download_rounded,
                onTap: _handleSave,
                loading: _isSaving,
              ),
              const SizedBox(height: PT.s12),
              _OutlineBtn(
                  label: t.of('result_edit'),
                  icon: Icons.edit_rounded,
                  onTap: widget.onEditAgain),
              const SizedBox(height: PT.s8),
              _OutlineBtn(
                  label: t.of('result_new'),
                  icon: Icons.add_photo_alternate_rounded,
                  onTap: widget.onNewImage),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final T t;
  final VoidCallback onBack;
  const _TopBar({required this.t, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: PT.card,
                borderRadius: BorderRadius.circular(PT.r12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: PT.t2,
                  size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (b) =>
                    PT.gradMint.createShader(b),
                child: Text(
                  t.of('result_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                t.of('result_subtitle'),
                style: const TextStyle(
                    color: PT.t2,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Image Area ───────────────────────────────────────────────────
class _ImageArea extends StatelessWidget {
  final File imageFile;
  final Widget Function(File) canvasBuilder;
  final bool comparing;
  final bool showBadge;
  final Animation<double> badgeFade;
  final T t;
  final VoidCallback onCompareStart;
  final VoidCallback onCompareEnd;

  const _ImageArea({
    required this.imageFile,
    required this.canvasBuilder,
    required this.comparing,
    required this.showBadge,
    required this.badgeFade,
    required this.t,
    required this.onCompareStart,
    required this.onCompareEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onLongPressStart: (_) => onCompareStart(),
            onLongPressEnd: (_) => onCompareEnd(),
            child: ConstrainedBox(
              constraints:
              BoxConstraints(maxWidth: Pro.canvasW(context)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(PT.r20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: comparing
                      ? Image.file(
                    imageFile,
                    key: const ValueKey('orig'),
                    fit: BoxFit.contain,
                    width: double.infinity,
                  )
                      : canvasBuilder(imageFile),
                ),
              ),
            ),
          ),
          if (comparing)
            Positioned(
              top: 16,
              left: 16,
              child: _Label(
                  text: t.of('before'), color: PT.t2),
            ),
          if (showBadge)
            Positioned(
              bottom: 16,
              child: FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.0)
                    .animate(badgeFade),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius:
                    BorderRadius.circular(PT.rFull),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                          Icons.compare_arrows_rounded,
                          color: PT.t3,
                          size: 13),
                      const SizedBox(width: PT.s8),
                      Text(t.of('compare_hold'),
                          style: const TextStyle(
                              color: PT.t3,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Action Bar ───────────────────────────────────────────────────
class _ActionBar extends StatelessWidget {
  final T t;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onEdit;
  final VoidCallback onNew;

  const _ActionBar({
    required this.t,
    required this.isSaving,
    required this.onSave,
    required this.onEdit,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
          top: Radius.circular(PT.r24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding:
          const EdgeInsets.fromLTRB(16, 16, 16, 24),
          decoration: BoxDecoration(
            color: PT.surface.withOpacity(0.92),
            border: Border(
                top: BorderSide(
                    color: PT.mint.withOpacity(0.1))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GradBtn(
                label: isSaving
                    ? t.of('loading')
                    : t.of('result_save'),
                icon: Icons.download_rounded,
                onTap: onSave,
                loading: isSaving,
                fullWidth: true,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _OutlineBtn(
                        label: t.of('result_edit'),
                        icon: Icons.edit_rounded,
                        onTap: onEdit),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OutlineBtn(
                        label: t.of('result_new'),
                        icon:
                        Icons.add_photo_alternate_rounded,
                        onTap: onNew),
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

// ─── Shared Atoms ─────────────────────────────────────────────────
class _GradBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool loading;
  final bool fullWidth;

  const _GradBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: 50,
        decoration: BoxDecoration(
          gradient: loading ? null : PT.gradMint,
          color: loading ? PT.card : null,
          borderRadius: BorderRadius.circular(PT.r16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            loading
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black),
            )
                : Icon(icon, color: Colors.black, size: 18),
            const SizedBox(width: PT.s8),
            Text(label,
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _OutlineBtn(
      {required this.label,
        required this.icon,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: PT.card,
          borderRadius: BorderRadius.circular(PT.r16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: PT.t2, size: 16),
            const SizedBox(width: PT.s8),
            Text(label,
                style: const TextStyle(
                    color: PT.t2,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(PT.rFull),
      ),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PT.s4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: PT.t2, fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: PT.t1,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
