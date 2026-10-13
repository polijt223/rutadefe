import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotesService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> saveNote({
    required String seccionId,
    required String seminarioId,
    required String texto,
  }) async {
    if (_uid == null) return;
    await _db
        .collection('seminarios')
        .doc(seminarioId)
        .collection('secciones')
        .doc(seccionId)
        .collection('notas')
        .doc(_uid)
        .set({
      'uid': _uid,
      'texto': texto,
      'seminarioId': seminarioId,
      'seccionId': seccionId,
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> getMyNote({required String seminarioId, required String seccionId}) async {
    if (_uid == null) return null;
    final doc = await _db
        .collection('seminarios')
        .doc(seminarioId)
        .collection('secciones')
        .doc(seccionId)
        .collection('notas')
        .doc(_uid)
        .get();
    if (doc.exists) return doc.data()?['texto'] as String?;

    final legacy = await _db.collection('usuarios').doc(_uid).collection('notas').doc(seccionId).get();
    final legacyData = legacy.data();
    if (legacyData?['seminarioId'] != seminarioId || legacyData?['texto'] is! String) return null;
    final text = legacyData!['texto'] as String;
    try {
      await saveNote(seccionId: seccionId, seminarioId: seminarioId, texto: text);
      await legacy.reference.delete();
    } catch (_) {}
    return text;
  }

  /// Notas de amigos en la misma sección
  Future<List<Map<String, dynamic>>> getFriendsNotes({
    required String seminarioId,
    required String seccionId,
    required List<String> friendUids,
  }) async {
    final notes = <Map<String, dynamic>>[];
    for (final uid in friendUids) {
      final doc = await _db
          .collection('seminarios')
          .doc(seminarioId)
          .collection('secciones')
          .doc(seccionId)
          .collection('notas')
          .doc(uid)
          .get();
      if (doc.exists && doc.data()?['texto'] != null) {
        final userDoc = await _db.collection('perfilesPublicos').doc(uid).get();
        notes.add({
          'uid': uid,
          'nombre': userDoc.data()?['displayName'] ?? 'Amigo',
          'texto': doc.data()!['texto'],
        });
      }
    }
    return notes;
  }
}
