import 'package:cloud_functions/cloud_functions.dart';

class GeminiService {
  static Future<Map<String, dynamic>> corregirRespuesta({
    required String seminarioId,
    required String seccionId,
    required String quizId,
    required String preguntaId,
    required String respuestaUsuario,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable('gradeQuizAnswer');
    final result = await callable.call<Map<String, dynamic>>({
      'seminarioId': seminarioId,
      'seccionId': seccionId,
      'quizId': quizId,
      'preguntaId': preguntaId,
      'respuestaUsuario': respuestaUsuario,
    });

    final data = result.data;
    final nota = data['nota'];
    final comentario = data['comentario'];
    final correcta = data['correcta'];
    if (nota is! num || comentario is! String || correcta is! bool) {
      throw const FormatException('Respuesta de correccion invalida.');
    }

    return {
      'nota': nota.round().clamp(0, 100),
      'comentario': comentario,
      'correcta': correcta,
    };
  }
}