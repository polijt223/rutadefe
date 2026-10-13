import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../widgets/async_stream_builder.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _loadOnboarding();
  }

  Future<void> _loadOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _onboardingDone = prefs.getBool('onboarding_done') ?? false);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_onboardingDone!) {
      return OnboardingScreen(
        onCompleted: () => setState(() => _onboardingDone = true),
      );
    }

    return AsyncStreamBuilder<User?>(
      streamFactory: () => AuthService().authStateChanges,
      isDataReady: (snapshot) => snapshot.connectionState != ConnectionState.waiting,
      loadingMessage: 'Comprobando tu sesión...',
      builder: (context, user) {
        if (user == null) return const LoginScreen();
        return const HomeScreen();
      },
    );
  }
}
