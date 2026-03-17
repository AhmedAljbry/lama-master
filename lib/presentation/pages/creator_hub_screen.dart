/*
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/core/ui/tokens.dart';
import 'package:lama/features/studio_editor/presentation/pages/studio_editor_scope.dart';
import 'package:lama/presentation/pages/luma_ultimate_editor_page.dart';
import 'package:lama/presentation/widgets/Steal/applyStyleCpu.dart';

class MainWorkspaceScreen extends StatefulWidget {
  const MainWorkspaceScreen({super.key});

  @override
  State<MainWorkspaceScreen> createState() => _MainWorkspaceScreenState();
}

class _MainWorkspaceScreenState extends State<MainWorkspaceScreen> {
  int _currentIndex = 0;
  Locale _studioLocale = const Locale('en');

  void _switchTab(int index) {
    if (_currentIndex == index) {
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  }

  void _toggleStudioLocale() {
    setState(() {
      _studioLocale = _studioLocale.languageCode == 'ar'
          ? const Locale('en')
          : const Locale('ar');
    });
  }

  List<Widget> _buildWorkspaces(BuildContext context) {
    return [
      const LumaUltimateEditorPage(),
      Localizations.override(
        context: context,
        locale: _studioLocale,
        delegates: const [
          AppL10nDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        child: StudioEditorScope(
          child: StudioEditorScreen(
            locale: _studioLocale,
            onToggleLocale: _toggleStudioLocale,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final workspaces = _buildWorkspaces(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: workspaces,
            ),
          ),
          Positioned(
            bottom: bottomInset + 16,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTokens.surface.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppTokens.text2.withOpacity(0.15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTokens.bg.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildNavButton(
                          title: 'Luma Color',
                          icon: Icons.color_lens_rounded,
                          index: 0,
                          activeColor: AppTokens.primary,
                        ),
                        SizedBox(width: 8),
                        _buildNavButton(
                          title: 'AI Studio',
                          icon: Icons.auto_awesome,
                          index: 1,
                          activeColor: AppTokens.warning,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required String title,
    required IconData icon,
    required int index,
    required Color activeColor,
  }) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => _switchTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? activeColor.withOpacity(0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? activeColor : AppTokens.text2,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isActive
                  ? Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        title,
                        style: TextStyle(
                          color: activeColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
*/
