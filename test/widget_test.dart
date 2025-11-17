import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:myapp/src/screens/login_screen.dart';
import 'firebase_test_helpers.dart';

void main() {
  setUp(() async {
    await mockAuth.signOut();
  });

  testWidgets('Renders LoginScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyApp(
          auth: mockAuth,
          firestore: fakeFirestore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Log In'), findsOneWidget);
    expect(find.text("Don't have an account? Sign Up"), findsOneWidget);
  });
}
