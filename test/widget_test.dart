import 'package:flutter_test/flutter_test.dart';

import 'package:logline/main.dart';

void main() {
  testWidgets('LogLine onboarding routes to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LogLineApp());

    expect(find.text('Logbook harian, lebih rapi'), findsOneWidget);

    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();

    expect(find.text('Masuk ke LogLine'), findsOneWidget);
  });
}
