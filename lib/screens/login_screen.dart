import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSigningIn = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isSigningIn = true);
    try {
      final credential = await AuthService().signInWithGoogle();
      if (credential == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se seleccionó una cuenta de Google.')),
        );
      }
    } on FirebaseAuthException catch (error) {
      debugPrint('Google sign-in Firebase error: ${error.code} ${error.message}');
      if (mounted) {
        final message = switch (error.code) {
          'operation-not-allowed' => 'Google no está habilitado en Firebase Authentication.',
          'network-request-failed' => 'No hay conexión. Comprueba tu internet e inténtalo de nuevo.',
          'invalid-credential' => 'Firebase rechazó la credencial de Google. Revisa la configuración OAuth.',
          _ => 'Error de autenticación (${error.code}). ${error.message ?? ''}',
        };
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error, stackTrace) {
      debugPrint('Google sign-in failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo iniciar sesión con Google: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _signInWithX() async {
    setState(() => _isSigningIn = true);
    try {
      await AuthService().signInWithX();
    } on FirebaseAuthException catch (error) {
      final message = error.code == 'operation-not-allowed'
          ? 'X no está habilitado en Firebase Authentication.'
          : 'No se pudo iniciar sesión con X (${error.code}).';
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo iniciar sesión con X: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo placeholder - reemplazar con el logo real
              const Icon(Icons.route, size: 80, color: Color(0xFF8B1E3F)),
              const SizedBox(height: 16),
              Text(
                'Ruta de Fe',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text('Tu camino espiritual diario'),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSigningIn ? null : _signInWithGoogle,
                  icon: _isSigningIn
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: Text(_isSigningIn ? 'Conectando...' : 'Continuar con Google'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSigningIn ? null : _signInWithX,
                  icon: const Icon(Icons.alternate_email),
                  label: const Text('Continuar con X'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
