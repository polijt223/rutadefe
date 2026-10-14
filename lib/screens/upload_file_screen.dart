// file_picker's analyzer resolution fails on some Windows SDK setups.
// ignore_for_file: uri_does_not_exist, undefined_identifier

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class UploadFileScreen extends StatefulWidget {
  final String seminarioId;
  final String seccionId;

  const UploadFileScreen({
    super.key,
    required this.seminarioId,
    required this.seccionId,
  });

  @override
  State<UploadFileScreen> createState() => _UploadFileScreenState();
}

class _UploadFileScreenState extends State<UploadFileScreen> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
    );
    if (files.isEmpty) return;

    final file = files.single;
    final path = file.path;
    final extension = file.extension?.toLowerCase();
    if (path == null || extension == null) {
      _showMessage('No se pudo leer el archivo seleccionado.');
      return;
    }
    if (await File(path).length() > 25 * 1024 * 1024) {
      _showMessage('El archivo no puede superar 25 MB.');
      return;
    }

    setState(() => _uploading = true);
    final version = DateTime.now().microsecondsSinceEpoch.toString();
    final tipo = extension == 'pdf' ? 'pdf' : 'imagen';
    final storage = FirebaseStorage.instance;
    final storageRef = storage
        .ref()
        .child('seminarios/${widget.seminarioId}/secciones/${widget.seccionId}/$version-${file.name}');
    final contentType = switch (extension) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    try {
      await storageRef.putFile(File(path), SettableMetadata(contentType: contentType));
      final url = await storageRef.getDownloadURL();
      final sectionRef = FirebaseFirestore.instance
          .collection('seminarios')
          .doc(widget.seminarioId)
          .collection('secciones')
          .doc(widget.seccionId);
      final section = await sectionRef.get();
      final data = section.data() ?? <String, dynamic>{};
      final existing = data['archivos'] is List
          ? List<Map<String, dynamic>>.from(
              (data['archivos'] as List).map((item) => Map<String, dynamic>.from(item as Map)),
            )
          : <Map<String, dynamic>>[];
      final replaced = existing.where((item) => item['nombre'] == file.name).toList();
      final updated = existing.where((item) => item['nombre'] != file.name).toList()
        ..add({
          'nombre': file.name,
          'url': url,
          'tipo': tipo,
          'version': version,
        });

      await sectionRef.set({'archivos': updated}, SetOptions(merge: true));

      for (final old in replaced) {
        final oldUrl = old['url'];
        if (oldUrl is String && oldUrl.isNotEmpty) {
          try {
            await storage.refFromURL(oldUrl).delete();
          } catch (_) {}
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material publicado')));
        Navigator.pop(context);
      }
    } catch (error) {
      try {
        await storageRef.delete();
      } catch (_) {}
      _showMessage('No se pudo publicar el material: $error');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showMessage(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subir material')),
      body: Center(
        child: _uploading
            ? const CircularProgressIndicator()
            : FilledButton.icon(
                onPressed: _pickAndUpload,
                icon: const Icon(Icons.upload_file),
                label: const Text('Seleccionar PDF o imagen'),
              ),
      ),
    );
  }
}