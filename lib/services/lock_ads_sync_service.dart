import 'package:shared_preferences/shared_preferences.dart';

import '../models/lock_ad.dart';
import 'lock_ads_admin_service.dart';
import 'lock_ads_diff.dart';
import 'lock_ads_store.dart';
import 'lock_screen_channel.dart';

class LockAdsSyncService {
  static const enabledKey = 'lock_ads_enabled';
  static const lastSyncDayKey = 'lock_ads_last_sync_day';

  final LockAdsStore _store;
  final LockAdsAdminService Function() _remoteFactory;
  final LockScreenChannel _channel;
  final Future<List<LockAd>> Function()? _fetcher;
  final DateTime Function() _clock;

  LockAdsSyncService({
    LockAdsStore? store,
    LockAdsAdminService? remote,
    LockAdsAdminService Function()? remoteFactory,
    LockScreenChannel? channel,
    Future<List<LockAd>> Function()? fetcher,
    DateTime Function()? clock,
  })  : _store = store ?? LockAdsStore(),
        _remoteFactory = remoteFactory ?? (() => remote ?? LockAdsAdminService()),
        _channel = channel ?? LockScreenChannel(),
        _fetcher = fetcher,
        _clock = clock ?? DateTime.now;

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(enabledKey) ?? false;
  }

  Future<String?> lastSyncDay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(lastSyncDayKey);
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, enabled);
    await _channel.setEnabled(enabled);
    if (enabled) {
      await syncIfDue(force: true);
    }
  }

  Future<int> syncIfDue({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(enabledKey) ?? false)) return 0;
    final today = LockAdsDiff.dayKey(_clock());
    final lastDay = prefs.getString(lastSyncDayKey);
    if (!LockAdsDiff.shouldSync(lastDay: lastDay, today: today, force: force)) {
      await _channel.applyCurrent();
      return (await _store.all()).length;
    }
    return _syncNow(prefs, today);
  }

  Future<int> _syncNow(SharedPreferences prefs, String today) async {
    final remote = await (_fetcher?.call() ?? _remoteFactory().listActive());
    final local = await _store.all();
    final plan = LockAdsDiff.plan(
      remote: remote.map(
        (ad) => LockAdRemoteRef(id: ad.id, version: ad.version, imagenUrl: ad.imagenUrl),
      ),
      local: local.map((row) => row.asRef),
    );
    final remoteById = {for (final ad in remote) ad.id: ad};

    for (final id in plan.downloadIds) {
      final ad = remoteById[id];
      if (ad != null) await _store.download(ad);
    }
    for (final id in plan.updateMetaIds) {
      final ad = remoteById[id];
      if (ad != null) await _store.updateMeta(ad);
    }
    for (final id in plan.deleteIds) {
      await _store.delete(id);
    }

    final rows = await _store.all();
    final catalog = await _store.writeCatalog(rows);
    await _channel.updateCatalog(catalog.path);
    await _channel.applyCurrent();
    await prefs.setString(lastSyncDayKey, today);
    return rows.length;
  }

  Future<void> applyNext() => _channel.applyNext();
}
