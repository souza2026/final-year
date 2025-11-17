
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:myapp/src/screens/login_screen.dart';
import 'package:myapp/src/screens/map_screen.dart';
import 'package:myapp/src/services/auth_service.dart';
import 'package:myapp/src/screens/register_screen.dart';
import 'package:provider/provider.dart';
import 'firebase_test_helpers.dart';

void main() {
  setUp(() async {
    await mockAuth.signOut();
  });

  testWidgets('Renders LoginScreen and navigates to RegisterScreen', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: MyApp(auth: mockAuth, firestore: fakeFirestore)));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.tap(find.text("Don't have an account? Sign Up"));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);

  });

  testWidgets('Auth Flow: user can sign up, log out, and then log in', (WidgetTester tester) async {

    await tester.pumpWidget(MaterialApp(home: MyApp(auth: mockAuth, firestore: fakeFirestore)));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);

    // Navigate to Register screen
    await tester.tap(find.text("Don't have an account? Sign Up"));
    await tester.pumpAndSettle();

    // Register
    await tester.enterText(find.byKey(const Key('register_username')), 'testuser');
    await tester.enterText(find.byKey(const Key('register_email')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('register_password')), 'password');
    await tester.enterText(find.byKey(const Key('confirm_password')), 'password');
    await tester.tap(find.byKey(const Key('register_button')));
    await tester.pumpAndSettle();

    // Verify navigation to map screen
    expect(find.byType(MapScreen), findsOneWidget);

    // Log out
    final authService = Provider.of<AuthService>(tester.element(find.byType(MapScreen)), listen: false);
    await authService.signOut();
    await tester.pumpAndSettle();

    // Verify navigation back to LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);

    // Log back in
    await tester.enterText(find.byKey(const Key('login_email')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('login_password')), 'password');
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    // Verify navigation to map screen again
    expect(find.byType(MapScreen), findsOneWidget);
  });

  testWidgets('Logged in user is redirected to map screen', (WidgetTester tester) async {
    // Log in the user first
    await mockAuth.signInWithEmailAndPassword(email: 'test@example.com', password: 'password');

    await tester.pumpWidget(MaterialApp(home: MyApp(auth: mockAuth, firestore: fakeFirestore)));
    await tester.pumpAndSettle();

    // Verify that the user is redirected to the map screen
    expect(find.byType(MapScreen), findsOneWidget);
  });
}
