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
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Seminario.fromMap(d.id, d.data()))
            .where((seminario) => seminario.activo)
            .toList()
          ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn)));
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
    final userRef = _db.collection('usuarios').doc(uid);
    final userDoc = await userRef.get();
    final notificationData = userDoc.data()?['notificaciones'];
    final preferences = notificationData is Map
        ? Map<String, dynamic>.from(notificationData)
        : <String, dynamic>{};
    final existingData = preferences[seminarioId];
    final existing = existingData is Map
        ? Map<String, dynamic>.from(existingData)
        : <String, dynamic>{};
    final restartCycle = enabled && existing['cycleCompleted'] == true;

    preferences[seminarioId] = {
      ...existing,
      'enabled': enabled,
      'frequency': frequency,
      'lastSentIndex': restartCycle ? 0 : existing['lastSentIndex'] ?? 0,
      'cycleCompleted': restartCycle ? false : existing['cycleCompleted'] ?? false,
      'lastSentAt': restartCycle ? null : existing['lastSentAt'],
    };
    await userRef.set({'notificaciones': preferences}, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getNotificationPreference(String seminarioId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('usuarios').doc(uid).get();
    final notificationData = doc.data()?['notificaciones'];
    if (notificationData is! Map) return null;
    final preference = notificationData[seminarioId];
    return preference is Map ? Map<String, dynamic>.from(preference) : null;
  }

  // Reiniciar ciclo de un seminario
  Future<void> restartNotificationCycle(String seminarioId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('usuarios').doc(uid).update({
      'notificaciones.$seminarioId.lastSentIndex': 0,
      'notificaciones.$seminarioId.cycleCompleted': false,
      'notificaciones.$seminarioId.enabled': true,
      'notificaciones.$seminarioId.lastSentAt': FieldValue.delete(),
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
    final quiz = Quiz.fromMap(quizDoc.id, quizDoc.data(), preguntas);
    return Quiz(
      id: quiz.id,
      seccionId: seccionId,
      titulo: quiz.titulo,
      preguntas: quiz.preguntas,
    );
  }
  Future<bool> isAdmin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final doc = await _db.collection('usuarios').doc(uid).get();
    return doc.data()?['isAdmin'] == true;
  }
}
