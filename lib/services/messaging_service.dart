import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase_options.dart';
import 'local_cache_service.dart';

@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await MessagingService.recordMessage(message);
}

class MessagingService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen(recordMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(recordMessage);
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) unawaited(_saveToken(user.uid, token));
    });

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) unawaited(_registerUser(user));
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) await recordMessage(initialMessage);
  }

  static Future<void> _registerUser(User user) async {
    final friendCode = user.uid.substring(0, 6).toUpperCase();
    final privateProfile = <String, dynamic>{
      'uid': user.uid,
      'friendCode': friendCode,
    };
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .set(privateProfile, SetOptions(merge: true));
    await FirebaseFirestore.instance.collection('perfilesPublicos').doc(user.uid).set({
      'uid': user.uid,
      'displayName': user.displayName?.trim().isNotEmpty == true ? user.displayName!.trim() : 'Usuario',
      'photoUrl': user.photoURL,
    }, SetOptions(merge: true));
    await FirebaseFirestore.instance.collection('codigosAmigo').doc(friendCode).set({'uid': user.uid});

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _saveToken(user.uid, token);
  }

  static Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> recordMessage(RemoteMessage message) async {
    final data = message.data;
    final seminarioId = data['seminarioId']?.toString();
    final reflexionId = data['miniReflexionId']?.toString();
    if (seminarioId == null || seminarioId.isEmpty ||
        reflexionId == null || reflexionId.isEmpty) {
      return;
    }

    await LocalCacheService.saveNotificationHistory(
      seminarioId: seminarioId,
      miniReflexionId: reflexionId,
      texto: (data['texto'] ?? message.notification?.body ?? '').toString(),
      imagenUrl: data['imagenUrl']?.toString(),
    );
  }
}