import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/notes_service.dart';
import '../models/seminario.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/seccion.dart';

enum SearchType { seminarios, secciones, notas, material }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  SearchType _type = SearchType.seminarios;
  List<dynamic> _results = [];
  bool _loading = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);

    final firestore = FirestoreService();
    List<dynamic> results = [];

    switch (_type) {
      case SearchType.seminarios:
        final all = await firestore.getSeminarios().first;
        results = all.where((s) =>
            s.nombre.toLowerCase().contains(query.toLowerCase()) ||
            s.descripcion.toLowerCase().contains(query.toLowerCase())).toList();
        break;
      case SearchType.secciones:
        // Búsqueda simple: recorre seminarios y sus secciones
        final seminarios = await firestore.getSeminarios().first;
        for (final s in seminarios) {
          final secciones = await firestore.getSecciones(s.id).first;
          results.addAll(secciones.where((sec) =>
              sec.titulo.toLowerCase().contains(query.toLowerCase())));
        }
        break;
      case SearchType.notas:
        // Busca dentro del texto de las notas del usuario
        final notesSnap = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('notas')
            .get();
        results = notesSnap.docs
            .where((d) => (d.data()['texto'] ?? '')
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .map((d) => {'id': d.id, 'texto': d.data()['texto'], 'seminarioId': d.data()['seminarioId']})
            .toList();
        break;
      case SearchType.material:
        results = [];
        break;
    }

    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar...',
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: SearchType.values.map((t) {
                final selected = _type == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_label(t)),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _type = t);
                      _search(_controller.text);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(child: Text('Sin resultados'))
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, i) {
                          final item = _results[i];
                          if (item is Seminario) {
                            return ListTile(
                              leading: const Icon(Icons.menu_book),
                              title: Text(item.nombre),
                              subtitle: Text(item.descripcion, maxLines: 1),
                            );
                          }
                          if (item is Map && item.containsKey('texto')) {
                            return ListTile(
                              leading: const Icon(Icons.note),
                              title: Text(item['texto'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                              subtitle: const Text('Nota personal'),
                            );
                          }
                          return const ListTile(title: Text('Resultado'));
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _label(SearchType t) {
    switch (t) {
      case SearchType.seminarios: return 'Seminarios';
      case SearchType.secciones: return 'Secciones';
      case SearchType.notas: return 'Notas';
      case SearchType.material: return 'Material';
    }
  }
}
