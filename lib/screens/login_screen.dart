import 'package:flutter/material.dart';
import '../widgets/fade_slide_in.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
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
                  onPressed: () => auth.signInWithGoogle(),
                  icon: const Icon(Icons.login),
                  label: const Text('Continuar con Google'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Login con X: configurar OAuth en Firebase'),
                      ),
                    );
                  },
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
