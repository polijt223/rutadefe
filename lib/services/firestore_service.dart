import '../models/mini_reflexion.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/seminario.dart';
import '../models/seccion.dart';
import '../models/quiz.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // SEMINARIOS
  Stream<List<Seminario>> getSeminarios() {
    return _db
        .collection('seminarios')
        .where('activo', isEqualTo: true)
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Seminario.fromMap(d.id, d.data()))
            .toList());
  }

  // SECCIONES de un seminario
  Stream<List<Seccion>> getSecciones(String seminarioId) {
    return _db
        .collection('seminarios')
        .doc(seminarioId)
        .collection('secciones')
        .orderBy('orden')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Seccion.fromMap(d.id, d.data())).toList());
  }

  // MINI REFLEXIONES de un seminario
  Future<List<MiniReflexion>> getMiniReflexiones(String seminarioId) async {
    final snap = await _db
        .collection('seminarios')
        .doc(seminarioId)
        .collection('miniReflexiones')
        .orderBy('orden')
        .get();
    return snap.docs
        .map((d) => MiniReflexion.fromMap(d.id, d.data()))
        .toList();
  }

  // Preferencias de notificación del usuario
  Future<void> setNotificationPreference({
    required String seminarioId,
    required bool enabled,
    required String frequency, // '1h', '6h', '12h'
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('usuarios').doc(uid).set({
      'notificaciones': {
        seminarioId: {
          'enabled': enabled,
          'frequency': frequency,
          'lastSentIndex': 0,
          'cycleCompleted': false,
        }
      }
    }, SetOptions(merge: true));
  }

  // Reiniciar ciclo de un seminario
  Future<void> restartNotificationCycle(String seminarioId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('usuarios').doc(uid).update({
      'notificaciones.$seminarioId.lastSentIndex': 0,
      'notificaciones.$seminarioId.cycleCompleted': false,
    });
  }

  // QUIZ de una sección
  Future<Quiz?> getQuiz(String seminarioId, String seccionId) async {
    final snap = await _db
        .collection('seminarios')
        .doc(seminarioId)
        .collection('secciones')
        .doc(seccionId)
        .collection('quiz')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final quizDoc = snap.docs.first;
    final preguntasSnap = await quizDoc.reference.collection('preguntas').get();
    final preguntas = preguntasSnap.docs
        .map((d) => PreguntaQuiz.fromMap(d.id, d.data()))
        .toList();
    return Quiz.fromMap(quizDoc.id, quizDoc.data(), preguntas);
  }
  Future<bool> isAdmin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final doc = await _db.collection('usuarios').doc(uid).get();
    return doc.data()?['isAdmin'] == true;
  }
}
