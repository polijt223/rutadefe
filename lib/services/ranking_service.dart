import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RankingService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

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
      final userDoc = await _db.collection('perfilesPublicos').doc(uid).get();
      final scoreData = puntajeDoc.data() ?? {};
      final promedio = scoreData['promedio'] ?? 0;
      ranking.add({
        'uid': uid,
        'nombre': userDoc.data()?['displayName'] ?? 'Usuario',
        'promedio': promedio,
        'totalQuizzes': scoreData['totalQuizzes'] ?? 0,
        'esYo': uid == _uid,
      });
    }

    ranking.sort((a, b) => (b['promedio'] as int).compareTo(a['promedio'] as int));
    return ranking;
  }
}
