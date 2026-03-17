import 'dart:io';

void main() async {
  final directories = [
    r'c:\Users\MK\Downloads\Compressed\lama-master\lib\presentation\widgets\filter_studio',
    r'c:\Users\MK\Downloads\Compressed\lama-master\lib\presentation\pages',
    r'c:\Users\MK\Downloads\Compressed\lama-master\lib\presentation\widgets'
  ];

  for (final dirPath in directories) {
    final dir = Directory(dirPath);
    if (!await dir.exists()) continue;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        String content = await entity.readAsString();
        bool changed = false;

        if (content.contains('AppTokens.bgOf(context)')) {
          content = content.replaceAll('AppTokens.bgOf(context)', 'AppTokens.bg');
          changed = true;
        }
        
        if (content.contains('backgroundColor: AppTokens.bgOf(context)')) {
          content = content.replaceAll('backgroundColor: AppTokens.bgOf(context)', 'backgroundColor: AppTokens.bg');
          changed = true;
        }

        // Fix "const _StudioHudCard(...)" containing "(AppTokens.text2.withOpacity(0.7))" inside its definition?
        // Wait, the error is inside `_StudioHudCard` definition: `const TextStyle(color: (AppTokens.text2.withOpacity(0.7)))`.
        // We can just use string replacement: `const TextStyle(\n                  color: (AppTokens.text2.withOpacity(0.7)),`
        // or regex. Let's replacing `const TextStyle` with `TextStyle` if it contains `withOpacity`.
        
        final regExp = RegExp(r'const\s+TextStyle\([^)]*withOpacity[^)]*\)', multiLine: true, dotAll: true);
        if (regExp.hasMatch(content)) {
          content = content.replaceAllMapped(regExp, (match) {
            return match.group(0)!.replaceFirst('const TextStyle', 'TextStyle');
          });
          changed = true;
        }
        
        final regExpText = RegExp(r'const\s+Text\([^;]*?style:\s*TextStyle\([^)]*withOpacity[^)]*\)[^;]*?\)', multiLine: true, dotAll: true);
        if (regExpText.hasMatch(content)) {
          content = content.replaceAllMapped(regExpText, (match) {
            return match.group(0)!.replaceFirst('const Text', 'Text');
          });
          changed = true;
        }

        // Some specific replacements for the exact errors
        if (content.contains('const TextStyle(\n                  color: (AppTokens.text2.withOpacity(0.7))')) {
          content = content.replaceAll(
            'const TextStyle(\n                  color: (AppTokens.text2.withOpacity(0.7))',
            'TextStyle(\n                  color: (AppTokens.text2.withOpacity(0.7))'
          );
          changed = true;
        }
        
        if (content.contains('const TextStyle(color: (AppTokens.text2.withOpacity(0.7))')) {
          content = content.replaceAll(
            'const TextStyle(color: (AppTokens.text2.withOpacity(0.7))',
            'TextStyle(color: (AppTokens.text2.withOpacity(0.7))'
          );
          changed = true;
        }

        if (changed) {
          await entity.writeAsString(content);
          print('Fixed \${entity.path}');
        }
      }
    }
  }
}
