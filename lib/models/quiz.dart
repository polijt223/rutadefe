class PreguntaQuiz {
  final String id;
  final String tipo; // 'multiple' o 'completar'
  final String enunciado;
  final List<String> opciones; // solo para multiple
  final String respuestaCorrecta;
  final String? explicacion;

  PreguntaQuiz({
    required this.id,
    required this.tipo,
    required this.enunciado,
    this.opciones = const [],
    required this.respuestaCorrecta,
    this.explicacion,
  });

  factory PreguntaQuiz.fromMap(String id, Map<String, dynamic> map) {
    return PreguntaQuiz(
      id: id,
      tipo: map['tipo'] ?? 'multiple',
      enunciado: map['enunciado'] ?? '',
      opciones: List<String>.from(map['opciones'] ?? []),
      respuestaCorrecta: map['respuestaCorrecta'] ?? '',
      explicacion: map['explicacion'],
    );
  }
}

class Quiz {
  final String id;
  final String seccionId;
  final String titulo;
  final List<PreguntaQuiz> preguntas;

  Quiz({
    required this.id,
    required this.seccionId,
    required this.titulo,
    required this.preguntas,
  });

  factory Quiz.fromMap(String id, Map<String, dynamic> map, List<PreguntaQuiz> preguntas) {
    return Quiz(
      id: id,
      seccionId: map['seccionId'] ?? '',
      titulo: map['titulo'] ?? 'Quiz',
      preguntas: preguntas,
    );
  }
}
