import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutadefe/models/quiz.dart';
import 'package:rutadefe/screens/quiz_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows pastoral feedback and waits for next instead of auto-advancing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final quiz = Quiz(
      id: 'quiz-1',
      seccionId: 'seccion-1',
      titulo: 'Quiz de prueba',
      preguntas: [
        PreguntaQuiz(
          id: 'p1',
          tipo: 'multiple',
          enunciado: '¿Cuál es el primer mandamiento?',
          opciones: const ['Amar a Dios', 'Amar al dinero'],
        ),
        PreguntaQuiz(
          id: 'p2',
          tipo: 'completar',
          enunciado: 'Resume la sección',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          quiz: quiz,
          seminarioId: 'seminario-1',
          grader: ({
            required seminarioId,
            required seccionId,
            required quizId,
            required preguntaId,
            required respuestaUsuario,
          }) async => {
            'nota': 100,
            'comentario': 'Respuesta clara y fiel al material.',
            'correcta': true,
          },
        ),
      ),
    );

    await tester.tap(find.text('Amar a Dios'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.text('Puntuación: 100/100'), findsOneWidget);
    expect(find.text('Respuesta clara y fiel al material.'), findsOneWidget);
    expect(find.text('Siguiente pregunta'), findsOneWidget);
    expect(find.text('Resume la sección'), findsNothing);

    await tester.tap(find.text('Siguiente pregunta'));
    await tester.pumpAndSettle();
    expect(find.text('Resume la sección'), findsOneWidget);
  });
}
