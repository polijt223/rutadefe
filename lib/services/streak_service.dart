import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static const _keyLastDate = 'streak_last_date';
  static const _keyCurrent = 'streak_current';

  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCurrent) ?? 0;
  }

  Future<void> recordActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final lastStr = prefs.getString(_keyLastDate);

    int current = prefs.getInt(_keyCurrent) ?? 0;

    if (lastStr == null) {
      current = 1;
    } else {
      final last = DateTime.parse(lastStr);
      final difference = today.difference(last).inDays;
      if (difference == 1) {
        current += 1;
      } else if (difference > 1) {
        current = 1;
      }
      // si difference == 0, ya registró hoy
    }

    await prefs.setString(_keyLastDate, todayStr);
    await prefs.setInt(_keyCurrent, current);
  }
}
