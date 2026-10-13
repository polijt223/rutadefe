import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/async_stream_builder.dart';

class UserProgressScreen extends StatelessWidget {
  const UserProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progreso de usuarios')),
      body: AsyncStreamBuilder<QuerySnapshot>(
        streamFactory: () => FirebaseFirestore.instance.collection('usuarios').snapshots(),
        loadingMessage: 'Cargando usuarios...',
        builder: (context, snapshot) {
          final users = snapshot.docs;
          if (users.isEmpty) {
            return const Center(child: Text('No hay usuarios con progreso todavía'));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, i) {
              final userData = users[i].data() as Map<String, dynamic>;
              return ExpansionTile(
                title: Text(userData['displayName'] ?? users[i].id),
                subtitle: const Text('Ver progreso por seminario'),
                children: [
                  AsyncFutureBuilder<QuerySnapshot>(
                    key: ValueKey(users[i].id),
                    futureFactory: () => users[i].reference.collection('puntajes').get(),
                    loadingMessage: 'Cargando progreso...',
                    builder: (context, puntajeSnap) {
                      if (puntajeSnap.docs.isEmpty) {
                        return const ListTile(title: Text('Sin progreso registrado'));
                      }
                      return Column(
                        children: puntajeSnap.docs.map((p) {
                          final data = p.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text('Seminario: ${p.id}'),
                            subtitle: Text('Promedio: ${data['promedio'] ?? 0}/100'),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
