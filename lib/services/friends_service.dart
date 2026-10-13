import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend.dart';

class FriendsService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Agregar amigo por código (el código es el uid corto o un código personalizado)
  Future<bool> addFriendByCode(String code) async {
    if (_uid == null) return false;
    // Buscar usuario por código (en producción se puede usar un campo 'friendCode')
    final codeDoc = await _db.collection('codigosAmigo').doc(code.toUpperCase()).get();
    final friendUid = codeDoc.data()?['uid'] as String?;
    if (friendUid == null) return false;
    if (friendUid == _uid) return false;

    await _db.collection('usuarios').doc(_uid).collection('amigos').doc(friendUid).set({
      'addedAt': FieldValue.serverTimestamp(),
    });
    // Bidireccional opcional
    await _db.collection('usuarios').doc(friendUid).collection('amigos').doc(_uid!).set({
      'addedAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  Stream<List<Friend>> getFriends() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('usuarios')
        .doc(_uid)
        .collection('amigos')
        .snapshots()
        .asyncMap((snap) async {
      final friends = <Friend>[];
      for (final doc in snap.docs) {
        final userDoc = await _db.collection('perfilesPublicos').doc(doc.id).get();
        if (userDoc.exists) {
          friends.add(Friend.fromMap(doc.id, userDoc.data()!));
        }
      }
      return friends;
    });
  }

  Future<String> getMyFriendCode() async {
    if (_uid == null) return '';
    final doc = await _db.collection('usuarios').doc(_uid).get();
    return doc.data()?['friendCode'] ?? _uid!.substring(0, 6).toUpperCase();
  }
}
