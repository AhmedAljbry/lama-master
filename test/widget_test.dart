import 'package:flutter_test/flutter_test.dart';

import 'package:lama/app.dart';
import 'package:lama/core/config/app_config.dart';
import 'package:lama/core/feature_flags/feature_flags.dart';
import 'package:lama/core/i18n/t.dart';

void main() {
  testWidgets('shows the premium dashboard entry points', (tester) async {
    await tester.pumpWidget(
      const App(
        config: AppConfig(baseUrl: 'https://example.invalid'),
        flags: FeatureFlags.dev,
        lang: Lang.en,
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Welcome, Creator'), findsOneWidget);
    expect(find.text('Luma Color'), findsOneWidget);
    expect(find.text('Image Intel'), findsOneWidget);
    expect(find.text('Pro Studio'), findsOneWidget);
    expect(find.text('Magic Eraser'), findsOneWidget);
  });
}
