import 'package:flutter_test/flutter_test.dart';
import 'package:calorimate_mobile/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const CaloriMateApp());
    expect(find.text('Login Client'), findsOneWidget);
  });
}
