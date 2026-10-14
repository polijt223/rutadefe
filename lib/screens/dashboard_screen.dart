import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/seminario.dart';
import '../services/progress_service.dart';
import '../theme/app_layout.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/glass_panel.dart';
import 'achievements_screen.dart';
import 'friends_screen.dart';
import 'search_screen.dart';
import 'seminario_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  final List<Seminario> seminarios;
  final ProgressService progressService;
  final int streak;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenSeminars;

  const DashboardScreen({
    super.key,
    required this.seminarios,
    required this.progressService,
    required this.streak,
    required this.onOpenMenu,
    required this.onOpenSeminars,
  });

  String get _firstName {
    try {
      final name = FirebaseAuth.instance.currentUser?.displayName?.trim();
      if (name == null || name.isEmpty) return 'peregrino';
      return name.split(' ').first;
    } catch (_) {
      return 'peregrino';
    }
  }

  Seminario? get _current {
    Seminario? inProgress;
    Seminario? notStarted;
    for (final seminar in seminarios) {
      final progress = progressService.getProgress(seminar.id);
      if (progress > 0 && progress < 1) {
        inProgress ??= seminar;
      } else if (progress == 0) {
        notStarted ??= seminar;
      }
    }
    return inProgress ?? notStarted ?? (seminarios.isEmpty ? null : seminarios.first);
  }

  int get _xp {
    var total = 0;
    for (final seminar in seminarios) {
      total += (progressService.getProgress(seminar.id) * 120).round();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final current = _current;
    final currentProgress = current == null ? 0.0 : progressService.getProgress(current.id);
    final completed = seminarios.where((s) => progressService.getProgress(s.id) >= 1).length;
    final level = 1 + (_xp ~/ 400);
    final levelProgress = (_xp % 400) / 400;
    final padding = AppLayout.pagePadding(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(dark ? 'assets/home/bg_dark.jpg' : 'assets/home/bg_light.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: padding.copyWith(bottom: 24),
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: dark ? const Color(0x66FFFFFF) : const Color(0x99FFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      tooltip: 'Menú',
                      onPressed: onOpenMenu,
                      icon: Icon(
                        Icons.menu,
                        color: dark ? Colors.white : AppTheme.olive,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const BrandLogo(height: 40),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              child: Text(
                '¡Hola,\n$_firstName!',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      color: dark ? Colors.white : const Color(0xFF3F4A24),
                    ),
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: 40,
              child: SizedBox(
                height: 112,
                child: Row(
                  children: [
                    Expanded(
                      child: GlassPanel(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        child: _StatChip(
                          icon: Icons.local_fire_department,
                          value: '$streak',
                          label: streak == 1 ? 'día racha' : 'días racha',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassPanel(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        child: _StatChip(
                          icon: Icons.auto_awesome,
                          value: '$_xp',
                          label: 'XP camino',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassPanel(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        child: SizedBox.expand(
                          child: CustomPaint(
                            painter: _LevelRingPainter(
                              progress: levelProgress,
                              color: AppTheme.gold,
                              track: const Color(0x55FFFFFF),
                            ),
                            child: Center(
                              child: Text(
                                'Nivel\n$level',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, height: 1.15),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: 80,
              child: GlassPanel(
                onTap: current == null
                    ? onOpenSeminars
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SeminarioDetailScreen(seminario: current),
                          ),
                        ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/home/tile_continue.jpg',
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seminario actual',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            current?.nombre ?? 'Aún no hay seminarios',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, height: 1.2),
                          ),
                          if (current != null) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: currentProgress,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentProgress >= 1
                                  ? 'Completado · $completed en total'
                                  : '${(currentProgress * 100).toStringAsFixed(0)}% de este camino',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: 120,
              child: SizedBox(
                height: 164,
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionTile(
                        image: 'assets/home/tile_continue.jpg',
                        label: 'Seguir el camino',
                        onTap: current == null
                            ? onOpenSeminars
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SeminarioDetailScreen(seminario: current),
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionTile(
                        image: 'assets/home/tile_friends.jpg',
                        label: 'Caminar con amigos',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FriendsScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionTile(
                        image: 'assets/home/tile_explore.jpg',
                        label: 'Explorar tesoros',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SearchScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: 180,
              child: GlassPanel(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AchievementsScreen()),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: AppTheme.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        completed == 0
                            ? 'Todavía no completas un seminario. El primer logro te espera.'
                            : 'Llevas $completed seminario${completed == 1 ? '' : 's'} terminado${completed == 1 ? '' : 's'}.',
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatChip({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppTheme.gold),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String image;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({required this.image, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      alignment: Alignment.center,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(image, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, height: 1.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  _LevelRingPainter({required this.progress, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 5;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..shader = SweepGradient(colors: [color.withValues(alpha: 0.2), color]).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57,
      6.2832 * progress.clamp(0.04, 1),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LevelRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
