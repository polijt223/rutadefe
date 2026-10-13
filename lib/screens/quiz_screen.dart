import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../services/progress_service.dart';
import '../widgets/celebration_dialog.dart';

class QuizScreen extends StatefulWidget {
  final Quiz quiz;
  final String seminarioId;
  const QuizScreen({super.key, required this.quiz, required this.seminarioId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _current = 0;
  int _correctas = 0;
  bool _answered = false;
  String? _selected;
  final _textController = TextEditingController();

  void _checkAnswer(String respuesta) {
    final pregunta = widget.quiz.preguntas[_current];
    final esCorrecta = respuesta.trim().toLowerCase() ==
        pregunta.respuestaCorrecta.trim().toLowerCase();

    setState(() {
      _answered = true;
      if (esCorrecta) _correctas++;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_current < widget.quiz.preguntas.length - 1) {
        setState(() {
          _current++;
          _answered = false;
          _selected = null;
          _textController.clear();
        });
      } else {
        _finish();
      }
    });
  }

  void _finish() async {
    final porcentaje = _correctas / widget.quiz.preguntas.length;
    await ProgressService().setProgress(
      widget.seminarioId,
      (await ProgressService().getProgressAsync(widget.seminarioId) + porcentaje * 0.2).clamp(0.0, 1.0),
    );

    if (!mounted) return;
    showCelebration(
      context,
      'Quiz completado',
      'Respondiste $_correctas de ${widget.quiz.preguntas.length} correctamente.',
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
                          backgroundColor: _answered && op == pregunta.respuestaCorrecta
                              ? Colors.green
                              : _answered && op == _selected
                                  ? Colors.red
                                  : null,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: _answered
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
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu respuesta',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: _answered ? null : _checkAnswer,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _answered ? null : () => _checkAnswer(_textController.text),
                      child: const Text('Comprobar'),
                    ),
                  ],
                ),
              if (_answered && pregunta.explicacion != null) ...[
                const SizedBox(height: 16),
                Text(
                  pregunta.explicacion!,
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
