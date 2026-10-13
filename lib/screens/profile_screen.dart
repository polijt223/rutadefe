import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/progress_service.dart';
import '../services/theme_service.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _completed = 0;
  int _streak = 0;
  final _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final completed = await ProgressService().getCompletedSeminariosCount();
    final streak = await StreakService().getCurrentStreak();
    setState(() {
      _completed = completed;
      _streak = streak;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: FadeSlideIn(
        child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              child: Text(
                (_user?.displayName?.isNotEmpty == true)
                    ? _user!.displayName![0].toUpperCase()
                    : 'U',
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _user?.displayName ?? 'Usuario',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(_user?.email ?? '', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Modo oscuro'),
              value: context.watch<ThemeService>().themeMode == ThemeMode.dark,
              onChanged: (v) {
                context.read<ThemeService>().setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
              },
            ),
            _StatCard(
              icon: Icons.local_fire_department,
              label: 'Racha actual',
              value: '$_streak días',
            ),
            const SizedBox(height: 12),
            _StatCard(
              icon: Icons.emoji_events,
              label: 'Seminarios completados',
              value: '$_completed',
            ),
            const SizedBox(height: 12),
            _StatCard(
              icon: Icons.menu_book,
              label: 'En progreso',
              value: 'Ver en inicio',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
