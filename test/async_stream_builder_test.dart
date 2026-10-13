import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutadefe/widgets/async_stream_builder.dart';

void main() {
  testWidgets('shows a retry action when a stream never returns data', (tester) async {
    var attempts = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsyncStreamBuilder<List<int>>(
            streamFactory: () {
              attempts++;
              return const Stream<List<int>>.empty();
            },
            loadingMessage: 'Cargando prueba...',
            builder: (context, values) => Text('$values'),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Cargando prueba...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 12));
    expect(find.text('No se pudo conectar con los datos'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(attempts, 2);
    expect(find.text('Cargando prueba...'), findsOneWidget);
  });

  testWidgets('shows a recoverable state when a future fails', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsyncFutureBuilder<int>(
            futureFactory: () => Future<int>.error(StateError('offline')),
            builder: (context, value) => Text('$value'),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('No se pudo conectar con los datos'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}