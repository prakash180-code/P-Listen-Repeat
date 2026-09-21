import 'package:flutter_test/flutter_test.dart';

import 'package:listen_repeat/app.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Listen & Repeat'), findsOneWidget);
  });
}
