import 'package:flutter/material.dart';
import '../services/ranking_service.dart';
import '../services/friends_service.dart';
import '../widgets/async_stream_builder.dart';

class RankingScreen extends StatefulWidget {
  final String seminarioId;
  final String seminarioNombre;
  const RankingScreen({super.key, required this.seminarioId, required this.seminarioNombre});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  Future<List<Map<String, dynamic>>> _load() async {
    final friends = await FriendsService().getFriends().first;
    final friendUids = friends.map((f) => f.uid).toList();
    return RankingService().getRankingAmongFriends(
      seminarioId: widget.seminarioId,
      friendUids: friendUids,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ranking · ${widget.seminarioNombre}')),
      body: AsyncFutureBuilder<List<Map<String, dynamic>>>(
        key: ValueKey(widget.seminarioId),
        futureFactory: _load,
        loadingMessage: 'Cargando ranking...',
        builder: (context, ranking) {
          if (ranking.isEmpty) {
            return const Center(child: Text('Aún no hay puntajes entre tus amigos'));
          }
          return ListView.builder(
            itemCount: ranking.length,
            itemBuilder: (context, index) {
              final item = ranking[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: item['esYo'] == true
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  child: Text('${index + 1}'),
                ),
                title: Text(item['nombre']),
                subtitle: Text('${item['totalQuizzes']} quizzes completados'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item['promedio']}/100',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Text('promedio'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
