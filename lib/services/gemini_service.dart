import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // Usa la API gratuita de Gemini (gemini-1.5-flash o gemini-2.0-flash-exp)
  // El usuario debe poner su API key en un archivo de configuración o variables de entorno.
  static const String _apiKey = 'TU_GEMINI_API_KEY'; // Reemplazar
  static const String _model = 'gemini-1.5-flash';

  static Future<Map<String, dynamic>> corregirRespuesta({
    required String materialSeccion,
    required String pregunta,
    required String respuestaUsuario,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final prompt = '''
Eres un corrector claro y respetuoso de un seminario cristiano.
Material de estudio de la sección:
$materialSeccion

Pregunta: $pregunta
Respuesta del alumno: $respuestaUsuario

Evalúa la respuesta de forma justa pero indulgente.
- Si está bien, dilo directamente y menciona 1 o 2 puntos fuertes concretos de la respuesta.
- Si le falta algo, indícalo de forma breve y constructiva.
- Evita frases genéricas, invitaciones a reflexionar o cierres tipo "sigue adelante con paz".
- Máximo 4 oraciones.

Devuelve SOLO un JSON con este formato:
{
  "nota": 0-100,
  "comentario": "comentario concreto y constructivo",
  "correcta": true/false
}
''';

    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';
        // Limpiar posibles markdown
        final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(clean);
      } else {
        return {'nota': 5, 'comentario': 'No se pudo corregir en este momento', 'correcta': false};
      }
    } catch (e) {
      return {'nota': 50, 'comentario': 'Error de conexión. Intenta más tarde.', 'correcta': false};
    }
  }
}
