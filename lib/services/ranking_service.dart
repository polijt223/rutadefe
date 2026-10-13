import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RankingService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Guarda la nota de un quiz (0-100) y actualiza el acumulado del seminario
  Future<void> saveQuizScore({
    required String seminarioId,
    required String quizId,
    required int nota, // 0-100
  }) async {
    if (_uid == null) return;
    final ref = _db.collection('usuarios').doc(_uid).collection('puntajes').doc(seminarioId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final quizzes = Map<String, dynamic>.from(data['quizzes'] ?? {});
      quizzes[quizId] = nota;

      final valores = quizzes.values.cast<int>();
      final promedio = valores.isEmpty ? 0 : (valores.reduce((a, b) => a + b) / valores.length).round();

      tx.set(ref, {
        'quizzes': quizzes,
        'promedio': promedio,
        'totalQuizzes': quizzes.length,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  /// Ranking solo entre amigos + yo mismo
  Future<List<Map<String, dynamic>>> getRankingAmongFriends({
    required String seminarioId,
    required List<String> friendUids,
  }) async {
    final allUids = [...friendUids];
    if (_uid != null) allUids.add(_uid!);

    final ranking = <Map<String, dynamic>>[];

    for (final uid in allUids) {
      final puntajeDoc = await _db.collection('usuarios').doc(uid).collection('puntajes').doc(seminarioId).get();
      final userDoc = await _db.collection('usuarios').doc(uid).get();
      final promedio = puntajeDoc.data()?['promedio'] ?? 0;
      ranking.add({
        'uid': uid,
        'nombre': userDoc.data()?['displayName'] ?? 'Usuario',
        'promedio': promedio,
        'esYo': uid == _uid,
      });
    }

    ranking.sort((a, b) => (b['promedio'] as int).compareTo(a['promedio'] as int));
    return ranking;
  }
}
