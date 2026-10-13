// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutadefe/theme/app_theme.dart';

void main() {
  testWidgets('Ruta de Fe light theme renders with Material 3', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Text('Ruta de Fe')),
      ),
    );

    expect(find.text('Ruta de Fe'), findsOneWidget);
    expect(Theme.of(tester.element(find.text('Ruta de Fe'))).useMaterial3, isTrue);
  });
}
