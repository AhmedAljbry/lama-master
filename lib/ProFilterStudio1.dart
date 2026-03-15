import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img_lib;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// --- تعريف القوالب ---
enum AppPreset { original, dreamy, motion, vintage, noir, neon, cyber, warm }

class PresetConfig {
  final String name;
  final IconData icon;
  final double blur;
  final double grain;
  final bool ghost;
  final bool colorPop;
  final double aura; // شدة الهالة
  final Color? auraColor;
  final double scanlines; // شدة خطوط التلفاز
  final Color? colorOverlay;

  PresetConfig({
    required this.name,
    required this.icon,
    this.blur = 0.0,
    this.grain = 0.0,
    this.ghost = false,
    this.colorPop = false,
    this.aura = 0.0,
    this.auraColor,
    this.scanlines = 0.0,
    this.colorOverlay,
  });
}



class ProFilterStudioV3 extends StatefulWidget {
  const ProFilterStudioV3({super.key});

  @override
  State<ProFilterStudioV3> createState() => _ProFilterStudioV3State();
}

class _ProFilterStudioV3State extends State<ProFilterStudioV3> {
  final GlobalKey _globalKey = GlobalKey();
  File? _imageFile;
  ui.Image? _personMask;
  bool _isProcessing = false;
  bool _isSaving = false;

  // --- التحكم في الواجهة ---
  int _selectedTabIndex = 0; // 0: Presets, 1: Adjust, 2: Effects, 3: Overlays

  // --- متغيرات الحالة ---
  AppPreset _selectedPreset = AppPreset.original;

  // 1. Effects
  double _currentBlur = 0.0;
  double _currentGrain = 0.0;
  double _glitchIntensity = 0.0;
  bool _ghostActive = false;
  bool _colorPopMode = false;

  // 2. New Power Features ✨
  double _auraIntensity = 0.0;     // شدة التوهج خلف الشخص
  Color _auraColor = Colors.purpleAccent; // لون التوهج
  double _scanlineIntensity = 0.0; // خطوط التلفاز
  bool _replaceBackground = false; // استبدال الخلفية

  // 3. Adjustments
  double _contrast = 1.0;
  double _saturation = 1.0;
  Color? _currentColor;

  // 4. Overlays
  bool _showDateStamp = false;
  bool _cinemaMode = false;
  bool _polaroidFrame = false;
  int _lightLeakIndex = 0;
  double _vignetteIntensity = 0.0;

  final _segmenter = SelfieSegmenter(mode: SegmenterMode.single);

  // --- القوالب الجاهزة (محدثة) ---
  final Map<AppPreset, PresetConfig> _presets = {
    AppPreset.original: PresetConfig(name: "Normal", icon: Icons.block),
    AppPreset.dreamy: PresetConfig(name: "Dreamy", icon: Icons.cloud, blur: 5.0, grain: 0.1, colorOverlay: Colors.purple.withOpacity(0.1)),
    AppPreset.motion: PresetConfig(name: "Motion", icon: Icons.blur_linear, blur: 2.0, ghost: true, grain: 0.15),
    AppPreset.vintage: PresetConfig(name: "Vintage", icon: Icons.camera_roll, blur: 0.0, grain: 0.4, scanlines: 0.3, colorOverlay: Colors.orange.withOpacity(0.1)),
    AppPreset.noir: PresetConfig(name: "Noir", icon: Icons.movie_filter, blur: 10.0, grain: 0.45, colorPop: true),
    AppPreset.neon: PresetConfig(name: "Neon", icon: Icons.light_mode, blur: 15.0, aura: 0.8, auraColor: Colors.pinkAccent, colorOverlay: Colors.blue.withOpacity(0.2)),
    AppPreset.cyber: PresetConfig(name: "Cyber", icon: Icons.electrical_services, grain: 0.2, scanlines: 0.5, aura: 0.5, auraColor: Colors.cyanAccent),
    AppPreset.warm: PresetConfig(name: "Sunset", icon: Icons.wb_sunny, blur: 5.0, colorOverlay: Colors.redAccent.withOpacity(0.1)),
  };

  void _applyPreset(AppPreset preset) {
    final config = _presets[preset]!;
    setState(() {
      _selectedPreset = preset;
      _currentBlur = config.blur;
      _currentGrain = config.grain;
      _ghostActive = config.ghost;
      _colorPopMode = config.colorPop;
      _currentColor = config.colorOverlay;
      _auraIntensity = config.aura;
      _scanlineIntensity = config.scanlines;
      if (config.auraColor != null) _auraColor = config.auraColor!;

      // Reset others
      _contrast = 1.0;
      _saturation = 1.0;
      _glitchIntensity = (preset == AppPreset.cyber) ? 2.0 : 0.0;
      _vignetteIntensity = 0.0;
      _replaceBackground = false;
      _showDateStamp = false; _cinemaMode = false; _polaroidFrame = false;
      _lightLeakIndex = 0;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _isProcessing = true;
        _applyPreset(AppPreset.original);
      });
      _generateMask();
    }
  }

  Future<void> _generateMask() async {
    if (_imageFile == null) return;
    try {
      final inputImage = InputImage.fromFilePath(_imageFile!.path);
      final mask = await _segmenter.processImage(inputImage);
      if (mask == null) { setState(() => _isProcessing = false); return; }

      final originalBytes = await _imageFile!.readAsBytes();
      final decoded = img_lib.decodeImage(originalBytes);
      if (decoded == null) return;

      final maskPixels = Uint8List(decoded.width * decoded.height * 4);
      for (int i = 0; i < mask.confidences.length; i++) {
        final double confidence = mask.confidences[i];
        final int alpha = (confidence * 255).toInt();
        maskPixels[i * 4] = 255; maskPixels[i * 4 + 1] = 255; maskPixels[i * 4 + 2] = 255; maskPixels[i * 4 + 3] = alpha;
      }

      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(maskPixels, mask.width, mask.height, ui.PixelFormat.rgba8888, completer.complete);
      final uiMask = await completer.future;

      setState(() {
        _personMask = uiMask;
        _isProcessing = false;
        _applyPreset(AppPreset.dreamy);
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveImage() async {
    if (_imageFile == null) return;
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      var status = await Permission.storage.request();
      if (status.isDenied) await Permission.photos.request();

      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final result = await ImageGallerySaverPlus.saveImage(byteData.buffer.asUint8List(), quality: 100, name: "pro_v3_${DateTime.now().millisecondsSinceEpoch}");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['isSuccess'] ? "Saved to Gallery! 🚀" : "Save Failed"), backgroundColor: result['isSuccess'] ? Colors.green : Colors.red));
      }
    } catch (e) { debugPrint("Save Error: $e"); }
    finally { setState(() => _isSaving = false); }
  }

  List<double> _calculateColorMatrix() {
    double t = (1.0 - _contrast) / 2.0 * 255.0;
    double sr = (1 - _saturation) * 0.3086;
    double sg = (1 - _saturation) * 0.6094;
    double sb = (1 - _saturation) * 0.0820;
    return [
      _contrast + sr, sg, sb, 0, t,
      sr, _contrast + sg, sb, 0, t,
      sr, sg, _contrast + sb, 0, t,
      0, 0, 0, 1, 0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // 1. Canvas
          Positioned.fill(
            child: _imageFile == null
                ? _buildEmptyState()
                : Center(child: RepaintBoundary(key: _globalKey, child: _buildArtisticCanvas())),
          ),

          // 2. Header
          Positioned(
            top: 50, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(backgroundColor: Colors.black45, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _imageFile = null))),
                if (_imageFile != null)
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveImage,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                    child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("SAVE", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
              ],
            ),
          ),

          if (_isProcessing) Container(color: Colors.black87, child: const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))),

          // 3. Bottom Controls
          if (_imageFile != null && !_isProcessing) _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: GestureDetector(onTap: _pickImage, child: Container(padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)), child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_photo_alternate, size: 50, color: Colors.white54), SizedBox(height: 10), Text("Open Gallery", style: TextStyle(color: Colors.white54))]))));
  }

  // --- 🔥 The Visual Engine V3 ---
  Widget _buildArtisticCanvas() {
    return Container(
      padding: _polaroidFrame ? const EdgeInsets.fromLTRB(20, 20, 20, 80) : EdgeInsets.zero,
      color: _polaroidFrame ? const Color(0xFFF0F0F0) : Colors.transparent,
      child: ClipRect(
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix(_calculateColorMatrix()),
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.loose,
            children: [
              // A. الخلفية (Background)
              if (_replaceBackground)
                Positioned.fill(child: Container(color: Colors.black)) // خلفية سوداء للعزل
              else
                ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: _currentBlur, sigmaY: _currentBlur),
                  child: ColorFiltered(
                    colorFilter: _colorPopMode
                        ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                        : ColorFilter.mode(_currentColor ?? Colors.transparent, BlendMode.srcOver),
                    child: _glitchIntensity > 0 ? _buildGlitchStack(isBackground: true) : Image.file(_imageFile!, fit: BoxFit.contain),
                  ),
                ),

              // B. هالة النيون (Neon Aura) - NEW ✨
              if (_auraIntensity > 0 && _personMask != null)
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 20 * _auraIntensity, sigmaY: 20 * _auraIntensity),
                    child: ShaderMask(
                      shaderCallback: (rect) => ImageShader(_personMask!, TileMode.clamp, TileMode.clamp, Matrix4.identity().scaled(rect.width/_personMask!.width, rect.height/_personMask!.height).storage),
                      blendMode: BlendMode.src,
                      child: Container(color: _auraColor.withOpacity(_auraIntensity)), // لون الهالة
                    ),
                  ),
                ),

              // C. الشبح (Ghost)
              if (_ghostActive && _personMask != null)
                Positioned.fill(child: Transform.translate(offset: const Offset(30, 0), child: Transform.scale(scale: 1.1, child: Opacity(opacity: 0.5, child: ShaderMask(shaderCallback: (rect) => ImageShader(_personMask!, TileMode.clamp, TileMode.clamp, Matrix4.identity().scaled(rect.width/_personMask!.width, rect.height/_personMask!.height).storage), blendMode: BlendMode.dstIn, child: Image.file(_imageFile!, fit: BoxFit.contain)))))),

              // D. الشخص (Foreground)
              if (_personMask != null)
                ShaderMask(
                  shaderCallback: (rect) => ImageShader(_personMask!, TileMode.clamp, TileMode.clamp, Matrix4.identity().scaled(rect.width/_personMask!.width, rect.height/_personMask!.height).storage),
                  blendMode: BlendMode.dstIn,
                  child: _glitchIntensity > 0 ? _buildGlitchStack(isBackground: false) : Image.file(_imageFile!, fit: BoxFit.contain),
                ),

              // E. خطوط التلفاز (Scanlines) - NEW ✨
              if (_scanlineIntensity > 0)
                Positioned.fill(child: CustomPaint(painter: ScanlinePainter(intensity: _scanlineIntensity))),

              // F. تسرب الضوء
              if (_lightLeakIndex != 0)
                Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: _lightLeakIndex == 1 ? [Colors.orange.withOpacity(0.4), Colors.transparent] : [Colors.blue.withOpacity(0.4), Colors.transparent], begin: _lightLeakIndex == 1 ? Alignment.centerLeft : Alignment.topCenter, end: Alignment.center)))),

              // G. فينيت
              if (_vignetteIntensity > 0)
                Positioned.fill(child: Container(decoration: BoxDecoration(gradient: RadialGradient(colors: [Colors.transparent, Colors.black.withOpacity(_vignetteIntensity)], stops: const [0.6, 1.0])))),

              // H. التحبيب (Grain)
              if (_currentGrain > 0)
                Positioned.fill(child: CustomPaint(painter: AdvancedGrainPainter(intensity: _currentGrain), child: Container())),

              // I. وضع السينما
              if (_cinemaMode) ...[
                Positioned(top: 0, left: 0, right: 0, height: 40, child: Container(color: Colors.black)),
                Positioned(bottom: 0, left: 0, right: 0, height: 40, child: Container(color: Colors.black)),
              ],

              // J. التاريخ
              if (_showDateStamp)
                Positioned(
                  bottom: _cinemaMode ? 50 : 20, right: 20,
                  child: Text("'98  1  24", style: TextStyle(color: const Color(0xFFFF8C00), fontFamily: Platform.isIOS ? "Courier" : "Monospace", fontWeight: FontWeight.bold, fontSize: 16, shadows: const [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1))])),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlitchStack({required bool isBackground}) {
    double offset = _glitchIntensity * 5.0;
    return Stack(
      children: [
        Transform.translate(offset: Offset(-offset, 0), child: ColorFiltered(colorFilter: const ColorFilter.mode(Colors.red, BlendMode.modulate), child: Image.file(_imageFile!, fit: BoxFit.contain))),
        Transform.translate(offset: Offset(offset, 0), child: ColorFiltered(colorFilter: const ColorFilter.mode(Colors.blue, BlendMode.modulate), child: Image.file(_imageFile!, fit: BoxFit.contain))),
        Image.file(_imageFile!, fit: BoxFit.contain),
      ],
    );
  }

  // --- لوحة التحكم ---
  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.only(top: 15, bottom: 25),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.95), Colors.black.withOpacity(0.8), Colors.transparent]),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  _buildTabItem("Presets", Icons.auto_awesome_mosaic, 0),
                  _buildTabItem("Adjust", Icons.tune, 1),
                  _buildTabItem("Effects", Icons.auto_fix_high, 2),
                  _buildTabItem("Overlays", Icons.layers, 3),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // Tab Content
            SizedBox(
              height: 130,
              child: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  // Tab 0: Presets
                  ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: _presets.keys.map((p) => _buildPresetItem(p)).toList(),
                  ),

                  // Tab 1: Adjust
                  Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _buildSlider("Contrast", _contrast, 0.5, 1.5, (v) => setState(() => _contrast = v)),
                    _buildSlider("Saturation", _saturation, 0.0, 2.0, (v) => setState(() => _saturation = v)),
                    _buildSwitchRow("Remove BG", _replaceBackground, (v) => setState(() => _replaceBackground = v)),
                  ]),

                  // Tab 2: Effects (Expanded)
                  ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
                    _buildSlider("Blur", _currentBlur, 0, 20, (v) => setState(() => _currentBlur = v)),
                    _buildSlider("Aura", _auraIntensity, 0, 1.0, (v) => setState(() => _auraIntensity = v)),
                    if(_auraIntensity > 0)
                      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [Colors.purpleAccent, Colors.blueAccent, Colors.greenAccent, Colors.redAccent, Colors.white].map((c) => GestureDetector(onTap: () => setState(()=>_auraColor=c), child: Container(margin: const EdgeInsets.all(4), width: 20, height: 20, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1))))).toList())),
                    _buildSlider("Grain", _currentGrain, 0, 0.5, (v) => setState(() => _currentGrain = v)),
                    _buildSlider("Scanlines", _scanlineIntensity, 0, 0.8, (v) => setState(() => _scanlineIntensity = v)),
                    _buildSlider("Glitch", _glitchIntensity, 0, 5.0, (v) => setState(() => _glitchIntensity = v)),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _buildToggleBtn("Ghost", _ghostActive, () => setState(() => _ghostActive = !_ghostActive)),
                      _buildToggleBtn("Color Pop", _colorPopMode, () => setState(() => _colorPopMode = !_colorPopMode)),
                    ])
                  ]),

                  // Tab 3: Overlays
                  ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
                    _buildSwitchRow("Date Stamp", _showDateStamp, (v) => setState(() => _showDateStamp = v)),
                    _buildSwitchRow("Cinema Bar", _cinemaMode, (v) => setState(() => _cinemaMode = v)),
                    _buildSwitchRow("Polaroid", _polaroidFrame, (v) => setState(() => _polaroidFrame = v)),
                    _buildSlider("Vignette", _vignetteIntensity, 0, 0.8, (v) => setState(() => _vignetteIntensity = v)),
                    const SizedBox(height: 10),
                    const Text("Light Leaks:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 5),
                    Row(children: [_buildLeakBtn("None", 0), _buildLeakBtn("Warm", 1), _buildLeakBtn("Cool", 2)]),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _buildTabItem(String title, IconData icon, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.white10, borderRadius: BorderRadius.circular(30)),
        child: Row(children: [Icon(icon, color: isSelected ? Colors.black : Colors.white, size: 18), const SizedBox(width: 5), Text(title, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Widget _buildPresetItem(AppPreset preset) {
    bool isSelected = _selectedPreset == preset;
    final config = _presets[preset]!;
    return GestureDetector(
      onTap: () => _applyPreset(preset),
      child: Container(
        width: 70, margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.white10, borderRadius: BorderRadius.circular(12), border: isSelected ? Border.all(color: Colors.purpleAccent, width: 2) : null),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(config.icon, color: isSelected ? Colors.black : Colors.white70, size: 28), const SizedBox(height: 5), Text(config.name, style: TextStyle(color: isSelected ? Colors.black : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, Function(double) onChanged) {
    return Row(children: [
      SizedBox(width: 60, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11))),
      Expanded(child: Slider(value: value, min: min, max: max, activeColor: Colors.purpleAccent, inactiveColor: Colors.white12, onChanged: onChanged)),
    ]);
  }

  Widget _buildSwitchRow(String label, bool val, Function(bool) onChanged) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.white)), Switch(value: val, activeColor: Colors.purpleAccent, onChanged: onChanged)]);
  }

  Widget _buildToggleBtn(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isActive ? Colors.purpleAccent : Colors.white10, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontSize: 12)),
      ),
    );
  }

  Widget _buildLeakBtn(String label, int index) {
    bool isSelected = _lightLeakIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _lightLeakIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: isSelected ? Colors.purpleAccent : Colors.white10, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
    );
  }
}

// --- Painters ---

class AdvancedGrainPainter extends CustomPainter {
  final double intensity;
  AdvancedGrainPainter({required this.intensity});
  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;
    final random = Random();
    final paint = Paint();
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..blendMode = BlendMode.overlay);
    int density = (size.width * size.height * 0.02 * intensity).toInt();
    List<Offset> whitePoints = [], blackPoints = [];
    for (int i = 0; i < density; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      if (random.nextBool()) whitePoints.add(Offset(x, y)); else blackPoints.add(Offset(x, y));
    }
    paint.color = Colors.white.withOpacity(0.5); paint.strokeWidth = 1.5; canvas.drawPoints(ui.PointMode.points, whitePoints, paint);
    paint.color = Colors.black.withOpacity(0.5); canvas.drawPoints(ui.PointMode.points, blackPoints, paint);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant AdvancedGrainPainter oldDelegate) => oldDelegate.intensity != intensity;
}

// راسم خطوط التلفاز
class ScanlinePainter extends CustomPainter {
  final double intensity;
  ScanlinePainter({required this.intensity});
  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0;
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..blendMode = BlendMode.overlay);
    for (double y = 0; y < size.height; y += 4) {
      paint.color = Colors.black.withOpacity(intensity * 0.5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant ScanlinePainter oldDelegate) => oldDelegate.intensity != intensity;
}