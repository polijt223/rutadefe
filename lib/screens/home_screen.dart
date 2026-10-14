import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'dashboard_screen.dart';
import '../services/auth_service.dart';
import '../services/lock_ads_sync_service.dart';
import '../theme/app_layout.dart';
import '../theme/app_motion.dart';
import '../widgets/animated_indexed_stack.dart';
import '../widgets/async_stream_builder.dart';
import '../widgets/brand_loading_screen.dart';
import '../widgets/brand_logo.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/living_icon.dart';
import '../widgets/press_scale.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _progressService = ProgressService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  int _streak = 0;
  int _navIndex = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStreak();
    _loadProgress();
    unawaited(_loadAdmin());
    StreakService().recordActivity();
    unawaited(LockAdsSyncService().syncIfDue());
  }

  Future<void> _loadAdmin() async {
    try {
      final isAdmin = await FirestoreService().isAdmin();
      if (mounted) setState(() => _isAdmin = isAdmin);
    } catch (_) {
      if (mounted) setState(() => _isAdmin = false);
    }
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

  void _openAdmin() {
    if (!_isAdmin) return;
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
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
      color: colors.surface,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandLogo(height: 88),
          const SizedBox(height: 14),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.onSurface, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.72), fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.local_fire_department, size: 18, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                '$_streak ${_streak == 1 ? 'día' : 'días'} de racha',
                style: TextStyle(color: colors.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
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
      key: _scaffoldKey,
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
                      icon: Icons.home_outlined,
                      label: 'Inicio',
                      selected: _navIndex == 0,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _navIndex = 0);
                      },
                    ),
                    _drawerItem(
                      icon: Icons.menu_book_outlined,
                      label: 'Seminarios',
                      selected: _navIndex == 1,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _navIndex = 1);
                      },
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
                      selected: _navIndex == 2,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _navIndex = 2);
                      },
                    ),
                    if (_isAdmin)
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
      body: AsyncStreamBuilder<List<Seminario>>(
        streamFactory: firestore.getSeminarios,
        loadingBuilder: (_) => const BrandLoadingScreen(),
        builder: (context, allSeminarios) {
          return AnimatedIndexedStack(
            index: _navIndex,
            children: [
              DashboardScreen(
                seminarios: allSeminarios,
                progressService: _progressService,
                streak: _streak,
                onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
                onOpenSeminars: () => setState(() => _navIndex = 1),
              ),
              _buildSeminarsTab(allSeminarios),
              const ProfileScreen(),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        animationDuration: AppMotion.medium,
        onDestinationSelected: (index) {
          HapticFeedback.selectionClick();
          setState(() => _navIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: LivingIcon(icon: Icons.home_outlined, active: _navIndex == 0),
            selectedIcon: const LivingIcon(icon: Icons.home, active: true),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: LivingIcon(icon: Icons.menu_book_outlined, active: _navIndex == 1),
            selectedIcon: const LivingIcon(icon: Icons.menu_book, active: true),
            label: 'Seminarios',
          ),
          NavigationDestination(
            icon: LivingIcon(icon: Icons.person_outline, active: _navIndex == 2),
            selectedIcon: const LivingIcon(icon: Icons.person, active: true),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildSeminarsTab(List<Seminario> allSeminarios) {
    return Scaffold(
      primary: false,
      appBar: AppBar(
        title: const Text('Seminarios'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSeminarioList(
            allSeminarios.where((s) => _progressService.getProgress(s.id) > 0).toList(),
            _progressService,
            emptyMessage: 'Aún no has empezado ningún seminario',
          ),
          _buildSeminarioList(allSeminarios, _progressService),
        ],
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
    final columns = AppLayout.seminarColumns(context);
    final padding = AppLayout.pagePadding(context);
    if (columns == 1) {
      return ListView.builder(
        padding: padding,
        itemCount: seminarios.length,
        itemBuilder: (context, index) => FadeSlideIn(
          delay: AppMotion.staggered(index).inMilliseconds - 280,
          child: _SeminarioCard(seminario: seminarios[index], progress: progressService.getProgress(seminarios[index].id)),
        ),
      );
    }
    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: AppLayout.isWide(context) ? 1.7 : 1.45,
      ),
      itemCount: seminarios.length,
      itemBuilder: (context, index) => FadeSlideIn(
        delay: AppMotion.staggered(index).inMilliseconds - 280,
        child: _SeminarioCard(seminario: seminarios[index], progress: progressService.getProgress(seminarios[index].id)),
      ),
    );
  }
}

class _SeminarioCard extends StatelessWidget {
  final Seminario seminario;
  final double progress;
  const _SeminarioCard({required this.seminario, required this.progress});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: PressScale(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SeminarioDetailScreen(seminario: seminario)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: LivingIcon(
                      icon: Icons.menu_book,
                      size: 28,
                      color: colors.primary,
                      active: progress > 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(seminario.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          seminario.descripcion,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.onSurface.withValues(alpha: 0.68), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: colors.surfaceContainerHighest,
                color: colors.primary,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 6),
              Text('${(progress * 100).toStringAsFixed(0)}% completado', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
