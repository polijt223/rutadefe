import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutadefe/screens/auth_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the three onboarding screens before login', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: AuthWrapper()));
    await tester.pump();
    await tester.pump();

    expect(find.text('Bienvenido a Ruta de Fe'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsNothing);
  });
}
