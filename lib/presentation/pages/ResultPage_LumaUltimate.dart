// result_page.dart — Result & Export Page
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lama/core/utils/Responsive.dart';

import '../../core/i18n/t.dart';
import '../../core/ui/tokens.dart';



class ResultpageLumaultimate extends StatefulWidget {
  final String imagePath;
  final List<double> colorMatrix;
  final T t;
  final VoidCallback onEditAgain;
  final VoidCallback onNewImage;
  final Future<void> Function(T t) onSave;

  const ResultpageLumaultimate({
    super.key,
    required this.imagePath,
    required this.colorMatrix,
    required this.t,
    required this.onEditAgain,
    required this.onNewImage,
    required this.onSave,
  });

  @override
  State<ResultpageLumaultimate> createState() => _ResultpageLumaultimateState();
}

class _ResultpageLumaultimateState extends State<ResultpageLumaultimate>
    with SingleTickerProviderStateMixin {

  final GlobalKey _repaintKey = GlobalKey();
  bool _isSaving = false;
  bool _showOriginal = false;
  bool _showInfo = false;

  late final AnimationController _enterCtrl;
  late final Animation<double> _enterScale;
  late final Animation<double> _enterOpacity;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _enterScale = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutBack)
        .drive(Tween(begin: 0.92, end: 1.0));
    _enterOpacity = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(widget.t);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final isTablet = Responsive.isTablet(context) || Responsive.isDesktop(context);

    return Directionality(
      textDirection: t.isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppTokens.bg,
        body: SafeArea(
          child: isTablet
              ? _buildTabletLayout(context, t)
              : _buildPhoneLayout(context, t),
        ),
      ),
    );
  }

  // ─── Phone Layout ─────────────────────────────────────────────
  Widget _buildPhoneLayout(BuildContext context, T t) {
    return Column(
      children: [
        _buildTopBar(context, t),
        Expanded(
          child: AnimatedBuilder(
            animation: _enterCtrl,
            builder: (_, child) => Transform.scale(
              scale: _enterScale.value,
              child: Opacity(opacity: _enterOpacity.value, child: child),
            ),
            child: _buildImageArea(context),
          ),
        ),
        _buildActionBar(context, t),
      ],
    );
  }

  // ─── Tablet/Desktop Layout ────────────────────────────────────
  Widget _buildTabletLayout(BuildContext context, T t) {
    return Row(
      children: [
        // Image side
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildTopBar(context, t),
              Expanded(child: _buildImageArea(context)),
            ],
          ),
        ),
        // Controls side
        SizedBox(
          width: 280,
          child: Container(
            color: AppTokens.surface,
            child: Column(
              children: [
                const SizedBox(height: 32),
                _buildResultInfo(context, t),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildVerticalActions(context, t),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Top Bar ──────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, T t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: widget.onEditAgain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.of('result_title'),
                  style: const TextStyle(
                    color: AppTokens.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                Text(
                  t.of('result_subtitle'),
                  style: const TextStyle(
                    color: AppTokens.text2,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _GlassIconButton(
            icon: _showInfo ? Icons.info : Icons.info_outline,
            onTap: () => setState(() => _showInfo = !_showInfo),
            color: _showInfo ? AppTokens.primary : null,
          ),
        ],
      ),
    );
  }

  // ─── Image Area ───────────────────────────────────────────────
  Widget _buildImageArea(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Image
          RepaintBoundary(
            key: _repaintKey,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.r20),
              child: GestureDetector(
                onLongPressStart: (_) => setState(() => _showOriginal = true),
                onLongPressEnd: (_) => setState(() => _showOriginal = false),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _showOriginal
                      ? Image.file(
                    File(widget.imagePath),
                    key: const ValueKey('original'),
                    fit: BoxFit.contain,
                    width: double.infinity,
                  )
                      : ColorFiltered(
                    key: const ValueKey('filtered'),
                    colorFilter: ColorFilter.matrix(widget.colorMatrix),
                    child: Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // "Hold to compare" badge
          Positioned(
            bottom: 16,
            child: _HoldCompareBadge(t: widget.t),
          ),

          // Info overlay
          if (_showInfo)
            Positioned.fill(
              child: _InfoOverlay(imagePath: widget.imagePath),
            ),
        ],
      ),
    );
  }

  // ─── Action Bar (Phone) ───────────────────────────────────────
  Widget _buildActionBar(BuildContext context, T t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.r24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Save button (primary)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _handleSave,
              icon: _isSaving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
                  : const Icon(Icons.download_rounded, size: 20),
              label: Text(
                _isSaving ? widget.t.of('loading') : t.of('result_save'),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.r16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Secondary buttons row
          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  icon: Icons.edit_rounded,
                  label: t.of('result_edit'),
                  onTap: widget.onEditAgain,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SecondaryButton(
                  icon: Icons.add_photo_alternate_rounded,
                  label: t.of('result_new'),
                  onTap: widget.onNewImage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Vertical Actions (Tablet) ────────────────────────────────
  Widget _buildVerticalActions(BuildContext context, T t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _handleSave,
          icon: const Icon(Icons.download_rounded),
          label: Text(t.of('result_save')),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: widget.onEditAgain,
          icon: const Icon(Icons.edit_rounded),
          label: Text(t.of('result_edit')),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: widget.onNewImage,
          icon: const Icon(Icons.add_photo_alternate_rounded),
          label: Text(t.of('result_new')),
        ),
      ],
    );
  }

  // ─── Result Info Panel ────────────────────────────────────────
  Widget _buildResultInfo(BuildContext context, T t) {
    final file = File(widget.imagePath);
    final sizeKB = (file.lengthSync() / 1024).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.of('result_title'),
            style: const TextStyle(
              color: AppTokens.primary,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'File Size', value: '$sizeKB KB'),
          _InfoRow(label: 'Format', value: 'JPEG'),
          _InfoRow(label: 'Filter Applied', value: '✓'),
        ],
      ),
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTokens.card,
          borderRadius: BorderRadius.circular(AppTokens.r12),
          border: Border.all(
            color: AppTokens.text2.withOpacity(0.1),
          ),
        ),
        child: Icon(icon, color: color ?? AppTokens.text2, size: 18),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppTokens.card,
          borderRadius: BorderRadius.circular(AppTokens.r16),
          border: Border.all(color: AppTokens.text2.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppTokens.text2),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTokens.text2,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldCompareBadge extends StatelessWidget {
  final T t;
  const _HoldCompareBadge({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.compare, color: Colors.white54, size: 14),
          const SizedBox(width: 6),
          Text(
            t.of('compare_hold'),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoOverlay extends StatelessWidget {
  final String imagePath;
  const _InfoOverlay({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.r20),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Icon(
            Icons.check_circle_outline_rounded,
            color: AppTokens.primary,
            size: 64,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTokens.text2, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppTokens.text, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}
