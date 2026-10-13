import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/seminario.dart';
import '../models/seccion.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/async_stream_builder.dart';
import 'content_viewer_screen.dart';
import 'seminario_detail_screen.dart';

enum SearchType { seminarios, secciones, notas, material }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  SearchType _type = SearchType.seminarios;
  String _query = '';

  void _search(String query) => setState(() => _query = query);

  Future<List<dynamic>> _performSearch(String query) async {
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
        final seminarios = await firestore.getSeminarios().first;
        for (final s in seminarios) {
          final secciones = await firestore.getSecciones(s.id).first;
          results.addAll(secciones
              .where((sec) => sec.titulo.toLowerCase().contains(query.toLowerCase()))
              .map((sec) => {'type': 'section', 'section': sec, 'seminarioId': s.id}));
        }
        break;
      case SearchType.notas:
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return [];
        final notesSnap = await FirebaseFirestore.instance
            .collectionGroup('notas')
            .where('uid', isEqualTo: uid)
            .get();
        final legacySnap = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .collection('notas')
            .get();
        final seen = <String>{};
        final matchingNotes = <Map<String, dynamic>>[];
        for (final note in [...notesSnap.docs, ...legacySnap.docs]) {
          final data = note.data();
          final text = (data['texto'] ?? '').toString();
          final seminarioId = data['seminarioId']?.toString();
          final seccionId = (data['seccionId'] ?? note.id).toString();
          final key = '$seminarioId/$seccionId';
          if (seminarioId == null || seen.contains(key) || !text.toLowerCase().contains(query.toLowerCase())) {
            continue;
          }
          seen.add(key);
          matchingNotes.add({
            'type': 'note',
            'id': note.id,
            'texto': text,
            'seminarioId': seminarioId,
            'seccionId': seccionId,
          });
        }
        results = matchingNotes;
        break;
      case SearchType.material:
        final seminarios = await firestore.getSeminarios().first;
        for (final seminario in seminarios) {
          final secciones = await firestore.getSecciones(seminario.id).first;
          for (final seccion in secciones) {
            results.addAll(seccion.archivos
                .where((archivo) => archivo.nombre.toLowerCase().contains(query.toLowerCase()))
                .map((archivo) => {
                      'type': 'material',
                      'archivo': archivo,
                      'section': seccion,
                      'seminarioId': seminario.id,
                    }));
          }
        }
        break;
    }
    return results;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openNote(Map<String, dynamic> item) async {
    final seminarioId = item['seminarioId'] as String?;
    final seccionId = item['seccionId'] as String?;
    if (seminarioId == null || seccionId == null) return;
    final sections = await FirestoreService().getSecciones(seminarioId).first;
    final matches = sections.where((section) => section.id == seccionId);
    if (!mounted || matches.isEmpty) return;
    _openContent(matches.first, seminarioId);
  }

  void _openContent(Seccion section, String seminarioId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContentViewerScreen(seccion: section, seminarioId: seminarioId),
      ),
    );
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
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _query.trim().isEmpty
                ? const Center(child: Text('Escribe para buscar'))
                : AsyncFutureBuilder<List<dynamic>>(
                    key: ValueKey('${_type.name}:$_query'),
                    futureFactory: () => _performSearch(_query),
                    loadingMessage: 'Buscando...',
                    builder: (context, results) {
                      if (results.isEmpty) {
                        return const Center(child: Text('Sin resultados'));
                      }
                      return ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, i) {
                          final item = results[i];
                          if (item is Seminario) {
                            return ListTile(
                              leading: const Icon(Icons.menu_book),
                              title: Text(item.nombre),
                              subtitle: Text(item.descripcion, maxLines: 1),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => SeminarioDetailScreen(seminario: item)),
                              ),
                            );
                          }
                          if (item is Map && item['type'] == 'section') {
                            final section = item['section'] as Seccion;
                            return ListTile(
                              leading: const Icon(Icons.menu_book_outlined),
                              title: Text(section.titulo),
                              subtitle: const Text('Sección'),
                              onTap: () => _openContent(section, item['seminarioId'] as String),
                            );
                          }
                          if (item is Map && item['type'] == 'material') {
                            final section = item['section'] as Seccion;
                            final file = item['archivo'] as ArchivoMaterial;
                            return ListTile(
                              leading: Icon(file.tipo == 'pdf' ? Icons.picture_as_pdf : Icons.image_outlined),
                              title: Text(file.nombre),
                              subtitle: Text('Material de ${section.titulo}'),
                              onTap: () => _openContent(section, item['seminarioId'] as String),
                            );
                          }
                          if (item is Map && item['type'] == 'note') {
                            return ListTile(
                              leading: const Icon(Icons.note),
                              title: Text(item['texto'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                              subtitle: const Text('Nota personal'),
                              onTap: () => _openNote(Map<String, dynamic>.from(item)),
                            );
                          }
                          return const ListTile(title: Text('Resultado'));
                        },
                      );
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
