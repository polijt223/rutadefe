import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProgressScreen extends StatelessWidget {
  const UserProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progreso de usuarios')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, i) {
              final userData = users[i].data() as Map<String, dynamic>;
              return ExpansionTile(
                title: Text(userData['displayName'] ?? users[i].id),
                subtitle: const Text('Ver progreso por seminario'),
                children: [
                  FutureBuilder<QuerySnapshot>(
                    future: users[i].reference.collection('puntajes').get(),
                    builder: (context, puntajeSnap) {
                      if (!puntajeSnap.hasData) return const SizedBox();
                      if (puntajeSnap.data!.docs.isEmpty) {
                        return const ListTile(title: Text('Sin progreso registrado'));
                      }
                      return Column(
                        children: puntajeSnap.data!.docs.map((p) {
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
