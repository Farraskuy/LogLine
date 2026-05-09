import 'package:flutter_test/flutter_test.dart';

import 'package:logline/main.dart';

void main() {
  testWidgets('LogLine boilerplate renders', (WidgetTester tester) async {
    await tester.pumpWidget(const LogLineApp());

    expect(find.text('LogLine boilerplate is ready.'), findsOneWidget);
  });
}
