import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_config_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Administrador')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Gestión de contenido', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _AdminTile(
            icon: Icons.edit,
            title: 'Editar / Eliminar Seminarios',
            subtitle: 'Modificar o borrar seminarios existentes',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditSeminariosScreen())),
          ),
          _AdminTile(
            icon: Icons.library_books,
            title: 'Gestionar Secciones',
            subtitle: 'Agregar texto, YouTube, PDFs y quizzes',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageSeccionesScreen())),
          ),
          _AdminTile(
            icon: Icons.notifications_active,
            title: 'Mini-reflexiones',
            subtitle: 'Bolsa de notificaciones por seminario',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageReflexionesScreen())),
          ),
          _AdminTile(
            icon: Icons.workspace_premium,
            title: 'Certificados',
            subtitle: 'Información sobre generación automática',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CertificateConfigScreen())),
          ),
          const SizedBox(height: 24),
          const Text('Usuarios', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _AdminTile(
            icon: Icons.bar_chart,
            title: 'Progreso de usuarios',
            subtitle: 'Ver avance por seminario',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProgressScreen())),
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _AdminTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class CreateSeminarioScreen extends StatefulWidget {
  const CreateSeminarioScreen({super.key});
  @override
  State<CreateSeminarioScreen> createState() => _CreateSeminarioScreenState();
}

class _CreateSeminarioScreenState extends State<CreateSeminarioScreen> {
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();

  Future<void> _crear() async {
    if (_nombre.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('seminarios').add({
      'nombre': _nombre.text.trim(),
      'descripcion': _descripcion.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Seminario')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nombre, decoration: const InputDecoration(labelText: 'Nombre')),
            const SizedBox(height: 12),
            TextField(controller: _descripcion, decoration: const InputDecoration(labelText: 'Descripción'), maxLines: 3),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _crear, child: const Text('Crear')),
          ],
        ),
      ),
    );
  }
}

class ManageSeccionesScreen extends StatefulWidget {
  const ManageSeccionesScreen({super.key});
  @override
  State<ManageSeccionesScreen> createState() => _ManageSeccionesScreenState();
}

class _ManageSeccionesScreenState extends State<ManageSeccionesScreen> {
  String? _seminarioId;
  final _titulo = TextEditingController();
  final _contenido = TextEditingController();
  final _youtube = TextEditingController();

  Future<void> _agregarSeccion() async {
    if (_seminarioId == null || _titulo.text.trim().isEmpty) return;
    await FirebaseFirestore.instance
        .collection('seminarios')
        .doc(_seminarioId)
        .collection('secciones')
        .add({
      'titulo': _titulo.text.trim(),
      'contenidoTexto': _contenido.text.trim(),
      'youtubeUrl': _youtube.text.trim().isEmpty ? null : _youtube.text.trim(),
      'orden': DateTime.now().millisecondsSinceEpoch,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _titulo.clear();
    _contenido.clear();
    _youtube.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sección creada')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Secciones')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('seminarios').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final docs = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _seminarioId,
                  hint: const Text('Selecciona un seminario'),
                  items: docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return DropdownMenuItem(value: d.id, child: Text(data['nombre'] ?? d.id));
                  }).toList(),
                  onChanged: (v) => setState(() => _seminarioId = v),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(controller: _titulo, decoration: const InputDecoration(labelText: 'Título de la sección')),
            const SizedBox(height: 12),
            TextField(
              controller: _contenido,
              decoration: const InputDecoration(labelText: 'Contenido / texto'),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _youtube,
              decoration: const InputDecoration(labelText: 'Link de YouTube (opcional)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _agregarSeccion, child: const Text('Agregar sección')),
          ],
        ),
      ),
    );
  }
}

class ManageReflexionesScreen extends StatefulWidget {
  const ManageReflexionesScreen({super.key});
  @override
  State<ManageReflexionesScreen> createState() => _ManageReflexionesScreenState();
}

class _ManageReflexionesScreenState extends State<ManageReflexionesScreen> {
  String? _seminarioId;
  final _texto = TextEditingController();

  Future<void> _agregar() async {
    if (_seminarioId == null || _texto.text.trim().isEmpty) return;
    await FirebaseFirestore.instance
        .collection('seminarios')
        .doc(_seminarioId)
        .collection('mini_reflexiones')
        .add({
      'texto': _texto.text.trim(),
      'orden': DateTime.now().millisecondsSinceEpoch,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _texto.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reflexión agregada')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mini-reflexiones')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('seminarios').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final docs = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _seminarioId,
                  hint: const Text('Selecciona un seminario'),
                  items: docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return DropdownMenuItem(value: d.id, child: Text(data['nombre'] ?? d.id));
                  }).toList(),
                  onChanged: (v) => setState(() => _seminarioId = v),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _texto,
              decoration: const InputDecoration(labelText: 'Texto de la mini-reflexión'),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _agregar, child: const Text('Agregar reflexión')),
          ],
        ),
      ),
    );
  }
}

class CertificateConfigScreen extends StatelessWidget {
  const CertificateConfigScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Certificados')),
      body: const Center(child: Text('Los certificados se generan automáticamente al completar un seminario.')),
    );
  }
}

class UserProgressScreen extends StatelessWidget {
  const UserProgressScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progreso de usuarios')),
      body: const Center(child: Text('Pantalla de progreso (en desarrollo)')),
    );
  }
}

class EditSeminariosScreen extends StatelessWidget {
  const EditSeminariosScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Seminarios')),
      body: const Center(child: Text('Pantalla de edición (en desarrollo)')),
    );
  }
}