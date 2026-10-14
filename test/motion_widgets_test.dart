import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutadefe/widgets/animated_indexed_stack.dart';
import 'package:rutadefe/widgets/living_icon.dart';
import 'package:rutadefe/widgets/press_scale.dart';

void main() {
  testWidgets('press scale invokes onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PressScale(
          onTap: () => taps++,
          child: const Text('pulse'),
        ),
      ),
    );
    await tester.tap(find.text('pulse'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('animated stack keeps offstage pages and shows the selected one', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AnimatedIndexedStack(
          index: 1,
          children: [
            Text('inicio'),
            Text('seminarios'),
            Text('perfil'),
          ],
        ),
      ),
    );
    expect(find.text('seminarios'), findsOneWidget);
  });

  testWidgets('living icon draws the requested glyph', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LivingIcon(icon: Icons.home, active: true),
      ),
    );
    expect(find.byIcon(Icons.home), findsOneWidget);
  });
}
