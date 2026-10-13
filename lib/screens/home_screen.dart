import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/progress_service.dart';
import '../services/streak_service.dart';
import '../models/seminario.dart';
import 'seminario_detail_screen.dart';
import 'notifications_screen.dart';
import 'admin_screen.dart';
import 'achievements_screen.dart';
import 'friends_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import '../services/auth_service.dart';
import '../widgets/async_stream_builder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _progressService = ProgressService();
  late TabController _tabController;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStreak();
    _loadProgress();
    StreakService().recordActivity();
  }

  Future<void> _loadStreak() async {
    final s = await StreakService().getCurrentStreak();
    if (mounted) setState(() => _streak = s);
  }

  Future<void> _loadProgress() async {
    await _progressService.loadStoredProgress();
    if (mounted) setState(() {});
  }

  void _openDrawerScreen(Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _openAdmin() async {
    Navigator.pop(context);
    try {
      final isAdmin = await FirestoreService().isAdmin();
      if (!mounted) return;
      if (isAdmin) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tienes permisos de administrador')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo verificar el acceso de administrador')),
        );
      }
    }
  }

  Widget _drawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        selected: selected,
        selectedColor: colors.primary,
        selectedTileColor: colors.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: onTap,
      ),
    );
  }

  Widget _drawerHeader() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    final name = displayName?.isNotEmpty == true ? displayName! : 'Ruta de Fe';
    final email = user?.email ?? 'Tu camino de crecimiento diario';
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: colors.primary,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colors.onPrimary.withValues(alpha: 0.16),
            child: Text(
              name[0].toUpperCase(),
              style: TextStyle(color: colors.onPrimary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.onPrimary, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.onPrimary.withValues(alpha: 0.78), fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.local_fire_department, size: 18, color: colors.onPrimary),
              const SizedBox(width: 6),
              Text(
                '$_streak ${_streak == 1 ? 'día' : 'días'} de racha',
                style: TextStyle(color: colors.onPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              _drawerHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _drawerSection('APRENDER'),
                    _drawerItem(
                      icon: Icons.menu_book_outlined,
                      label: 'Seminarios',
                      selected: true,
                      onTap: () => Navigator.pop(context),
                    ),
                    _drawerSection('COMUNIDAD'),
                    _drawerItem(
                      icon: Icons.people_outline,
                      label: 'Amigos',
                      onTap: () => _openDrawerScreen(const FriendsScreen()),
                    ),
                    _drawerSection('TU ACTIVIDAD'),
                    _drawerItem(
                      icon: Icons.emoji_events_outlined,
                      label: 'Logros',
                      onTap: () => _openDrawerScreen(const AchievementsScreen()),
                    ),
                    _drawerItem(
                      icon: Icons.notifications_outlined,
                      label: 'Notificaciones',
                      onTap: () => _openDrawerScreen(const NotificationsScreen()),
                    ),
                    _drawerSection('CUENTA'),
                    _drawerItem(
                      icon: Icons.person_outline,
                      label: 'Mi perfil',
                      onTap: () => _openDrawerScreen(const ProfileScreen()),
                    ),
                    _drawerItem(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Administración',
                      onTap: _openAdmin,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _drawerItem(
                icon: Icons.logout,
                label: 'Cerrar sesión',
                onTap: () {
                  Navigator.pop(context);
                  AuthService().signOut();
                },
              ),
            ],
          ),
        ),
      ),
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
          IconButton(
            tooltip: 'Buscar',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      ),
      body: AsyncStreamBuilder<List<Seminario>>(
        streamFactory: firestore.getSeminarios,
        loadingMessage: 'Cargando seminarios...',
        builder: (context, allSeminarios) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildSeminarioList(
                allSeminarios.where((s) => _progressService.getProgress(s.id) > 0).toList(),
                _progressService,
                emptyMessage: 'Aún no has empezado ningún seminario',
              ),
              _buildSeminarioList(allSeminarios, _progressService),
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
            shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
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
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
