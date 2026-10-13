import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutadefe/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('completing onboarding marks the flag and does not open Home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(onCompleted: () => completed = true),
      ),
    );

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_done'), isTrue);
    expect(completed, isTrue);
    expect(find.text('Ruta de Fe'), findsNothing);
    expect(find.text('Continuar con Google'), findsNothing);
  });
}
