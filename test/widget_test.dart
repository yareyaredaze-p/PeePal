import 'package:flutter_test/flutter_test.dart';
import 'package:peepal/app.dart';

void main() {
  testWidgets('PeePal app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PeePalApp());

    // Verify that splash screen is shown
    expect(find.text('PeePal'), findsOneWidget);
  });
}
