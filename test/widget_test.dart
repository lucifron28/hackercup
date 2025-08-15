import 'package:flutter_test/flutter_test.dart';
import 'package:jeepney_tracker/main.dart';
void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const JeepneyTrackerApp());
    // Verify that the role selection screen shows up
    expect(find.text('Choose Your Role'), findsOneWidget);
  });
}
