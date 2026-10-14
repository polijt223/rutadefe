import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_motion.dart';
import '../widgets/adaptive_body.dart';
import '../widgets/brand_logo.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.route,
      title: 'Bienvenido a Ruta de Fe',
      description: 'Un espacio para crecer espiritualmente con seminarios, reflexiones y material de estudio.',
    ),
    _OnboardingPage(
      icon: Icons.notifications_active,
      title: 'Notificaciones diarias',
      description: 'Activa recordatorios por seminario y recibe mini-reflexiones a tu ritmo.',
    ),
    _OnboardingPage(
      icon: Icons.emoji_events,
      title: 'Progreso y logros',
      description: 'Marca tu avance, completa quizzes, gana certificados y comparte el camino con amigos.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(dark ? 'assets/home/bg_dark.jpg' : 'assets/home/bg_light.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
        child: AdaptiveBody(
          maxWidth: 560,
          child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.emphasized,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? colors.primary : colors.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _page == _pages.length - 1
                      ? _finish
                      : () => _controller.nextPage(
                            duration: AppMotion.medium,
                            curve: AppMotion.emphasized,
                          ),
                  child: Text(_page == _pages.length - 1 ? 'Comenzar' : 'Siguiente'),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
        ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon == Icons.route)
            const BrandLogo(height: 160)
          else
            Icon(icon, size: 100, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 32),
          Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
