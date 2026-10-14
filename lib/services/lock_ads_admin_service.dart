// firebase_storage analyzer resolution fails on some Windows SDK setups.
// ignore_for_file: uri_does_not_exist, undefined_identifier

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/lock_ad.dart';

class LockAdsAdminService {
  final _col = FirebaseFirestore.instance.collection('anunciosBloqueo');

  Stream<List<LockAd>> watch() {
    return _col.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map((doc) => LockAd.fromMap(doc.id, doc.data())).toList(),
        );
  }

  Future<List<LockAd>> listActive() async {
    final snap = await _col.where('activo', isEqualTo: true).get();
    return snap.docs
        .map((doc) => LockAd.fromMap(doc.id, doc.data()))
        .where((ad) => ad.texto.isNotEmpty && ad.imagenUrl.isNotEmpty)
        .toList();
  }

  Future<void> create({required String texto, required File image}) async {
    final trimmed = texto.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('El texto no puede estar vacío');
    }
    if (await image.length() > 8 * 1024 * 1024) {
      throw ArgumentError('La imagen no puede superar 8 MB');
    }
    final doc = _col.doc();
    final version = DateTime.now().millisecondsSinceEpoch.toString();
    final storageRef = FirebaseStorage.instance.ref('anunciosBloqueo/${doc.id}/$version.jpg');
    await storageRef.putFile(image, SettableMetadata(contentType: 'image/jpeg'));
    final url = await storageRef.getDownloadURL();
    await doc.set({
      'texto': trimmed,
      'imagenUrl': url,
      'version': version,
      'activo': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setActivo(String id, bool activo) {
    return _col.doc(id).update({
      'activo': activo,
      'version': DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }

  Future<void> delete(LockAd ad) async {
    try {
      await FirebaseStorage.instance.refFromURL(ad.imagenUrl).delete();
    } catch (_) {
      // The firestore doc should still go away even if storage already vanished.
    }
    await _col.doc(ad.id).delete();
  }
}
