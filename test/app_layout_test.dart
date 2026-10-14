import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutadefe/theme/app_layout.dart';
import 'package:rutadefe/theme/app_theme.dart';

void main() {
  testWidgets('tablet and phone breakpoints choose seminar columns', (tester) async {
    Future<int> columnsFor(Size size) async {
      late int columns;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: Builder(
            builder: (context) {
              columns = AppLayout.seminarColumns(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return columns;
    }

    expect(await columnsFor(const Size(390, 844)), 1);
    expect(await columnsFor(const Size(800, 600)), 2);
    expect(await columnsFor(const Size(1280, 800)), 3);
  });

  testWidgets('dark theme uses gold primary on a warm surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: Text('oscuro')),
      ),
    );
    final theme = Theme.of(tester.element(find.text('oscuro')));
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, AppTheme.gold);
    expect(theme.scaffoldBackgroundColor, AppTheme.darkBg);
  });

  testWidgets('light theme uses olive from the official logo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Text('claro')),
      ),
    );
    final theme = Theme.of(tester.element(find.text('claro')));
    expect(theme.colorScheme.primary, AppTheme.olive);
    expect(theme.scaffoldBackgroundColor, AppTheme.cream);
  });
}
