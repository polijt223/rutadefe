import 'package:flutter/material.dart';
import '../models/seminario.dart';
import '../services/firestore_service.dart';
import '../services/local_cache_service.dart';
import '../widgets/async_stream_builder.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: AsyncStreamBuilder<List<Seminario>>(
        streamFactory: firestore.getSeminarios,
        loadingMessage: 'Cargando seminarios...',
        builder: (context, seminarios) {
          if (seminarios.isEmpty) {
            return const Center(child: Text('No hay seminarios disponibles todavía'));
          }
          return ListView.builder(
            itemCount: seminarios.length,
            itemBuilder: (context, index) {
              final s = seminarios[index];
              return ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(s.nombre),
                subtitle: const Text('Ver historial de este seminario'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _SeminarioNotificationsDetail(seminarioId: s.id, nombre: s.nombre),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SeminarioNotificationsDetail extends StatelessWidget {
  final String seminarioId;
  final String nombre;
  const _SeminarioNotificationsDetail({required this.seminarioId, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nombre),
        actions: [
          TextButton(
            onPressed: () async {
              await FirestoreService().restartNotificationCycle(seminarioId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ciclo reiniciado. Seguirás recibiendo notificaciones.')),
                );
              }
            },
            child: const Text('Reiniciar ciclo'),
          ),
        ],
      ),
      body: AsyncFutureBuilder<List<Map<String, dynamic>>>(
        futureFactory: () => LocalCacheService.getHistoryForSeminario(seminarioId),
        loadingMessage: 'Cargando historial...',
        builder: (context, items) {
          if (items.isEmpty) {
            return const Center(child: Text('Aún no has recibido notificaciones de este seminario'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item['texto'] ?? ''),
                subtitle: Text(
                  DateTime.fromMillisecondsSinceEpoch(item['fechaRecepcion'] as int)
                      .toString()
                      .substring(0, 16),
                ),
                leading: item['imagenUrl'] != null
                    ? const Icon(Icons.image)
                    : const Icon(Icons.text_snippet),
              );
            },
          );
        },
      ),
    );
  }
}
