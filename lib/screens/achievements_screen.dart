import 'package:flutter/material.dart';
import '../widgets/fade_slide_in.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final count = await ProgressService().getCompletedSeminariosCount();
    setState(() => _completedCount = count);
  }

  @override
  Widget build(BuildContext context) {
    final achievements = [
      _Achievement('Primer paso', 'Completa tu primer seminario', 1, Icons.flag),
      _Achievement('Caminante', 'Completa 5 seminarios', 5, Icons.directions_walk),
      _Achievement('Peregrino', 'Completa 10 seminarios', 10, Icons.hiking),
      _Achievement('Maestro del camino', 'Completa 25 seminarios', 25, Icons.military_tech),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Logros')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Seminarios completados: $_completedCount',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ...achievements.map((a) => Card(
                child: ListTile(
                  leading: Icon(
                    a.icon,
                    color: _completedCount >= a.requiredCount
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  title: Text(a.title),
                  subtitle: Text(a.description),
                  trailing: _completedCount >= a.requiredCount
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : Text('${a.requiredCount}'),
                ),
              )),
        ],
      ),
    );
  }
}

class _Achievement {
  final String title;
  final String description;
  final int requiredCount;
  final IconData icon;
  _Achievement(this.title, this.description, this.requiredCount, this.icon);
}
