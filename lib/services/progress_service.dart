import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Progreso por seminario: caché local (offline) y réplica en Firestore.
class ProgressService {
  static const _prefix = 'progress_';
  static const _completedSectionsPrefix = 'completed_sections_';
  static final Map<String, double> _progressCache = {};

  ProgressService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  FirebaseFirestore? get _db {
    if (_firestore != null) return _firestore;
    if (Firebase.apps.isEmpty) return null;
    return FirebaseFirestore.instance;
  }

  String? get _uid {
    try {
      return (_auth ?? (Firebase.apps.isEmpty ? null : FirebaseAuth.instance))
          ?.currentUser
          ?.uid;
    } catch (_) {
      return null;
    }
  }

  double getProgress(String seminarioId) {
    return _progressCache[seminarioId] ?? 0.0;
  }

  Future<void> loadStoredProgress() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where((key) => key.startsWith(_prefix))) {
      _progressCache[key.substring(_prefix.length)] = prefs.getDouble(key) ?? 0.0;
    }

    final db = _db;
    final uid = _uid;
    if (db == null || uid == null) return;

    try {
      final snap = await db.collection('usuarios').doc(uid).collection('progreso').get();
      for (final doc in snap.docs) {
        await _mergeRemoteSeminar(prefs, doc.id, doc.data());
      }
    } catch (_) {}
  }

  Future<void> setProgress(String seminarioId, double progress) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = progress.clamp(0.0, 1.0).toDouble();
    await prefs.setDouble('$_prefix$seminarioId', normalized);
    _progressCache[seminarioId] = normalized;
  }

  Future<double> getProgressAsync(String seminarioId) async {
    final prefs = await SharedPreferences.getInstance();
    final progress = prefs.getDouble('$_prefix$seminarioId') ?? 0.0;
    _progressCache[seminarioId] = progress;
    return progress;
  }

  Future<Set<String>> getCompletedSections(String seminarioId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('$_completedSectionsPrefix$seminarioId') ?? []).toSet();
  }

  Future<bool> isSectionCompleted(String seminarioId, String seccionId) async {
    final completed = await getCompletedSections(seminarioId);
    return completed.contains(seccionId);
  }

  Future<double> setSectionCompleted({
    required String seminarioId,
    required String seccionId,
    required int totalSections,
    required bool completed,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_completedSectionsPrefix$seminarioId';
    final sections = (prefs.getStringList(key) ?? []).toSet();
    if (completed) {
      sections.add(seccionId);
    } else {
      sections.remove(seccionId);
    }
    await prefs.setStringList(key, sections.toList());

    final progress = totalSections == 0 ? 0.0 : sections.length / totalSections;
    await setProgress(seminarioId, progress);
    await _writeRemote(
      seminarioId: seminarioId,
      sections: sections,
      progress: progress,
      totalSections: totalSections,
    );
    return progress;
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

  Future<void> _mergeRemoteSeminar(
    SharedPreferences prefs,
    String seminarioId,
    Map<String, dynamic> data,
  ) async {
    final remoteSections = List<String>.from(data['seccionesCompletadas'] ?? const []);
    final localKey = '$_completedSectionsPrefix$seminarioId';
    final localSections = (prefs.getStringList(localKey) ?? []).toSet();
    final merged = {...localSections, ...remoteSections};
    final total = (data['totalSecciones'] as num?)?.toInt();
    final remoteProgress = (data['progreso'] as num?)?.toDouble() ?? 0.0;
    final localProgress = prefs.getDouble('$_prefix$seminarioId') ?? 0.0;
    final progress = total != null && total > 0
        ? (merged.length / total).clamp(0.0, 1.0)
        : (localProgress > remoteProgress ? localProgress : remoteProgress);

    await prefs.setStringList(localKey, merged.toList());
    await prefs.setDouble('$_prefix$seminarioId', progress);
    _progressCache[seminarioId] = progress;

    final remoteChanged =
        merged.length != remoteSections.toSet().length || (total != null && progress != remoteProgress);
    if (remoteChanged) {
      await _writeRemote(
        seminarioId: seminarioId,
        sections: merged,
        progress: progress,
        totalSections: total,
      );
    }
  }

  Future<void> _writeRemote({
    required String seminarioId,
    required Set<String> sections,
    required double progress,
    int? totalSections,
  }) async {
    final db = _db;
    final uid = _uid;
    if (db == null || uid == null) return;

    try {
      final payload = <String, dynamic>{
        'seccionesCompletadas': sections.toList(),
        'progreso': progress,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (totalSections != null) {
        payload['totalSecciones'] = totalSections;
      }
      await db
          .collection('usuarios')
          .doc(uid)
          .collection('progreso')
          .doc(seminarioId)
          .set(payload, SetOptions(merge: true));
    } catch (_) {}
  }
}
