import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutadefe/screens/lock_ads_settings_screen.dart';
import 'package:rutadefe/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('settings screen explains lock-screen reflections', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const LockAdsSettingsScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('Mostrar reflexiones al desbloquear'), findsOneWidget);
    expect(find.text('Buscar anuncios nuevos'), findsOneWidget);
  });
}
