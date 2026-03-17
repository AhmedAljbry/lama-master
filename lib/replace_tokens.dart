import 'dart:io';

void main() async {
  final filesToModify = [
    r'c:\Users\MK\Downloads\Compressed\lama-master\lib\presentation\widgets\filter_studio\filter_studio_shell.dart',
    r'c:\Users\MK\Downloads\Compressed\lama-master\lib\presentation\pages\pro_filter_studio_page.dart',
    r'c:\Users\MK\Downloads\Compressed\lama-master\lib\presentation\pages\ProcessingOverlay_ProFilterStudioPage.dart',
    r'c:\Users\MK\Downloads\Compressed\lama-master\lib\presentation\pages\ProResultPage.dart',
    r'c:\Users\MK\Downloads\Compressed\lama-master\lib\presentation\widgets\bottom_controls.dart',
  ];

  final replacements = {
    "import 'package:lama/presentation/pages/PT.dart';": "import 'package:lama/core/ui/AppTokens.dart';\nimport 'package:lama/core/ui/app_theme.dart';",
    'PT.bg': 'AppTokens.bg',
    'PT.surface': 'AppTokens.surface',
    'PT.card': 'AppTokens.card',
    'PT.card2': 'AppTokens.card2',
    'PT.mint': 'AppTokens.primary',
    'PT.cyan': 'AppTokens.info',
    'PT.purple': 'AppTokens.accent',
    'PT.gold': 'AppTokens.warning',
    'PT.coral': 'AppTokens.danger',
    'PT.danger': 'AppTokens.danger',
    'PT.warning': 'AppTokens.warning',
    'PT.t1': 'AppTokens.text',
    'PT.t2': 'AppTokens.text2',
    'PT.t3': '(AppTokens.text2.withOpacity(0.7))',
    'PT.gradMint': 'AppTokens.primaryGradient',
    'PT.gradPurple': 'AppTokens.primaryGradient',
    'PT.gradMintV': 'AppTokens.primaryGradient',
    'PT.r8': 'AppTokens.r8',
    'PT.r12': 'AppTokens.r12',
    'PT.r16': 'AppTokens.r16',
    'PT.r20': 'AppTokens.r20',
    'PT.r24': 'AppTokens.r24',
    'PT.r32': 'AppTokens.r32',
    'PT.rFull': 'AppTokens.rFull',
    'PT.s4': 'AppTokens.s4',
    'PT.s6': 'AppTokens.s6',
    'PT.s7': 'AppTokens.s7',
    'PT.s8': 'AppTokens.s8',
    'PT.s10': 'AppTokens.s10',
    'PT.s12': 'AppTokens.s12',
    'PT.s14': 'AppTokens.s14',
    'PT.s16': 'AppTokens.s16',
    'PT.s20': 'AppTokens.s20',
    'PT.s24': 'AppTokens.s24',
    'PT.s32': 'AppTokens.s32',
    'PT.fast': 'const Duration(milliseconds: 150)',
    'PT.medium': 'const Duration(milliseconds: 280)',
    'PT.slow': 'const Duration(milliseconds: 480)',
    'PT.elevation': 'AppTokens.cardShadow',
  };

  for (final filePath in filesToModify) {
    final file = File(filePath);
    if (!await file.exists()) {
      print('File not found: \$filePath');
      continue;
    }

    String content = await file.readAsString();

    for (final entry in replacements.entries) {
      content = content.replaceAll(entry.key, entry.value);
    }

    // Regex replacement for PT.glow
    final glowRegExp = RegExp(r'PT\.glow\([^)]+\)');
    content = content.replaceAll(glowRegExp, 'AppTokens.primaryGlow(0.35)');

    await file.writeAsString(content);
    print('Updated \$filePath');
  }
}
