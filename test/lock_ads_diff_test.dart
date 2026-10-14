import 'package:flutter_test/flutter_test.dart';
import 'package:rutadefe/models/lock_ad.dart';
import 'package:rutadefe/services/lock_ads_diff.dart';

void main() {
  test('day key is stable for the calendar day', () {
    expect(LockAdsDiff.dayKey(DateTime(2026, 10, 14)), '2026-10-14');
  });

  test('syncs once per day unless forced', () {
    expect(
      LockAdsDiff.shouldSync(lastDay: '2026-10-14', today: '2026-10-14', force: false),
      isFalse,
    );
    expect(
      LockAdsDiff.shouldSync(lastDay: '2026-10-13', today: '2026-10-14', force: false),
      isTrue,
    );
    expect(
      LockAdsDiff.shouldSync(lastDay: '2026-10-14', today: '2026-10-14', force: true),
      isTrue,
    );
  });

  test('downloads new or changed images and deletes stale ones', () {
    final plan = LockAdsDiff.plan(
      remote: const [
        LockAdRemoteRef(id: 'a', version: '2', imagenUrl: 'https://img/a2.jpg'),
        LockAdRemoteRef(id: 'b', version: '1', imagenUrl: 'https://img/b.jpg'),
        LockAdRemoteRef(id: 'c', version: '2', imagenUrl: 'https://img/c.jpg'),
      ],
      local: const [
        LockAdLocalRef(id: 'a', version: '1', imagenUrl: 'https://img/a1.jpg'),
        LockAdLocalRef(id: 'b', version: '1', imagenUrl: 'https://img/b.jpg'),
        LockAdLocalRef(id: 'gone', version: '1', imagenUrl: 'https://img/x.jpg'),
      ],
    );
    expect(plan.downloadIds, ['a', 'c']);
    expect(plan.keepIds, ['b']);
    expect(plan.deleteIds, ['gone']);
    expect(plan.updateMetaIds, isEmpty);
  });

  test('updates text-only changes without redownloading the image', () {
    final plan = LockAdsDiff.plan(
      remote: const [
        LockAdRemoteRef(id: 'a', version: '2', imagenUrl: 'https://img/a.jpg'),
      ],
      local: const [
        LockAdLocalRef(id: 'a', version: '1', imagenUrl: 'https://img/a.jpg'),
      ],
    );
    expect(plan.updateMetaIds, ['a']);
    expect(plan.downloadIds, isEmpty);
  });

  test('parses firestore maps', () {
    final ad = LockAd.fromMap('id-1', {
      'texto': '  Confía en el camino  ',
      'imagenUrl': 'https://img/a.jpg',
      'version': '9',
      'activo': true,
    });
    expect(ad.texto, 'Confía en el camino');
    expect(ad.activo, isTrue);
  });
}
