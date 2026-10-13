import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/async_stream_builder.dart';

class EditSeminariosScreen extends StatelessWidget {
  const EditSeminariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Seminarios')),
      body: AsyncStreamBuilder<QuerySnapshot>(
        streamFactory: () => FirebaseFirestore.instance.collection('seminarios').snapshots(),
        loadingMessage: 'Cargando seminarios...',
        builder: (context, snapshot) {
          final docs = snapshot.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No hay seminarios para editar'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['nombre'] ?? ''),
                subtitle: Text(data['descripcion'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // Abrir formulario de edición simple
                        showDialog(
                          context: context,
                          builder: (ctx) {
                            final nombreCtrl = TextEditingController(text: data['nombre']);
                            final descCtrl = TextEditingController(text: data['descripcion']);
                            return AlertDialog(
                              title: const Text('Editar seminario'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción')),
                                ],
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                TextButton(
                                  onPressed: () async {
                                    await docs[i].reference.update({
                                      'nombre': nombreCtrl.text.trim(),
                                      'descripcion': descCtrl.text.trim(),
                                    });
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  },
                                  child: const Text('Guardar'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await docs[i].reference.delete();
                      },
                    ),
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
