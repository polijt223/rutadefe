import 'package:flutter/material.dart';
import '../models/friend.dart';
import '../services/friends_service.dart';
import '../widgets/async_stream_builder.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _codeController = TextEditingController();
  String _myCode = '';

  @override
  void initState() {
    super.initState();
    FriendsService().getMyFriendCode().then((c) {
      if (mounted) setState(() => _myCode = c);
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = FriendsService();
    return Scaffold(
      appBar: AppBar(title: const Text('Amigos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Tu código: $_myCode', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Código de amigo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final ok = await service.addFriendByCode(_codeController.text.trim());
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? 'Amigo agregado' : 'Código no válido')),
                    );
                  },
                  child: const Text('Agregar amigo'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: AsyncStreamBuilder<List<Friend>>(
              streamFactory: service.getFriends,
              loadingMessage: 'Cargando amigos...',
              builder: (context, friends) {
                if (friends.isEmpty) {
                  return const Center(child: Text('Aún no tienes amigos'));
                }
                return ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, i) {
                    final f = friends[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text(f.displayName[0])),
                      title: Text(f.displayName),
                      subtitle: const Text('Ver notas compartidas'),
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
