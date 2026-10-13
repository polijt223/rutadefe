import 'package:shared_preferences/shared_preferences.dart';

class SectionCooldownService {
  static const _keyLastSectionTime = 'last_section_open_time';
  static const cooldown = Duration(minutes: 30);

  Future<bool> canOpenSection() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_keyLastSectionTime);
    if (last == null) return true;
    final lastTime = DateTime.fromMillisecondsSinceEpoch(last);
    return DateTime.now().difference(lastTime) >= cooldown;
  }

  Future<Duration> remainingTime() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_keyLastSectionTime);
    if (last == null) return Duration.zero;
    final lastTime = DateTime.fromMillisecondsSinceEpoch(last);
    final elapsed = DateTime.now().difference(lastTime);
    if (elapsed >= cooldown) return Duration.zero;
    return cooldown - elapsed;
  }

  Future<void> markSectionOpened() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastSectionTime, DateTime.now().millisecondsSinceEpoch);
  }
}
