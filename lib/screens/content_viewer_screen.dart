import 'package:flutter/material.dart';
import '../models/seccion.dart';
import '../services/local_cache_service.dart';
import 'package:open_file/open_file.dart';
import '../models/quiz.dart';
import '../services/firestore_service.dart';
import '../widgets/notes_section.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../services/favorites_service.dart';
import 'quiz_screen.dart';

class ContentViewerScreen extends StatefulWidget {
  final Seccion seccion;
  final String seminarioId;
  final int totalSecciones;
  const ContentViewerScreen({
    super.key,
    required this.seccion,
    required this.seminarioId,
    this.totalSecciones = 1,
  });

  @override
  State<ContentViewerScreen> createState() => _ContentViewerScreenState();
}

class _ContentViewerScreenState extends State<ContentViewerScreen> {
  bool _loading = false;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    if (widget.seccion.youtubeUrl != null && widget.seccion.youtubeUrl!.isNotEmpty) {
      final videoId = YoutubePlayerController.convertUrlToId(widget.seccion.youtubeUrl!);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: false,
        );
      }
    }
  }

  @override
  void dispose() {
    _youtubeController?.close();
    super.dispose();
  }

  Future<void> _openFile(ArchivoMaterial archivo) async {
    setState(() => _loading = true);
    try {
      final localPath = await LocalCacheService.getLocalPathIfUpToDate(
        fileId: '${widget.seccion.id}_${archivo.nombre}',
        remoteVersion: archivo.version,
      );

      String pathToOpen;
      if (localPath != null) {
        pathToOpen = localPath;
      } else {
        pathToOpen = await LocalCacheService.downloadAndCache(
          fileId: '${widget.seccion.id}_${archivo.nombre}',
          seminarioId: widget.seminarioId,
          seccionId: widget.seccion.id,
          nombre: archivo.nombre,
          tipo: archivo.tipo,
          remoteUrl: archivo.url,
          remoteVersion: archivo.version,
        );
      }

      await OpenFile.open(pathToOpen);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.seccion.titulo),
        actions: [
          FutureBuilder<bool>(
            future: FavoritesService().isFavorite(widget.seccion.id),
            builder: (context, snapshot) {
              final isFav = snapshot.data ?? false;
              return IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                onPressed: () async {
                  await FavoritesService().toggleFavorite(widget.seccion.id);
                  setState(() {});
                },
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.seccion.contenidoTexto.isNotEmpty)
                    Text(widget.seccion.contenidoTexto),
                  const SizedBox(height: 16),
                  if (_youtubeController != null)
                    YoutubePlayer(
                      controller: _youtubeController!,
                    ),
                  const SizedBox(height: 16),
                  FutureBuilder<Quiz?>(
                    future: FirestoreService().getQuiz(widget.seminarioId, widget.seccion.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const SizedBox.shrink();
                      }
                      return ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizScreen(
                              quiz: snapshot.data!,
                              seminarioId: widget.seminarioId,
                              totalSecciones: widget.totalSecciones,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.quiz),
                        label: const Text('Hacer el quiz de esta sección'),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  NotesSection(
                    seccionId: widget.seccion.id,
                    seminarioId: widget.seminarioId,
                  ),
                  const SizedBox(height: 16),
                  ...widget.seccion.archivos.map((archivo) => Card(
                        child: ListTile(
                          leading: Icon(
                            archivo.tipo == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                          ),
                          title: Text(archivo.nombre),
                          subtitle: Text('Versión ${archivo.version}'),
                          trailing: const Icon(Icons.download),
                          onTap: () => _openFile(archivo),
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}