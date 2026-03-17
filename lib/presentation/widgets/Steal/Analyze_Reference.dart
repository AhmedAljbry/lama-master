import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:lama/core/ui/tokens.dart';
// ⚠️ تأكد من استيراد ملف التوكنز
// import 'tokens.dart';

class MaskEditorScreen extends StatefulWidget {
  final String imagePath;
  const MaskEditorScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<MaskEditorScreen> createState() => _MaskEditorScreenState();
}

class _MaskEditorScreenState extends State<MaskEditorScreen> {
  List<DrawnPath> paths = [];
  double strokeWidth = 30.0;
  bool isEraser = false; // الممحاة
  bool isPanMode = false; // التبديل بين الرسم والتحريك (Zoom/Pan)

  final GlobalKey _imageKey = GlobalKey();
  Offset? _currentCursorPosition;

  // ==========================================
  // منطق الرسم
  // ==========================================
  void _onPanStart(DragStartDetails details) {
    if (isPanMode) return; // لا ترسم إذا كنا في وضع التحريك

    RenderBox box = _imageKey.currentContext!.findRenderObject() as RenderBox;
    Offset point = box.globalToLocal(details.globalPosition);

    setState(() {
      _currentCursorPosition = details.localPosition;
      paths.add(
          DrawnPath(
            path: Path()..moveTo(point.dx, point.dy),
            isEraser: isEraser,
            width: strokeWidth,
          )
      );
    });
    HapticFeedback.lightImpact();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (isPanMode) return;

    RenderBox box = _imageKey.currentContext!.findRenderObject() as RenderBox;
    Offset point = box.globalToLocal(details.globalPosition);

    setState(() {
      _currentCursorPosition = details.localPosition;
      paths.last.path.lineTo(point.dx, point.dy);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (isPanMode) return;

    setState(() {
      _currentCursorPosition = null;
      if (paths.isNotEmpty) paths.last.isFinished = true;
    });
  }

  // ==========================================
  // 🚀 تصدير قناع (Mask) عالي الجودة للذكاء الاصطناعي
  // ==========================================
  Future<void> _saveHighQualityMask() async {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("جاري معالجة القناع الدقيق..."), backgroundColor: AppTokens.surface),
    );

    try {
      // 1. الحصول على أبعاد مساحة الصورة بالضبط
      RenderBox box = _imageKey.currentContext!.findRenderObject() as RenderBox;
      Size size = box.size;

      // 2. إنشاء لوحة رسم افتراضية (Canvas) مخفية
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

      // 3. جعل الخلفية سوداء بالكامل (مطلب أساسي للذكاء الاصطناعي)
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.black);

      // 4. رسم الخطوط باللون الأبيض
      for (var p in paths) {
        Paint paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = p.width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        if (p.isEraser) {
          // الممحاة ترسم بالأسود لتمسح الأبيض
          paint.color = Colors.black;
          paint.blendMode = BlendMode.srcOver;
        } else {
          paint.color = Colors.white;
        }
        canvas.drawPath(p.path, paint);
      }

      // 5. تحويل اللوحة إلى صورة PNG عالية الدقة
      final picture = recorder.endRecording();
      final img = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List maskBytes = byteData!.buffer.asUint8List();

      // 6. إرجاع القناع إلى الشاشة السابقة
      if (mounted) Navigator.pop(context, maskBytes);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في استخراج القناع: $e'), backgroundColor: AppTokens.danger),
        );
      }
    }
  }

  // ==========================================
  // واجهة المستخدم (UI)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        title: Text('التحديد الدقيق (Masking)', style: TextStyle(color: AppTokens.text, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: AppTokens.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTokens.text),
        actions: [
          IconButton(
            icon: Icon(Icons.check_circle_rounded, color: AppTokens.primary, size: 28),
            onPressed: paths.isEmpty ? null : _saveHighQualityMask,
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // 1. مساحة العرض التفاعلية
          InteractiveViewer(
            panEnabled: isPanMode, // تفعيل التحريك فقط إذا كان الزر مضغوطاً
            scaleEnabled: isPanMode, // تفعيل التكبير
            minScale: 1.0,
            maxScale: 5.0,
            child: Center(
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // الصورة الأصلية
                    Image.file(
                      File(widget.imagePath),
                      key: _imageKey, // المفتاح هنا لأخذ الأبعاد الدقيقة
                      fit: BoxFit.contain,
                    ),

                    // طبقة الرسم الشفافة فوق الصورة
                    Positioned.fill(
                      child: CustomPaint(
                        painter: MaskUIPainter(paths: paths),
                      ),
                    ),

                    // مؤشر الفرشاة أثناء الرسم
                    if (_currentCursorPosition != null && !isPanMode)
                      Positioned(
                        left: _currentCursorPosition!.dx - (strokeWidth / 2),
                        top: _currentCursorPosition!.dy - (strokeWidth / 2),
                        child: Container(
                          width: strokeWidth,
                          height: strokeWidth,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTokens.text, width: 1.5),
                            color: isEraser
                                ? Colors.black.withOpacity(0.5)
                                : AppTokens.warning.withOpacity(0.4),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 2. كبسولة أدوات التحكم السفلية (Glassmorphism)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.r24),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: EdgeInsets.symmetric(horizontal: AppTokens.s16, vertical: AppTokens.s8),
                    decoration: BoxDecoration(
                      color: AppTokens.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(AppTokens.r24),
                      border: Border.all(color: AppTokens.text2.withOpacity(0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // شريط حجم الفرشاة
                        Row(
                          children: [
                            Icon(Icons.lens, color: AppTokens.text2, size: 14),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: AppTokens.primary,
                                  thumbColor: AppTokens.primary,
                                  trackHeight: 2.0,
                                ),
                                child: Slider(
                                  value: strokeWidth,
                                  min: 5.0,
                                  max: 80.0,
                                  onChanged: (val) => setState(() => strokeWidth = val),
                                ),
                              ),
                            ),
                            Icon(Icons.lens, color: AppTokens.text2, size: 24),
                          ],
                        ),
                        // أزرار الأدوات
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // زر الفرشاة
                            _buildToolBtn(
                              icon: Icons.brush_rounded,
                              label: "رسم",
                              isActive: !isEraser && !isPanMode,
                              activeColor: AppTokens.warning,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() { isEraser = false; isPanMode = false; });
                              },
                            ),
                            // زر الممحاة
                            _buildToolBtn(
                              icon: Icons.cleaning_services_rounded,
                              label: "مسح",
                              isActive: isEraser && !isPanMode,
                              activeColor: AppTokens.danger,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() { isEraser = true; isPanMode = false; });
                              },
                            ),
                            // زر التحريك والتكبير
                            _buildToolBtn(
                              icon: Icons.pan_tool_rounded,
                              label: "تحريك",
                              isActive: isPanMode,
                              activeColor: Colors.blueAccent,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => isPanMode = true);
                              },
                            ),
                            // زر مسح الكل
                            IconButton(
                              icon: Icon(Icons.delete_sweep_rounded, color: AppTokens.text2),
                              onPressed: () {
                                HapticFeedback.heavyImpact();
                                setState(() => paths.clear());
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildToolBtn({required IconData icon, required String label, required bool isActive, required Color activeColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.r16),
          border: Border.all(color: isActive ? activeColor : Colors.transparent),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? activeColor : AppTokens.text2, size: 20),
            SizedBox(height: 4),
            Text(label, style: TextStyle(color: isActive ? activeColor : AppTokens.text2, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 🎨 نماذج الرسم (Models & Painters)
// ==========================================
class DrawnPath {
  Path path;
  bool isEraser;
  double width;
  bool isFinished = false;

  DrawnPath({required this.path, required this.isEraser, required this.width});
}

// هذا الرسام يُستخدم فقط لعرض الرسم للمستخدم على الشاشة (لونه أحمر شفاف)
class MaskUIPainter extends CustomPainter {
  final List<DrawnPath> paths;

  MaskUIPainter({required this.paths});

  @override
  void paint(Canvas canvas, Size size) {
    // استخدمنا saveLayer لتمكين عمل الممحاة (BlendMode.clear) على طبقة منفصلة
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    for (var p in paths) {
      Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = p.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (p.isEraser) {
        paint.blendMode = BlendMode.clear; // يمسح الرسمة الحمراء
      } else {
        paint.color = AppTokens.warning.withOpacity(0.6); // لون التحديد المرئي للمستخدم
      }

      canvas.drawPath(p.path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}