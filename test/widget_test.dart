import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:myapp/src/screens/onboarding_screen.dart';
import 'package:myapp/src/theme/theme.dart';
import 'package:provider/provider.dart';

import 'firebase_test_helpers.dart';

void main() {
  setUp(() async {
    await mockAuth.signOut();
  });

  testWidgets('Renders OnboardingScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: MyApp(auth: mockAuth, firestore: fakeFirestore),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
