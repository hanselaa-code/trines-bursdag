import 'package:flutter_test/flutter_test.dart';
import 'package:trines_bursdag/main.dart';

void main() {
  testWidgets('App starts without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const TrinesBursdagApp());
    // Very basic test to ensure main screen loads
    expect(find.text('Trines Bursdag!'), findsWidgets);
  });
}
