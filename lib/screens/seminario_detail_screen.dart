import 'package:flutter/material.dart';
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

class SeminarioDetailScreen extends StatefulWidget {
  final Seminario seminario;
  const SeminarioDetailScreen({super.key, required this.seminario});

  @override
  State<SeminarioDetailScreen> createState() => _SeminarioDetailScreenState();
}

class _SeminarioDetailScreenState extends State<SeminarioDetailScreen> {
  final _progressService = ProgressService();
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<Map<String, bool>> _checkNotes(String seccionId) async {
    final myNote = await NotesService().getMyNote(seccionId);
    final friends = await FriendsService().getFriends().first;
    final friendsNotes = await NotesService().getFriendsNotes(
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

  Future<void> _markCompleted() async {
    await _progressService.setProgress(widget.seminario.id, 1.0);
    await StreakService().recordActivity();
    setState(() => _progress = 1.0);
    if (mounted) {
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
      appBar: AppBar(title: Text(widget.seminario.nombre)),
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
                ] else ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _markCompleted,
                    child: const Text('Marcar como completado'),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Seccion>>(
              stream: firestore.getSecciones(widget.seminario.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final secciones = snapshot.data!;
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
