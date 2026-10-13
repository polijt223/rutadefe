import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/seminario.dart';
import '../services/firestore_service.dart';
import '../services/progress_service.dart';
import '../services/certificate_service.dart';
import '../models/seccion.dart';
import 'content_viewer_screen.dart';
import '../widgets/celebration_dialog.dart';
import '../services/streak_service.dart';
import '../services/notes_service.dart';
import '../services/section_cooldown_service.dart';
import '../services/friends_service.dart';
import '../widgets/async_stream_builder.dart';
import 'ranking_screen.dart';

class SeminarioDetailScreen extends StatefulWidget {
  final Seminario seminario;
  const SeminarioDetailScreen({super.key, required this.seminario});

  @override
  State<SeminarioDetailScreen> createState() => _SeminarioDetailScreenState();
}

class _SeminarioDetailScreenState extends State<SeminarioDetailScreen> {
  final _progressService = ProgressService();
  double _progress = 0;
  bool _notificationsEnabled = false;
  bool _savingNotificationPreference = false;
  String _notificationFrequency = '6h';

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    try {
      final preference = await FirestoreService().getNotificationPreference(widget.seminario.id);
      if (!mounted) return;
      setState(() {
        _notificationsEnabled = preference?['enabled'] == true;
        _notificationFrequency = preference?['frequency'] ?? '6h';
      });
    } catch (_) {}
  }

  Future<void> _saveNotificationPreference({bool? enabled, String? frequency}) async {
    setState(() => _savingNotificationPreference = true);
    final nextEnabled = enabled ?? _notificationsEnabled;
    final nextFrequency = frequency ?? _notificationFrequency;
    try {
      await FirestoreService().setNotificationPreference(
        seminarioId: widget.seminario.id,
        enabled: nextEnabled,
        frequency: nextFrequency,
      );
      if (mounted) {
        setState(() {
          _notificationsEnabled = nextEnabled;
          _notificationFrequency = nextFrequency;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la preferencia: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingNotificationPreference = false);
    }
  }

  Future<Map<String, bool>> _checkNotes(String seccionId) async {
    final myNote = await NotesService().getMyNote(
      seminarioId: widget.seminario.id,
      seccionId: seccionId,
    );
    final friends = await FriendsService().getFriends().first;
    final friendsNotes = await NotesService().getFriendsNotes(
      seminarioId: widget.seminario.id,
      seccionId: seccionId,
      friendUids: friends.map((f) => f.uid).toList(),
    );
    return {
      'my': myNote != null && myNote.isNotEmpty,
      'friends': friendsNotes.isNotEmpty,
    };
  }

  Future<void> _loadProgress() async {
    final p = await _progressService.getProgressAsync(widget.seminario.id);
    setState(() => _progress = p);
  }

  Future<void> _toggleSectionCompleted({
    required String seccionId,
    required int totalSections,
    required bool currentlyCompleted,
  }) async {
    final progress = await _progressService.setSectionCompleted(
      seminarioId: widget.seminario.id,
      seccionId: seccionId,
      totalSections: totalSections,
      completed: !currentlyCompleted,
    );
    if (!mounted) return;
    setState(() => _progress = progress);
    if (progress >= 1.0 && !currentlyCompleted) {
      await StreakService().recordActivity();
      if (!mounted) return;
      showCelebration(
        context,
        '¡Seminario completado!',
        'Has terminado "${widget.seminario.nombre}". ¡Tu certificado está listo!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.seminario.nombre),
        actions: [
          IconButton(
            tooltip: 'Ranking entre amigos',
            icon: const Icon(Icons.leaderboard_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RankingScreen(
                  seminarioId: widget.seminario.id,
                  seminarioNombre: widget.seminario.nombre,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: _progress, minHeight: 8),
                const SizedBox(height: 8),
                Text('${(_progress * 100).toStringAsFixed(0)}% completado'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Recibir reflexiones'),
                  subtitle: const Text('Solo de este seminario'),
                  value: _notificationsEnabled,
                  onChanged: _savingNotificationPreference
                      ? null
                      : (enabled) => _saveNotificationPreference(enabled: enabled),
                ),
                if (_notificationsEnabled)
                  Row(
                    children: [
                      const Expanded(child: Text('Frecuencia')),
                      DropdownButton<String>(
                        value: _notificationFrequency,
                        items: const [
                          DropdownMenuItem(value: '1h', child: Text('Cada hora')),
                          DropdownMenuItem(value: '6h', child: Text('Cada 6 horas')),
                          DropdownMenuItem(value: '12h', child: Text('Cada 12 horas')),
                        ],
                        onChanged: _savingNotificationPreference
                            ? null
                            : (frequency) {
                                if (frequency != null) {
                                  _saveNotificationPreference(frequency: frequency);
                                }
                              },
                      ),
                    ],
                  ),
                if (_progress >= 1.0) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      CertificateService.generateAndShare(
                        userName: user?.displayName ?? 'Usuario',
                        seminarioName: widget.seminario.nombre,
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Descargar certificado'),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: AsyncStreamBuilder<List<Seccion>>(
              streamFactory: () => firestore.getSecciones(widget.seminario.id),
              loadingMessage: 'Cargando secciones...',
              builder: (context, secciones) {
                if (secciones.isEmpty) {
                  return const Center(child: Text('Este seminario todavía no tiene secciones'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: secciones.length,
                  itemBuilder: (context, index) {
                    final sec = secciones[index];
                    return Card(
                      child: FutureBuilder<Map<String, bool>>(
                        future: _checkNotes(sec.id),
                        builder: (context, noteSnap) {
                          final hasMyNotes = noteSnap.data?['my'] ?? false;
                          final hasFriendsNotes = noteSnap.data?['friends'] ?? false;
                          return ListTile(
                            title: Text(sec.titulo),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasMyNotes)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(Icons.edit_note, size: 20, color: Colors.blue),
                                  ),
                                if (hasFriendsNotes)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(Icons.people, size: 20, color: Colors.green),
                                  ),
                                FutureBuilder<bool>(
                                  future: _progressService.isSectionCompleted(widget.seminario.id, sec.id),
                                  builder: (context, completionSnap) {
                                    final completed = completionSnap.data ?? false;
                                    return IconButton(
                                      tooltip: completed ? 'Marcar como pendiente' : 'Marcar sección completa',
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(
                                        completed ? Icons.check_circle : Icons.radio_button_unchecked,
                                        color: completed ? Colors.green : null,
                                      ),
                                      onPressed: () => _toggleSectionCompleted(
                                        seccionId: sec.id,
                                        totalSections: secciones.length,
                                        currentlyCompleted: completed,
                                      ),
                                    );
                                  },
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () async {
                              final cooldown = SectionCooldownService();
                              if (!await cooldown.canOpenSection()) {
                                final remaining = await cooldown.remainingTime();
                                final minutes = remaining.inMinutes;
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: const Duration(seconds: 6),
                                      content: Text(
                                        'Tómate un momento.\n'
                                        'El aprendizaje edificante necesita tiempo para asentarse.\n'
                                        'Descansa $minutes minutos y deja que lo que leíste madure en ti '
                                        'antes de continuar. No es una carrera.',
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }
                              await cooldown.markSectionOpened();
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ContentViewerScreen(
                                      seccion: sec,
                                      seminarioId: widget.seminario.id,
                                      totalSecciones: secciones.length,
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
