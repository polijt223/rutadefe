import 'package:flutter/material.dart';
import '../services/ranking_service.dart';
import '../services/friends_service.dart';

class RankingScreen extends StatefulWidget {
  final String seminarioId;
  final String seminarioNombre;
  const RankingScreen({super.key, required this.seminarioId, required this.seminarioNombre});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<Map<String, dynamic>> _ranking = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final friends = await FriendsService().getFriends().first;
    final friendUids = friends.map((f) => f.uid).toList();
    final ranking = await RankingService().getRankingAmongFriends(
      seminarioId: widget.seminarioId,
      friendUids: friendUids,
    );
    if (mounted) {
      setState(() {
        _ranking = ranking;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ranking · ${widget.seminarioNombre}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _ranking.isEmpty
              ? const Center(child: Text('Aún no hay puntajes entre tus amigos'))
              : ListView.builder(
                  itemCount: _ranking.length,
                  itemBuilder: (context, index) {
                    final item = _ranking[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item['esYo'] == true
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(item['nombre']),
                      trailing: Text(
                        '${item['promedio']}/100',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    );
                  },
                ),
    );
  }
}
