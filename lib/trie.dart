import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:share_plus/share_plus.dart';

class MaskBrushRealTestPage extends StatefulWidget {
  const MaskBrushRealTestPage({super.key});

  @override
  State<MaskBrushRealTestPage> createState() => _MaskBrushRealTestPageState();
}

class _MaskBrushRealTestPageState extends State<MaskBrushRealTestPage> {
  // ✅ سيرفرك الحقيقي
  static const String _baseUrl = "https://unimpairable-foggy-alia.ngrok-free.dev";

  ui.Image? _imageUi;
  Uint8List? _imageBytes;

  ui.Image? _resultUi;
  Uint8List? _resultBytes;

  bool _busy = false;
  String _status = "تحميل صورة...";

  // ======== Mask Drawing ========
  final List<_Stroke> _strokes = [];
  _Stroke? _active;
  bool _isEraser = false;
  double _brushPx = 36; // حجم الفرشاة على الويدجت (px)
  double _opacity = 1.0; // شفافية رسم الماسك على الويدجت

  // نحتاج مقاس الويدجت + Rect للصورة داخل الويدجت عشان mapping
  Size _canvasSize = Size.zero;
  Rect _imageRectInCanvas = Rect.zero;

  @override
  void initState() {
    super.initState();
    _loadSampleImage();
  }

  Future<void> _loadSampleImage() async {
    setState(() {
      _busy = true;
      _status = "تحميل صورة...";
      _strokes.clear();
      _active = null;
      _resultBytes = null;
      _resultUi = null;
    });

    try {
      final res = await http.get(Uri.parse("https://picsum.photos/1000/750"));
      if (res.statusCode != 200) throw Exception("Image HTTP ${res.statusCode}");
      _imageBytes = res.bodyBytes;

      final codec = await ui.instantiateImageCodec(_imageBytes!);
      final frame = await codec.getNextFrame();
      _imageUi = frame.image;

      setState(() {
        _status = "ارسم بالفرشاة على الشيء المراد مسحه ثم Submit";
      });
    } catch (e) {
      setState(() => _status = "فشل تحميل الصورة: $e");
    } finally {
      setState(() => _busy = false);
    }
  }

  // =========================================================
  // 1) Gesture: رسم Stroke على الويدجت
  // =========================================================
  void _startStroke(Offset p) {
    if (_busy) return;
    final s = _Stroke(
      isEraser: _isEraser,
      widthPx: _brushPx,
      points: [p],
    );
    setState(() {
      _active = s;
      _strokes.add(s);
    });
  }

  void _appendStroke(Offset p) {
    if (_busy) return;
    final s = _active;
    if (s == null) return;
    setState(() => s.points.add(p));
  }

  void _endStroke() {
    if (_busy) return;
    setState(() => _active = null);
  }

  void _clearMask() {
    if (_busy) return;
    setState(() {
      _strokes.clear();
      _active = null;
      _status = "تم مسح الماسك. ارسم من جديد.";
    });
  }

  // =========================================================
  // 2) Export Mask PNG (شفاف) بدقة الصورة الأصلية
  //    - الخلفية شفافة
  //    - الفرشاة: أبيض
  //    - الممحاة: تمسح فعليًا
  // =========================================================
  Future<Uint8List> _exportMaskPng() async {
    final img = _imageUi;
    if (img == null) throw Exception("No image loaded");
    if (_strokes.isEmpty) throw Exception("Mask is empty");

    if (_canvasSize == Size.zero || _imageRectInCanvas == Rect.zero) {
      throw Exception("Canvas not ready (size/rect missing)");
    }

    final int w = img.width;
    final int h = img.height;

    // سجل رسم جديد
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // ✅ طبقة شفافة
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()
        ..color = Colors.transparent
        ..blendMode = BlendMode.src,
    );

    // ✅ نستخدم saveLayer عشان الممحاة تشتغل بـ clear
    canvas.saveLayer(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Paint());

    // تحويل نقاط الويدجت -> إحداثيات الصورة الحقيقية
    // الصورة مرسومة داخل canvas ضمن _imageRectInCanvas (BoxFit.contain)
    // نعمل mapping من [rect] إلى [w,h]
    final rect = _imageRectInCanvas;
    final double sx = w / rect.width;
    final double sy = h / rect.height;

    Offset toImage(Offset p) {
      final dx = ((p.dx - rect.left) * sx).clamp(0.0, w - 1.0);
      final dy = ((p.dy - rect.top) * sy).clamp(0.0, h - 1.0);
      return Offset(dx, dy);
    }

    for (final s in _strokes) {
      if (s.points.isEmpty) continue;

      // عرض الفرشاة على الصورة = تحويل من px على الويدجت إلى px على الصورة
      final double strokeWImage = s.widthPx * sx; // تقريبًا (نستخدم sx)

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWImage
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;

      if (s.isEraser) {
        // ✅ ممحاة حقيقية
        paint
          ..blendMode = BlendMode.clear
          ..color = Colors.transparent;
      } else {
        // ✅ ماسك = أبيض
        paint
          ..blendMode = BlendMode.srcOver
          ..color = Colors.white;
      }

      final pts = s.points.map(toImage).toList();

      if (pts.length == 1) {
        canvas.drawPoints(ui.PointMode.points, pts, paint..strokeWidth = strokeWImage);
      } else {
        final path = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (int i = 1; i < pts.length; i++) {
          path.lineTo(pts[i].dx, pts[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }

    canvas.restore(); // restore layer

    final picture = recorder.endRecording();
    final outImg = await picture.toImage(w, h);
    final byteData = await outImg.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // =========================================================
  // 3) Real API: submit-job → status → result
  // =========================================================
  Future<String> _submitJobReal({
    required Uint8List imageBytes,
    required Uint8List maskPngBytes,
  }) async {
    final uri = Uri.parse("$_baseUrl/submit-job");
    final req = http.MultipartRequest("POST", uri);

    // ✅ أسماء الحقول الافتراضية (لو سيرفرك مختلف اذكرها وسأعدلها فورًا)
    req.files.add(http.MultipartFile.fromBytes(
      "image",
      imageBytes,
      filename: "image.png",
    ));
    req.files.add(http.MultipartFile.fromBytes(
      "mask",
      maskPngBytes,
      filename: "mask.png",
    ));

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception("submit-job failed HTTP ${streamed.statusCode} | $body");
    }

    final j = json.decode(body) as Map<String, dynamic>;
    final jobId = (j["jobId"] ?? j["job_id"] ?? j["id"])?.toString();
    if (jobId == null || jobId.isEmpty) {
      throw Exception("submit-job: missing jobId in response: $j");
    }
    return jobId;
  }

  Future<Map<String, dynamic>> _getStatus(String jobId) async {
    final uri = Uri.parse("$_baseUrl/status/$jobId");
    final res = await http.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("status failed HTTP ${res.statusCode} | ${res.body}");
    }
    return json.decode(res.body) as Map<String, dynamic>;
  }

  bool _isDone(Map<String, dynamic> j) {
    final s = (j["status"] ?? j["state"] ?? "").toString().toLowerCase();
    if (s.contains("done") || s.contains("success") || s.contains("completed") || s == "ok") return true;
    final finished = j["finished"];
    if (finished is bool && finished) return true;
    final progress = j["progress"];
    if (progress is num && progress >= 1) return true;
    return false;
  }

  bool _isFailed(Map<String, dynamic> j) {
    final s = (j["status"] ?? j["state"] ?? "").toString().toLowerCase();
    if (s.contains("fail") || s.contains("error")) return true;
    final ok = j["ok"];
    if (ok is bool && ok == false) return true;
    return false;
  }

  String _prettyStatus(Map<String, dynamic> j) {
    final s = j["status"] ?? j["state"] ?? "processing";
    final p = j["progress"];
    return p != null ? "$s | progress=$p" : "$s";
  }

  bool _looksLikeJson(Uint8List bytes) {
    for (final b in bytes.take(60)) {
      if (b == 0x20 || b == 0x0A || b == 0x0D || b == 0x09) continue;
      return (b == 0x7B || b == 0x5B); // { or [
    }
    return false;
  }

  Future<Uint8List> _fetchResultBytes(String jobId) async {
    final uri = Uri.parse("$_baseUrl/result/$jobId");
    final res = await http.get(uri);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("result failed HTTP ${res.statusCode} | ${res.body}");
    }

    final ct = (res.headers["content-type"] ?? "").toLowerCase();
    if (ct.contains("application/json") || _looksLikeJson(res.bodyBytes)) {
      final j = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final b64 = (j["image"] ?? j["result"] ?? j["bytes"])?.toString();
      if (b64 == null || b64.isEmpty) throw Exception("result json missing base64: $j");
      return base64Decode(b64);
    }

    return res.bodyBytes;
  }

  Future<void> _submitAndRun() async {
    if (_busy) return;
    if (_imageBytes == null || _imageUi == null) return;
    if (_strokes.isEmpty) {
      setState(() => _status = "ارسم ماسك أولًا (الماسك فارغ)");
      return;
    }

    setState(() {
      _busy = true;
      _status = "تصدير الماسك...";
      _resultBytes = null;
      _resultUi = null;
    });

    try {
      final maskPng = await _exportMaskPng();

      setState(() => _status = "إرسال job...");
      final jobId = await _submitJobReal(
        imageBytes: _imageBytes!,
        maskPngBytes: maskPng,
      );

      setState(() => _status = "تم الإرسال ✅ jobId=$jobId | Polling...");

      final start = DateTime.now();
      const timeout = Duration(seconds: 120);
      const interval = Duration(milliseconds: 900);

      while (true) {
        await Future.delayed(interval);
        final st = await _getStatus(jobId);

        if (!mounted) return;

        if (_isFailed(st)) {
          throw Exception("Job failed: $st");
        }

        if (_isDone(st)) {
          setState(() => _status = "اكتمل ✅ تحميل النتيجة...");
          final bytes = await _fetchResultBytes(jobId);

          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();

          setState(() {
            _resultBytes = bytes;
            _resultUi = frame.image;
            _status = "تم ✅ تقدر تحمّل/تحفظ النتيجة";
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ اكتملت المعالجة بنجاح")),
          );
          break;
        } else {
          setState(() => _status = "Processing... ${_prettyStatus(st)}");
        }

        if (DateTime.now().difference(start) > timeout) {
          throw Exception("Timeout after ${timeout.inSeconds}s");
        }
      }
    } catch (e) {
      setState(() => _status = "🚨 خطأ: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // =========================================================
  // 4) Download / Save / Share result
  // =========================================================
  Future<String> _saveResultToFile() async {
    if (_resultBytes == null) throw Exception("No result bytes");
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File("${dir.path}/inpaint_result_$ts.png");
    await file.writeAsBytes(_resultBytes!, flush: true);
    return file.path;
  }

  Future<void> _downloadResult() async {
    try {
      setState(() => _status = "حفظ الملف...");
      final path = await _saveResultToFile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ تم حفظ النتيجة: $path")),
      );
      setState(() => _status = "تم حفظ الملف ✅");
    } catch (e) {
      setState(() => _status = "🚨 فشل حفظ الملف: $e");
    }
  }

  Future<void> _saveToGallery() async {
    if (_resultBytes == null) return;
    try {
      setState(() => _status = "حفظ في المعرض...");
      final res = await ImageGallerySaverPlus.saveImage(
        _resultBytes!,
        quality: 100,
        name: "inpaint_${DateTime.now().millisecondsSinceEpoch}",
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ تم الحفظ في المعرض: $res")),
      );
      setState(() => _status = "تم الحفظ في المعرض ✅");
    } catch (e) {
      setState(() => _status = "🚨 فشل الحفظ في المعرض: $e");
    }
  }

  Future<void> _shareResult() async {
    if (_resultBytes == null) return;
    try {
      setState(() => _status = "تجهيز المشاركة...");
      final path = await _saveResultToFile();
      await Share.shareXFiles([XFile(path)], text: "Inpainting result");
      if (!mounted) return;
      setState(() => _status = "تم ✅");
    } catch (e) {
      setState(() => _status = "🚨 فشل المشاركة: $e");
    }
  }

  // =========================================================
  // UI helpers: عرض الصورة/النتيجة
  // =========================================================
  ui.Image? get _displayImage => _resultUi ?? _imageUi;

  @override
  Widget build(BuildContext context) {
    final img = _displayImage;
    final canSubmit = !_busy && _imageBytes != null && _imageUi != null;
    final hasResult = _resultBytes != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text("Brush Mask → Real LaMa"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _busy ? null : _loadSampleImage,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: img == null
                      ? const CircularProgressIndicator(color: Color(0xFF2EE59D))
                      : Padding(
                    padding: const EdgeInsets.all(14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: LayoutBuilder(
                        builder: (context, c) {
                          _canvasSize = Size(c.maxWidth, c.maxHeight);
                          return _BrushMaskCanvas(
                            image: img,
                            strokes: _strokes,
                            opacity: _opacity,
                            onImageRect: (r) => _imageRectInCanvas = r,
                            onPanStart: (p) => _startStroke(p),
                            onPanUpdate: (p) => _appendStroke(p),
                            onPanEnd: _endStroke,
                            isBusy: _busy,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (_busy)
                  Container(
                    color: Colors.black.withOpacity(0.55),
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF161D27),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 13),
                ),
                const SizedBox(height: 10),

                // Tools Row
                Row(
                  children: [
                    Expanded(
                      child: _ToolChip(
                        label: "Brush",
                        icon: Icons.brush,
                        selected: !_isEraser,
                        onTap: _busy ? null : () => setState(() => _isEraser = false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ToolChip(
                        label: "Eraser",
                        icon: Icons.cleaning_services,
                        selected: _isEraser,
                        onTap: _busy ? null : () => setState(() => _isEraser = true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ToolChip(
                        label: "Clear",
                        icon: Icons.delete_outline,
                        selected: false,
                        onTap: _busy ? null : _clearMask,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Sliders
                Row(
                  children: [
                    const SizedBox(width: 6),
                    const Text("Size", style: TextStyle(color: Colors.white70)),
                    Expanded(
                      child: Slider(
                        value: _brushPx,
                        min: 8,
                        max: 120,
                        onChanged: _busy ? null : (v) => setState(() => _brushPx = v),
                      ),
                    ),
                    Text("${_brushPx.toInt()}",
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(width: 6),
                    const Text("Mask α", style: TextStyle(color: Colors.white70)),
                    Expanded(
                      child: Slider(
                        value: _opacity,
                        min: 0.15,
                        max: 1.0,
                        onChanged: _busy ? null : (v) => setState(() => _opacity = v),
                      ),
                    ),
                    Text(_opacity.toStringAsFixed(2),
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),

                const SizedBox(height: 8),

                // Submit
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2EE59D),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: canSubmit ? _submitAndRun : null,
                        icon: const Icon(Icons.auto_fix_high),
                        label: const Text("Submit Job (Real)", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Download buttons appear after result
                if (hasResult) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _downloadResult,
                          icon: const Icon(Icons.download),
                          label: const Text("تحميل ملف"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saveToGallery,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text("حفظ بالمعرض"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _shareResult,
                          icon: const Icon(Icons.share_outlined),
                          label: const Text("مشاركة"),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 6),
                Text(
                  _baseUrl,
                  style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// Canvas Painter: Image (contain) + strokes overlay (brush/eraser)
// - يرسل imageRect الحقيقي داخل الويدجت للمابنج عند تصدير الماسك
// =========================================================
class _BrushMaskCanvas extends StatelessWidget {
  final ui.Image image;
  final List<_Stroke> strokes;
  final double opacity;
  final void Function(Rect imageRectInCanvas) onImageRect;

  final void Function(Offset p) onPanStart;
  final void Function(Offset p) onPanUpdate;
  final VoidCallback onPanEnd;

  final bool isBusy;

  const _BrushMaskCanvas({
    required this.image,
    required this.strokes,
    required this.opacity,
    required this.onImageRect,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);

      // BoxFit.contain rect computation
      final imgW = image.width.toDouble();
      final imgH = image.height.toDouble();
      final scale = (size.width / imgW).clamp(0.0, double.infinity);
      final scale2 = (size.height / imgH).clamp(0.0, double.infinity);
      final s = scale < scale2 ? scale : scale2;

      final drawW = imgW * s;
      final drawH = imgH * s;

      final left = (size.width - drawW) / 2;
      final top = (size.height - drawH) / 2;

      final rect = Rect.fromLTWH(left, top, drawW, drawH);
      onImageRect(rect);

      return GestureDetector(
        onPanStart: isBusy ? null : (d) => onPanStart(d.localPosition),
        onPanUpdate: isBusy ? null : (d) => onPanUpdate(d.localPosition),
        onPanEnd: isBusy ? null : (_) => onPanEnd(),
        child: CustomPaint(
          painter: _BrushMaskPainter(
            image: image,
            imageRect: rect,
            strokes: strokes,
            opacity: opacity,
          ),
          size: size,
        ),
      );
    });
  }
}

class _BrushMaskPainter extends CustomPainter {
  final ui.Image image;
  final Rect imageRect;
  final List<_Stroke> strokes;
  final double opacity;

  _BrushMaskPainter({
    required this.image,
    required this.imageRect,
    required this.strokes,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw image (contain)
    paintImage(
      canvas: canvas,
      rect: imageRect,
      image: image,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    // Overlay: strokes (with eraser via saveLayer)
    canvas.saveLayer(Offset.zero & size, Paint());

    for (final s in strokes) {
      if (s.points.isEmpty) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.widthPx
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;

      if (s.isEraser) {
        paint
          ..blendMode = BlendMode.clear
          ..color = Colors.transparent;
      } else {
        paint
          ..blendMode = BlendMode.srcOver
          ..color = Colors.red.withOpacity(opacity);
      }

      // Only draw inside imageRect visually (اختياري)
      // لكن لو رسم خارجها لا يؤثر كثيرًا، عند التصدير نعمل clamp.
      final pts = s.points;

      if (pts.length == 1) {
        canvas.drawPoints(ui.PointMode.points, pts, paint);
      } else {
        final path = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (int i = 1; i < pts.length; i++) {
          path.lineTo(pts[i].dx, pts[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrushMaskPainter old) {
    return old.image != image ||
        old.imageRect != imageRect ||
        old.opacity != opacity ||
        old.strokes.length != strokes.length;
  }
}

// =========================================================
// Models + Widgets
// =========================================================
class _Stroke {
  final bool isEraser;
  final double widthPx;
  final List<Offset> points;

  _Stroke({
    required this.isEraser,
    required this.widthPx,
    required this.points,
  });
}

class _ToolChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _ToolChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF2EE59D) : Colors.white.withOpacity(0.06);
    final fg = selected ? Colors.black : Colors.white.withOpacity(0.85);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}