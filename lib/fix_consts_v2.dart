import 'dart:io';

void main() async {
  final directories = [
    r'c:\Users\MK\Downloads\Compressed\lama-master\lib\presentation',
    r'c:\Users\MK\Downloads\Compressed\lama-master\lib\features',
  ];

  for (final dirPath in directories) {
    final dir = Directory(dirPath);
    if (!await dir.exists()) continue;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        String content = await entity.readAsString();
        bool changed = false;

        // More robust regex to catch const calls with nested parentheses (like withOpacity)
        // We look for 'const' followed by an identifier and an opening parenthesis.
        // Then we check if 'withOpacity' or 'withValues' exists before the next semicolon or closing brace.
        
        final constRegExp = RegExp(r'const\s+[A-Z][a-zA-Z0-9_]*\(');
        
        final lines = content.split('\n');
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].contains('const ') && (lines[i].contains('withOpacity') || lines[i].contains('withValues'))) {
            lines[i] = lines[i].replaceAll('const ', '');
            changed = true;
          }
        }
        
        if (changed) {
          content = lines.join('\n');
        }

        // Catch multi-line: const TextStyle(\n color: ...withOpacity...
        // This is harder. Let's just remove 'const' globally before identifiers if they are followed by withOpacity in the same "statement".
        // Actually, simpler: search for any occurrence of 'withOpacity' and find the preceding 'const' in that statement.
        
        // Let's try to match blocks: const X( ... ) where ... contains withOpacity.
        // Since we can't easily match nested parens with simple regex, let's do a more targeted search.
        
        final patterns = [
          'const TextStyle',
          'const EdgeInsets',
          'const BoxShadow',
          'const BoxBorder',
          'const Border',
          'const RoundedRectangleBorder',
          'const Text',
          'const Icon',
          'const Container', // unlikely but possible
          'const DecoratedBox',
          'const Padding',
          'const Center',
          'const Positioned',
          'const SizedBox',
        ];

        for (final p in patterns) {
          if (content.contains(p) && (content.contains('withOpacity') || content.contains('withValues'))) {
            // We'll replace all 'const Name(' with 'Name(' IF the following text (until ;) contains withOpacity.
            // This is still tricky. Let's just remove 'const' from EVERY occurrence of these patterns if withOpacity is present in the file.
            // That's a bit heavy but safe.
            content = content.replaceAll(p, p.replaceFirst('const ', ''));
            changed = true;
          }
        }

        if (changed) {
          await entity.writeAsString(content);
          print('Fixed \${entity.path}');
        }
      }
    }
  }
}
