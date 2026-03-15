import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/features/studio_editor/presentation/pages/studio_editor_scope.dart';
import 'package:lama/features/studio_editor/presentation/pages/studio_editor_main_screen.dart';

class AiStudioPage extends StatefulWidget {
  const AiStudioPage({super.key});

  @override
  State<AiStudioPage> createState() => _AiStudioPageState();
}

class _AiStudioPageState extends State<AiStudioPage> {
  Locale _studioLocale = const Locale('en');
  bool _seededLocale = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seededLocale) {
      return;
    }

    _seededLocale = true;
    final locale = Localizations.localeOf(context);
    _studioLocale =
        locale.languageCode == 'ar' ? const Locale('ar') : const Locale('en');
  }

  void _toggleStudioLocale() {
    setState(() {
      _studioLocale = _studioLocale.languageCode == 'ar'
          ? const Locale('en')
          : const Locale('ar');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: _studioLocale,
      delegates: const [
        AppL10nDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      child: StudioEditorScope(
        child: StudioEditorMainScreen(
          locale: _studioLocale,
          onToggleLocale: _toggleStudioLocale,
        ),
      ),
    );
  }
}
