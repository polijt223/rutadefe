import 'package:flutter/material.dart';
import '../models/seccion.dart';
import '../services/local_cache_service.dart';
import '../models/quiz.dart';
import '../services/firestore_service.dart';
import '../theme/app_layout.dart';
import '../widgets/adaptive_body.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/notes_section.dart';
import '../widgets/section_youtube_player.dart';
import '../services/favorites_service.dart';
import 'material_viewer_screen.dart';
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
  String? _openingFile;

  Future<void> _openFile(ArchivoMaterial archivo) async {
    setState(() => _openingFile = archivo.nombre);
    try {
      final localPath = await LocalCacheService.getLocalPathIfUpToDate(
        fileId: '${widget.seccion.id}_${archivo.nombre}',
        remoteVersion: archivo.version,
      );

      final pathToOpen = localPath ??
          await LocalCacheService.downloadAndCache(
            fileId: '${widget.seccion.id}_${archivo.nombre}',
            seminarioId: widget.seminarioId,
            seccionId: widget.seccion.id,
            nombre: archivo.nombre,
            tipo: archivo.tipo,
            remoteUrl: archivo.url,
            remoteVersion: archivo.version,
          );

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MaterialViewerScreen(
            title: archivo.nombre,
            path: pathToOpen,
            isPdf: archivo.isPdf,
            isImage: archivo.isImage,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _openingFile = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seccion = widget.seccion;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(seccion.titulo),
        actions: [
          FutureBuilder<bool>(
            future: FavoritesService().isFavorite(seccion.id),
            builder: (context, snapshot) {
              final isFav = snapshot.data ?? false;
              return IconButton(
                tooltip: isFav ? 'Quitar de favoritos' : 'Guardar en favoritos',
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                onPressed: () async {
                  await FavoritesService().toggleFavorite(seccion.id);
                  setState(() {});
                },
              );
            },
          ),
        ],
      ),
      body: AdaptiveBody(
        maxWidth: 800,
        padded: false,
        child: ListView(
        padding: AppLayout.pagePadding(context),
        children: [
          if (_openingFile != null) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text('Preparando $_openingFile...'),
            const SizedBox(height: 16),
          ],
          if (seccion.contenidoTexto.isNotEmpty)
            FadeSlideIn(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    seccion.contenidoTexto,
                    style: const TextStyle(height: 1.45, fontSize: 16),
                  ),
                ),
              ),
            ),
          if (seccion.youtubeUrl != null && seccion.youtubeUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: 40,
              child: SectionYoutubePlayer(url: seccion.youtubeUrl!),
            ),
          ],
          const SizedBox(height: 20),
          Text('Materiales', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (seccion.archivos.isEmpty)
            Text(
              'Esta sección no tiene PDF ni imágenes descargables.',
              style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7)),
            )
          else
            ...seccion.archivos.map(
              (archivo) => FadeSlideIn(
                delay: 80,
                child: Card(
                  child: ListTile(
                    leading: Icon(
                      archivo.isPdf ? Icons.picture_as_pdf : Icons.image,
                      color: colors.primary,
                    ),
                    title: Text(archivo.nombre),
                    subtitle: Text('Versión ${archivo.version} · se abre en la app'),
                    trailing: const Icon(Icons.visibility),
                    onTap: _openingFile == null ? () => _openFile(archivo) : null,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          FutureBuilder<Quiz?>(
            future: FirestoreService().getQuiz(widget.seminarioId, seccion.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                );
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const SizedBox.shrink();
              }
              return FadeSlideIn(
                delay: 120,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
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
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          FadeSlideIn(
            delay: 160,
            child: NotesSection(
              seccionId: seccion.id,
              seminarioId: widget.seminarioId,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
