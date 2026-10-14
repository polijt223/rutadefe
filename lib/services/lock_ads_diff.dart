class LockAdRemoteRef {
  final String id;
  final String version;
  final String imagenUrl;

  const LockAdRemoteRef({
    required this.id,
    required this.version,
    required this.imagenUrl,
  });
}

class LockAdLocalRef {
  final String id;
  final String version;
  final String imagenUrl;

  const LockAdLocalRef({
    required this.id,
    required this.version,
    required this.imagenUrl,
  });
}

enum LockAdSyncAction { download, updateMeta, keep, delete }

class LockAdSyncPlan {
  final List<String> downloadIds;
  final List<String> updateMetaIds;
  final List<String> deleteIds;
  final List<String> keepIds;

  const LockAdSyncPlan({
    required this.downloadIds,
    required this.updateMetaIds,
    required this.deleteIds,
    required this.keepIds,
  });
}

class LockAdsDiff {
  static String dayKey(DateTime now) {
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  static bool shouldSync({
    required String? lastDay,
    required String today,
    required bool force,
  }) {
    return force || lastDay != today;
  }

  static LockAdSyncPlan plan({
    required Iterable<LockAdRemoteRef> remote,
    required Iterable<LockAdLocalRef> local,
  }) {
    final remoteById = {for (final item in remote) item.id: item};
    final localById = {for (final item in local) item.id: item};
    final download = <String>[];
    final updateMeta = <String>[];
    final keep = <String>[];
    final delete = <String>[];

    for (final item in remote) {
      final cached = localById[item.id];
      if (cached == null || cached.imagenUrl != item.imagenUrl) {
        download.add(item.id);
      } else if (cached.version != item.version) {
        updateMeta.add(item.id);
      } else {
        keep.add(item.id);
      }
    }
    for (final item in local) {
      if (!remoteById.containsKey(item.id)) {
        delete.add(item.id);
      }
    }
    return LockAdSyncPlan(
      downloadIds: download,
      updateMetaIds: updateMeta,
      deleteIds: delete,
      keepIds: keep,
    );
  }
}
