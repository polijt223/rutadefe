import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutadefe/models/lock_ad.dart';
import 'package:rutadefe/services/lock_ads_store.dart';
import 'package:rutadefe/services/lock_ads_sync_service.dart';
import 'package:rutadefe/services/lock_screen_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryStore extends LockAdsStore {
  final items = <String, LockAdLocalRow>{};
  String catalogPath = '/tmp/catalog.json';
  final downloaded = <String>[];

  @override
  Future<List<LockAdLocalRow>> all() async => items.values.toList();

  @override
  Future<String> download(LockAd ad) async {
    downloaded.add(ad.id);
    items[ad.id] = LockAdLocalRow(
      id: ad.id,
      texto: ad.texto,
      imagenUrl: ad.imagenUrl,
      version: ad.version,
      localPath: '/tmp/${ad.id}.jpg',
    );
    return items[ad.id]!.localPath;
  }

  @override
  Future<void> updateMeta(LockAd ad) async {
    final current = items[ad.id];
    if (current == null) return;
    items[ad.id] = LockAdLocalRow(
      id: ad.id,
      texto: ad.texto,
      imagenUrl: ad.imagenUrl,
      version: ad.version,
      localPath: current.localPath,
    );
  }

  @override
  Future<void> delete(String id) async {
    items.remove(id);
  }

  @override
  Future<File> writeCatalog(List<LockAdLocalRow> rows) async {
    return File(catalogPath);
  }
}

class _FakeChannel extends LockScreenChannel {
  bool enabled = false;
  String? catalog;
  int applyCurrentCount = 0;
  int applyNextCount = 0;

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<void> setEnabled(bool enabled) async {
    this.enabled = enabled;
  }

  @override
  Future<void> updateCatalog(String catalogPath) async {
    catalog = catalogPath;
  }

  @override
  Future<void> applyCurrent() async {
    applyCurrentCount++;
  }

  @override
  Future<void> applyNext() async {
    applyNextCount++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('skips network when already synced today', () async {
    SharedPreferences.setMockInitialValues({
      LockAdsSyncService.enabledKey: true,
      LockAdsSyncService.lastSyncDayKey: '2026-10-14',
    });
    final store = _MemoryStore();
    final channel = _FakeChannel();
    var fetches = 0;
    final sync = LockAdsSyncService(
      store: store,
      channel: channel,
      clock: () => DateTime(2026, 10, 14),
      fetcher: () async {
        fetches++;
        return const [LockAd(id: 'a', texto: 'hola', imagenUrl: 'https://img/a.jpg', version: '1')];
      },
    );

    expect(await sync.syncIfDue(), 0);
    expect(fetches, 0);
    expect(store.downloaded, isEmpty);
    expect(channel.applyCurrentCount, 1);
  });

  test('downloads only ads the device does not already have', () async {
    SharedPreferences.setMockInitialValues({
      LockAdsSyncService.enabledKey: true,
    });
    final store = _MemoryStore()
      ..items['keep'] = const LockAdLocalRow(
        id: 'keep',
        texto: 'sigue',
        imagenUrl: 'https://img/keep.jpg',
        version: '1',
        localPath: '/tmp/keep.jpg',
      )
      ..items['old'] = const LockAdLocalRow(
        id: 'old',
        texto: 'viejo',
        imagenUrl: 'https://img/old.jpg',
        version: '1',
        localPath: '/tmp/old.jpg',
      );
    final channel = _FakeChannel();
    final sync = LockAdsSyncService(
      store: store,
      channel: channel,
      clock: () => DateTime(2026, 10, 14),
      fetcher: () async => const [
        LockAd(id: 'keep', texto: 'sigue', imagenUrl: 'https://img/keep.jpg', version: '1'),
        LockAd(id: 'new', texto: 'nuevo', imagenUrl: 'https://img/new.jpg', version: '1'),
      ],
    );

    expect(await sync.syncIfDue(), 2);
    expect(store.downloaded, ['new']);
    expect(store.items.containsKey('old'), isFalse);
    expect(channel.catalog, '/tmp/catalog.json');
    expect(channel.applyCurrentCount, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(LockAdsSyncService.lastSyncDayKey), '2026-10-14');
  });

  test('does nothing when the user has the lock screen ads disabled', () async {
    SharedPreferences.setMockInitialValues({});
    final store = _MemoryStore();
    var fetches = 0;
    final sync = LockAdsSyncService(
      store: store,
      clock: () => DateTime(2026, 10, 14),
      fetcher: () async {
        fetches++;
        return const [];
      },
    );
    expect(await sync.syncIfDue(force: true), 0);
    expect(fetches, 0);
  });
}
