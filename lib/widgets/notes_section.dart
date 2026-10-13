import 'package:flutter/material.dart';
import '../services/notes_service.dart';
import '../services/friends_service.dart';

class NotesSection extends StatefulWidget {
  final String seccionId;
  final String seminarioId;
  const NotesSection({super.key, required this.seccionId, required this.seminarioId});

  @override
  State<NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<NotesSection> {
  final _controller = TextEditingController();
  String? _myNote;
  List<Map<String, dynamic>> _friendsNotes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final my = await NotesService().getMyNote(widget.seccionId);
    final friends = await FriendsService().getFriends().first;
    final friendNotes = await NotesService().getFriendsNotes(
      seccionId: widget.seccionId,
      friendUids: friends.map((f) => f.uid).toList(),
    );
    if (mounted) {
      setState(() {
        _myNote = my;
        _controller.text = my ?? '';
        _friendsNotes = friendNotes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mis notas', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Escribe tus notas de esta sección...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) async {
            await NotesService().saveNote(
              seccionId: widget.seccionId,
              seminarioId: widget.seminarioId,
              texto: v,
            );
            setState(() => _myNote = v);
          },
        ),
        const SizedBox(height: 16),
        if (_friendsNotes.isNotEmpty) ...[
          const Text('Notas de amigos', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._friendsNotes.map((n) => Card(
                child: ListTile(
                  title: Text(n['nombre'] ?? ''),
                  subtitle: Text(n['texto'] ?? ''),
                ),
              )),
        ],
      ],
    );
  }
}
