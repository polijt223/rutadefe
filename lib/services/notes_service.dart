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
    await _db.collection('usuarios').doc(_uid).collection('notas').doc(seccionId).set({
      'texto': texto,
      'seminarioId': seminarioId,
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> getMyNote(String seccionId) async {
    if (_uid == null) return null;
    final doc = await _db.collection('usuarios').doc(_uid).collection('notas').doc(seccionId).get();
    return doc.data()?['texto'];
  }

  /// Notas de amigos en la misma sección
  Future<List<Map<String, dynamic>>> getFriendsNotes({
    required String seccionId,
    required List<String> friendUids,
  }) async {
    final notes = <Map<String, dynamic>>[];
    for (final uid in friendUids) {
      final doc = await _db.collection('usuarios').doc(uid).collection('notas').doc(seccionId).get();
      if (doc.exists && doc.data()?['texto'] != null) {
        final userDoc = await _db.collection('usuarios').doc(uid).get();
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
