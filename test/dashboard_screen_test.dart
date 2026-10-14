import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutadefe/screens/dashboard_screen.dart';
import 'package:rutadefe/services/progress_service.dart';
import 'package:rutadefe/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dashboard shows greeting, streak and current-seminar empty state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: DashboardScreen(
          seminarios: const [],
          progressService: ProgressService(),
          streak: 12,
          onOpenMenu: () {},
          onOpenSeminars: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('¡Hola,'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Aún no hay seminarios'), findsOneWidget);
    expect(find.text('Seguir el camino'), findsOneWidget);
  });
}
