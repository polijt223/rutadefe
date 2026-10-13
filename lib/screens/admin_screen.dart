import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'user_progress_screen.dart';
import 'upload_file_screen.dart';
import '../widgets/async_stream_builder.dart';

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
            icon: Icons.add_circle_outline,
            title: 'Crear seminario',
            subtitle: 'Publicar un nuevo seminario',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateSeminarioScreen())),
          ),
          _AdminTile(
            icon: Icons.edit,
            title: 'Editar seminarios',
            subtitle: 'Modificar o activar/desactivar contenido',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditSeminariosScreen())),
          ),
          _AdminTile(
            icon: Icons.library_books,
            title: 'Gestionar Secciones',
            subtitle: 'Agregar contenido, materiales y quizzes',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageSeccionesScreen())),
          ),
          _AdminTile(
            icon: Icons.security_outlined,
            title: 'Proteger quizzes existentes',
            subtitle: 'Mover respuestas correctas fuera de los documentos públicos',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MigrateQuizKeysScreen()),
            ),
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
      'activo': true,
      'creadoEn': FieldValue.serverTimestamp(),
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
            AsyncStreamBuilder<QuerySnapshot>(
              streamFactory: () => FirebaseFirestore.instance.collection('seminarios').snapshots(),
              loadingMessage: 'Cargando seminarios...',
              builder: (context, snapshot) {
                final docs = snapshot.docs;
                return DropdownButtonFormField<String>(
                  initialValue: _seminarioId,
                  hint: Text(docs.isEmpty ? 'No hay seminarios disponibles' : 'Selecciona un seminario'),
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
            if (_seminarioId == null)
              const Expanded(child: Center(child: Text('Selecciona un seminario para ver sus secciones')))
            else
              Expanded(
                child: AsyncStreamBuilder<QuerySnapshot>(
                  key: ValueKey(_seminarioId),
                  streamFactory: () => FirebaseFirestore.instance
                      .collection('seminarios')
                      .doc(_seminarioId)
                      .collection('secciones')
                      .orderBy('orden')
                      .snapshots(),
                  loadingMessage: 'Cargando secciones...',
                  builder: (context, snapshot) {
                    if (snapshot.docs.isEmpty) {
                      return const Center(child: Text('Todavía no hay secciones'));
                    }
                    return ListView.builder(
                      itemCount: snapshot.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(data['titulo'] ?? 'Sección'),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: 'Crear quiz',
                                icon: const Icon(Icons.quiz_outlined),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CreateQuizScreen(
                                      seminarioId: _seminarioId!,
                                      seccionId: doc.id,
                                      seccionTitulo: data['titulo'] ?? 'Sección',
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Subir material',
                                icon: const Icon(Icons.upload_file_outlined),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UploadFileScreen(
                                      seminarioId: _seminarioId!,
                                      seccionId: doc.id,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CreateQuizScreen extends StatefulWidget {
  final String seminarioId;
  final String seccionId;
  final String seccionTitulo;

  const CreateQuizScreen({
    super.key,
    required this.seminarioId,
    required this.seccionId,
    required this.seccionTitulo,
  });

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _titulo = TextEditingController();
  final _pregunta = TextEditingController();
  final _opciones = TextEditingController();
  final _respuestaCorrecta = TextEditingController();
  bool _multiple = true;
  bool _saving = false;
  int _savedQuestions = 0;

  @override
  void dispose() {
    _titulo.dispose();
    _pregunta.dispose();
    _opciones.dispose();
    _respuestaCorrecta.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titulo.text.trim().isEmpty || _pregunta.text.trim().isEmpty) return;
    final options = _opciones.text
        .split('\n')
        .map((option) => option.trim())
        .where((option) => option.isNotEmpty)
        .toList();
    final answer = _respuestaCorrecta.text.trim();
    if (_multiple && (options.length < 2 || !options.contains(answer))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega dos opciones o más y marca una como respuesta correcta.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
        final quizCollection = FirebaseFirestore.instance
          .collection('seminarios')
          .doc(widget.seminarioId)
          .collection('secciones')
          .doc(widget.seccionId)
          .collection('quiz');
        final existingQuizzes = await quizCollection.limit(1).get();
        final quiz = existingQuizzes.docs.isEmpty
          ? quizCollection.doc()
          : existingQuizzes.docs.first.reference;
        await quiz.set(
        {'seccionId': widget.seccionId, 'titulo': _titulo.text.trim()},
        SetOptions(merge: true),
        );
      final question = await quiz.collection('preguntas').add({
        'tipo': _multiple ? 'multiple' : 'abierta',
        'enunciado': _pregunta.text.trim(),
        'opciones': _multiple ? options : <String>[],
      });
      if (_multiple) {
        await question.collection('respuestas').doc('clave').set({'respuestaCorrecta': answer});
      }
      if (mounted) {
        setState(() {
          _savedQuestions++;
          _pregunta.clear();
          _opciones.clear();
          _respuestaCorrecta.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pregunta agregada. Preguntas nuevas: $_savedQuestions')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el quiz: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz · ${widget.seccionTitulo}'),
        actions: [
          IconButton(
            tooltip: 'Terminar edición',
            icon: const Icon(Icons.done),
            onPressed: _saving ? null : () => Navigator.pop(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _titulo, decoration: const InputDecoration(labelText: 'Título del quiz')),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Opción múltiple')),
              ButtonSegment(value: false, label: Text('Respuesta abierta')),
            ],
            selected: {_multiple},
            onSelectionChanged: (selection) => setState(() => _multiple = selection.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pregunta,
            decoration: const InputDecoration(labelText: 'Pregunta'),
            maxLines: 3,
          ),
          if (_multiple) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _opciones,
              decoration: const InputDecoration(labelText: 'Opciones, una por línea'),
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _respuestaCorrecta,
              decoration: const InputDecoration(labelText: 'Respuesta correcta exacta'),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: const Text('Agregar pregunta'),
          ),
        ],
      ),
    );
  }
}

class MigrateQuizKeysScreen extends StatefulWidget {
  const MigrateQuizKeysScreen({super.key});

  @override
  State<MigrateQuizKeysScreen> createState() => _MigrateQuizKeysScreenState();
}

class _MigrateQuizKeysScreenState extends State<MigrateQuizKeysScreen> {
  bool _migrating = false;
  int? _migrated;

  Future<void> _migrate() async {
    setState(() => _migrating = true);
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('migrateQuizAnswerKeys')
          .call<Map<String, dynamic>>();
      if (mounted) setState(() => _migrated = result.data['migrated'] as int? ?? 0);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudieron proteger los quizzes: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _migrating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proteger quizzes')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Mueve las respuestas correctas legacy a una ruta que los usuarios no pueden leer.',
                textAlign: TextAlign.center,
              ),
              if (_migrated != null) ...[
                const SizedBox(height: 12),
                Text('Preguntas protegidas: $_migrated'),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _migrating ? null : _migrate,
                icon: _migrating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.lock_outline),
                label: const Text('Migrar respuestas'),
              ),
            ],
          ),
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
        .collection('miniReflexiones')
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
            AsyncStreamBuilder<QuerySnapshot>(
              streamFactory: () => FirebaseFirestore.instance.collection('seminarios').snapshots(),
              loadingMessage: 'Cargando seminarios...',
              builder: (context, snapshot) {
                final docs = snapshot.docs;
                return DropdownButtonFormField<String>(
                  initialValue: _seminarioId,
                  hint: Text(docs.isEmpty ? 'No hay seminarios disponibles' : 'Selecciona un seminario'),
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

class EditSeminariosScreen extends StatelessWidget {
  const EditSeminariosScreen({super.key});

  Future<void> _editSeminario(BuildContext context, DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final nombreController = TextEditingController(text: data['nombre'] ?? '');
    final descripcionController = TextEditingController(text: data['descripcion'] ?? '');

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar seminario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreController, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(
              controller: descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Guardar')),
        ],
      ),
    );

    if (save == true && nombreController.text.trim().isNotEmpty) {
      await doc.reference.update({
        'nombre': nombreController.text.trim(),
        'descripcion': descripcionController.text.trim(),
      });
    }
    nombreController.dispose();
    descripcionController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar seminarios')),
      body: AsyncStreamBuilder<QuerySnapshot>(
        streamFactory: () => FirebaseFirestore.instance
            .collection('seminarios')
            .snapshots(),
        loadingMessage: 'Cargando seminarios...',
        builder: (context, snapshot) {
          if (snapshot.docs.isEmpty) {
            return const Center(child: Text('Todavía no hay seminarios'));
          }
          return ListView.builder(
            itemCount: snapshot.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['nombre'] ?? 'Sin nombre'),
                subtitle: Text(data['descripcion'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Editar seminario',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editSeminario(context, doc),
                    ),
                    Switch(
                      value: data['activo'] != false,
                      onChanged: (active) => doc.reference.update({'activo': active}),
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