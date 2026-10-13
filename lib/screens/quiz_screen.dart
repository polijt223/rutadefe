import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../services/gemini_service.dart';
import '../services/progress_service.dart';
import '../services/streak_service.dart';
import '../widgets/celebration_dialog.dart';

class QuizScreen extends StatefulWidget {
  final Quiz quiz;
  final String seminarioId;
  final int totalSecciones;
  const QuizScreen({
    super.key,
    required this.quiz,
    required this.seminarioId,
    this.totalSecciones = 1,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _current = 0;
  int _correctas = 0;
  int _totalScore = 0;
  bool _answered = false;
  bool _grading = false;
  String? _selected;
  String? _feedback;
  int? _lastScore;
  final _textController = TextEditingController();

  Future<void> _checkAnswer(String respuesta) async {
    if (_answered || _grading) return;
    final pregunta = widget.quiz.preguntas[_current];
    setState(() {
      _grading = true;
      _selected = respuesta;
    });

    try {
      final grade = await GeminiService.corregirRespuesta(
        seminarioId: widget.seminarioId,
        seccionId: widget.quiz.seccionId,
        quizId: widget.quiz.id,
        preguntaId: pregunta.id,
        respuestaUsuario: respuesta,
      );

      if (!mounted) return;
      final score = (grade['nota'] as num).round().clamp(0, 100);
      setState(() {
        _grading = false;
        _answered = true;
        _totalScore += score;
        _lastScore = score;
        _feedback = grade['comentario'] as String;
        if (grade['correcta'] == true) _correctas++;
      });

      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      if (_current < widget.quiz.preguntas.length - 1) {
        setState(() {
          _current++;
          _answered = false;
          _selected = null;
          _feedback = null;
          _lastScore = null;
          _textController.clear();
        });
      } else {
        await _finish();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _grading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo evaluar la respuesta: $error')),
      );
    }
  }

  Future<void> _finish() async {
    final nota = (_totalScore / widget.quiz.preguntas.length).round();
    try {
      final progress = await ProgressService().setSectionCompleted(
        seminarioId: widget.seminarioId,
        seccionId: widget.quiz.seccionId,
        totalSections: widget.totalSecciones,
        completed: true,
      );
      if (mounted && progress >= 1.0) await StreakService().recordActivity();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quiz corregido, pero no se pudo guardar el resultado: $error')),
        );
      }
    }

    if (!mounted) return;
    showCelebration(
      context,
      'Quiz completado',
      'Nota: $nota/100. Respuestas correctas: $_correctas de ${widget.quiz.preguntas.length}.',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pregunta = widget.quiz.preguntas[_current];
    final progreso = (_current + 1) / widget.quiz.preguntas.length;

    return Scaffold(
      appBar: AppBar(title: Text(widget.quiz.titulo)),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Padding(
          key: ValueKey(_current),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: progreso),
              const SizedBox(height: 8),
              Text('Pregunta ${_current + 1} de ${widget.quiz.preguntas.length}'),
              const SizedBox(height: 24),
              Text(
                pregunta.enunciado,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              if (pregunta.tipo == 'multiple')
                ...pregunta.opciones.map((op) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _answered && op == _selected
                              ? (_lastScore == 100 ? Colors.green : Colors.red)
                              : null,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: _answered || _grading
                            ? null
                            : () {
                                setState(() => _selected = op);
                                _checkAnswer(op);
                              },
                        child: Text(op),
                      ),
                    ))
              else
                Column(
                  children: [
                    TextField(
                      controller: _textController,
                      readOnly: _answered || _grading,
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu respuesta',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: _answered || _grading ? null : _checkAnswer,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _answered || _grading ? null : () => _checkAnswer(_textController.text),
                      child: _grading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Comprobar'),
                    ),
                  ],
                ),
              if (_grading) ...[
                const SizedBox(height: 16),
                const Text('Evaluando tu respuesta...'),
              ],
              if (_answered) ...[
                const SizedBox(height: 16),
                Text('Puntuación: $_lastScore/100'),
                Text(
                  _feedback ?? pregunta.explicacion ?? '',
                  style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
