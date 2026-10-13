import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/progress_service.dart';
import '../services/streak_service.dart';
import '../models/seminario.dart';
import 'seminario_detail_screen.dart';
import 'notifications_screen.dart';
import 'admin_screen.dart';
import 'achievements_screen.dart';
import 'friends_screen.dart';
import 'search_screen.dart';
import 'ranking_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStreak();
    StreakService().recordActivity();
  }

  Future<void> _loadStreak() async {
    final s = await StreakService().getCurrentStreak();
    if (mounted) setState(() => _streak = s);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final progressService = ProgressService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta de Fe'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mis seminarios'),
            Tab(text: 'Disponibles'),
          ],
        ),
        actions: [
          if (_streak > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: const Icon(Icons.local_fire_department, size: 18, color: Colors.orange),
                label: Text('$_streak'),
                visualDensity: VisualDensity.compact,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FriendsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AchievementsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () async {
              final isAdmin = await firestore.isAdmin();
              if (isAdmin && context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Seminario>>(
        stream: firestore.getSeminarios(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final allSeminarios = snapshot.data!;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildSeminarioList(
                allSeminarios.where((s) => progressService.getProgress(s.id) > 0).toList(),
                progressService,
                emptyMessage: 'Aún no has empezado ningún seminario',
              ),
              _buildSeminarioList(allSeminarios, progressService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSeminarioList(
    List<Seminario> seminarios,
    ProgressService progressService, {
    String emptyMessage = 'No hay seminarios disponibles',
  }) {
    if (seminarios.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: seminarios.length,
      itemBuilder: (context, index) {
        final s = seminarios[index];
        final progress = progressService.getProgress(s.id);

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 80)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Card(
            elevation: 4,
            shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SeminarioDetailScreen(seminario: s)),
              ),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.menu_book, size: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(
                                s.descripcion,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      color: Theme.of(context).colorScheme.primary,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% completado',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
