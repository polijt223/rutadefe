import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/progress_service.dart';
import '../services/streak_service.dart';
import '../services/theme_service.dart';
import 'package:provider/provider.dart';
import '../widgets/adaptive_body.dart';
import '../widgets/fade_slide_in.dart';
import 'lock_ads_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _completed = 0;
  int _streak = 0;
  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final completed = await ProgressService().getCompletedSeminariosCount();
    final streak = await StreakService().getCurrentStreak();
    if (!mounted) return;
    setState(() {
      _completed = completed;
      _streak = streak;
    });
  }

  Future<void> _editDisplayName() async {
    final user = _user;
    if (user == null) return;
    final controller = TextEditingController(text: user.displayName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;

    try {
      await user.updateDisplayName(name);
      await FirebaseFirestore.instance.collection('perfilesPublicos').doc(user.uid).set(
        {'uid': user.uid, 'displayName': name},
        SetOptions(merge: true),
      );
      await user.reload();
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar el perfil: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            tooltip: 'Editar nombre',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editDisplayName,
          ),
        ],
      ),
      body: FadeSlideIn(
        child: AdaptiveBody(
        maxWidth: 560,
        child: ListView(
          children: [
            Center(
              child: CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              child: Text(
                (_user?.displayName?.isNotEmpty == true)
                    ? _user!.displayName![0].toUpperCase()
                    : 'U',
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _user?.displayName ?? 'Usuario',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              _user?.email ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65)),
            ),
            const SizedBox(height: 24),
            Text('Apariencia', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Auto'), icon: Icon(Icons.brightness_auto)),
                ButtonSegment(value: ThemeMode.light, label: Text('Claro'), icon: Icon(Icons.light_mode)),
                ButtonSegment(value: ThemeMode.dark, label: Text('Oscuro'), icon: Icon(Icons.dark_mode)),
              ],
              selected: {context.watch<ThemeService>().themeMode},
              onSelectionChanged: (selected) {
                context.read<ThemeService>().setThemeMode(selected.first);
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(Icons.lock_open_outlined, color: Theme.of(context).colorScheme.primary),
                title: const Text('Pantalla de bloqueo'),
                subtitle: const Text('Reflexiones al desbloquear el teléfono'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LockAdsSettingsScreen()),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
            const _StatCard(
              icon: Icons.menu_book,
              label: 'En progreso',
              value: 'Ver en inicio',
            ),
          ],
        ),
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
