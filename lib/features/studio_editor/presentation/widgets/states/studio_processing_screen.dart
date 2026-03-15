import 'package:flutter/material.dart';
import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/core/ui/AppTokens.dart';

class StudioProcessingScreen extends StatelessWidget {
  const StudioProcessingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTokens.primaryGradient,
                boxShadow: AppTokens.primaryGlow(0.5),
              ),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.s32),
            Text(
              l10n.get('editor_state_processing'),
              style: AppTokens.headingM.copyWith(
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: AppTokens.s12),
            Text(
              l10n.get('apply_processing_hint'),
              style: AppTokens.bodyM.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
