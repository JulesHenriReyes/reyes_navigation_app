import 'package:flutter_test/flutter_test.dart';
import 'package:reyes_navigation_app/main.dart';

void main() {
  testWidgets('App smoke test - displays LoginScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const StudentApp());

    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
  });
}
