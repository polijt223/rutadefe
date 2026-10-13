import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _key = 'favorite_sections';

  Future<Set<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key)?.toSet() ?? {};
  }

  Future<void> toggleFavorite(String seccionId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key)?.toSet() ?? {};
    if (current.contains(seccionId)) {
      current.remove(seccionId);
    } else {
      current.add(seccionId);
    }
    await prefs.setStringList(_key, current.toList());
  }

  Future<bool> isFavorite(String seccionId) async {
    final favs = await getFavorites();
    return favs.contains(seccionId);
  }
}
