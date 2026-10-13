import 'package:shared_preferences/shared_preferences.dart';

/// Servicio simple de progreso local.
/// En producción se puede sincronizar con Firestore.
class ProgressService {
  static const _prefix = 'progress_';

  double getProgress(String seminarioId) {
    // Valor por defecto 0. Se actualiza al marcar secciones.
    // En una versión completa se leería de SharedPreferences o SQLite.
    return 0.0; // Placeholder: se implementa con persistencia real abajo
  }

  Future<void> setProgress(String seminarioId, double progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('$_prefix$seminarioId', progress.clamp(0.0, 1.0));
  }

  Future<double> getProgressAsync(String seminarioId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('$_prefix$seminarioId') ?? 0.0;
  }

  Future<int> getCompletedSeminariosCount() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    int count = 0;
    for (final key in keys) {
      final value = prefs.getDouble(key) ?? 0;
      if (value >= 1.0) count++;
    }
    return count;
  }
}
