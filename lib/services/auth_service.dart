import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  // Placeholder para X/Twitter. Requiere configuración adicional de OAuth.
  // Recomendado: usar firebase_auth + twitter_login o el flujo OAuth de X.
  Future<UserCredential?> signInWithX() async {
    // TODO: Implementar con el paquete actualizado de X/Twitter OAuth
    // Ejemplo de estructura:
    // final twitterLogin = TwitterLogin(...);
    // final result = await twitterLogin.login();
    // luego crear credential y signInWithCredential
    throw UnimplementedError('Configurar OAuth de X/Twitter en Firebase Console');
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
