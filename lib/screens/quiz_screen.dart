import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../services/gemini_service.dart';
import '../services/progress_service.dart';
import '../services/streak_service.dart';
import '../theme/app_motion.dart';
import '../widgets/adaptive_body.dart';
import '../widgets/celebration_dialog.dart';

typedef QuizGrader = Future<Map<String, dynamic>> Function({
  required String seminarioId,
  required String seccionId,
  required String quizId,
  required String preguntaId,
  required String respuestaUsuario,
});

class QuizScreen extends StatefulWidget {
  final Quiz quiz;
  final String seminarioId;
  final int totalSecciones;
  final QuizGrader? grader;

  const QuizScreen({
    super.key,
    required this.quiz,
    required this.seminarioId,
    this.totalSecciones = 1,
    this.grader,
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

  PreguntaQuiz get _pregunta => widget.quiz.preguntas[_current];
  bool get _isLast => _current >= widget.quiz.preguntas.length - 1;

  Future<void> _checkAnswer(String respuesta) async {
    if (_answered || _grading) return;
    final trimmed = respuesta.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe una respuesta antes de enviarla.')),
      );
      return;
    }

    setState(() {
      _grading = true;
      _selected = trimmed;
    });

    try {
      final grader = widget.grader ?? GeminiService.corregirRespuesta;
      final grade = await grader(
        seminarioId: widget.seminarioId,
        seccionId: widget.quiz.seccionId,
        quizId: widget.quiz.id,
        preguntaId: _pregunta.id,
        respuestaUsuario: trimmed,
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
    } catch (error) {
      if (!mounted) return;
      setState(() => _grading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo evaluar la respuesta: $error')),
      );
    }
  }

  Future<void> _continue() async {
    if (!_answered || _grading) return;
    if (!_isLast) {
      setState(() {
        _current++;
        _answered = false;
        _selected = null;
        _feedback = null;
        _lastScore = null;
        _textController.clear();
      });
      return;
    }
    await _finish();
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
    await showCelebration(
      context,
      'Quiz completado',
      'Nota: $nota/100. Respuestas correctas: $_correctas de ${widget.quiz.preguntas.length}.',
    );
    if (mounted) Navigator.pop(context);
  }

  Color _scoreColor(BuildContext context) {
    final score = _lastScore ?? 0;
    if (score >= 80) return Colors.green.shade700;
    if (score >= 50) return Theme.of(context).colorScheme.primary;
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final progreso = (_current + 1) / widget.quiz.preguntas.length;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.quiz.titulo)),
      body: AdaptiveBody(
        maxWidth: 720,
        child: AnimatedSwitcher(
        duration: AppMotion.medium,
        child: SingleChildScrollView(
          key: ValueKey(_current),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: progreso, minHeight: 8),
              const SizedBox(height: 8),
              Text('Pregunta ${_current + 1} de ${widget.quiz.preguntas.length}'),
              const SizedBox(height: 24),
              Text(
                _pregunta.enunciado,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              if (_pregunta.tipo == 'multiple')
                ..._pregunta.opciones.map((op) {
                  final selected = op == _selected;
                  Color? background;
                  if (_answered && selected) {
                    background = (_lastScore == 100) ? Colors.green : Colors.red;
                  } else if (selected && _grading) {
                    background = colors.primaryContainer;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: background,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: _answered || _grading ? null : () => _checkAnswer(op),
                      child: Text(op),
                    ),
                  );
                })
              else
                Column(
                  children: [
                    TextField(
                      controller: _textController,
                      readOnly: _answered || _grading,
                      minLines: 3,
                      maxLines: 6,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu respuesta con tus palabras',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _answered || _grading
                            ? null
                            : () => _checkAnswer(_textController.text),
                        child: _grading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Enviar respuesta'),
                      ),
                    ),
                  ],
                ),
              if (_grading) ...[
                const SizedBox(height: 16),
                const Text('Evaluando tu respuesta...'),
              ],
              if (_answered) ...[
                const SizedBox(height: 16),
                Text(
                  'Puntuación: $_lastScore/100',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _scoreColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _feedback ?? _pregunta.explicacion ?? '',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _continue,
                    child: Text(_isLast ? 'Ver resultado' : 'Siguiente pregunta'),
                  ),
                ),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }
}
