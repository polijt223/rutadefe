import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationConfigScreen extends StatefulWidget {
  const NotificationConfigScreen({super.key});
  @override
  State<NotificationConfigScreen> createState() => _NotificationConfigScreenState();
}

class _NotificationConfigScreenState extends State<NotificationConfigScreen> {
  String? _seminarioId;
  String _frecuencia = '6h';

  Future<void> _guardar() async {
    if (_seminarioId == null) return;
    await FirebaseFirestore.instance.collection('seminarios').doc(_seminarioId).update({
      'frecuenciaNotificacion': _frecuencia,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Frecuencia guardada')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar notificaciones')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('seminarios').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                return DropdownButtonFormField<String>(
                  value: _seminarioId,
                  hint: const Text('Selecciona seminario'),
                  items: snapshot.data!.docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return DropdownMenuItem(value: d.id, child: Text(data['nombre'] ?? d.id));
                  }).toList(),
                  onChanged: (v) => setState(() => _seminarioId = v),
                );
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _frecuencia,
              items: const [
                DropdownMenuItem(value: '1h', child: Text('Cada 1 hora')),
                DropdownMenuItem(value: '6h', child: Text('Cada 6 horas')),
                DropdownMenuItem(value: '12h', child: Text('Cada 12 horas')),
              ],
              onChanged: (v) => setState(() => _frecuencia = v ?? '6h'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _guardar, child: const Text('Guardar frecuencia')),
            const SizedBox(height: 24),
            const Text(
              'Nota: La frecuencia se guarda en el seminario. '
              'Las Cloud Functions deben leer este valor para enviar las notificaciones.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
