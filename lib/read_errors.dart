import 'dart:io';
import 'dart:convert';

void main() {
  final file = File('analyze_results.txt');
  if (!file.existsSync()) {
    print('analyze_results.txt not found');
    return;
  }
  
  final bytes = file.readAsBytesSync();
  // Simple UTF-16LE decoding for this specific case
  final content = String.fromCharCodes(
    Iterable.generate(bytes.length ~/ 2, (i) => bytes[i * 2] | (bytes[i * 2 + 1] << 8))
  );

  content.split('\n').where((l) => l.contains('error •')).forEach(print);
}
