import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/ui/tokens.dart';

class FullScreenImageViewer extends StatelessWidget {
  final Uint8List imageBytes;
  const FullScreenImageViewer({Key? key, required this.imageBytes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(AppTokens.s8),
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
          ),
        ),
      ),
      body: InteractiveViewer(
        minScale: 0.8,
        maxScale: 6.0,
        child: Center(
          child: Hero(
            tag: 'studio_image',
            child: Image.memory(imageBytes, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
