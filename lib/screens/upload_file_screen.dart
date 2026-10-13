import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UploadFileScreen extends StatefulWidget {
  final String seminarioId;
  final String seccionId;
  const UploadFileScreen({super.key, required this.seminarioId, required this.seccionId});

  @override
  State<UploadFileScreen> createState() => _UploadFileScreenState();
}

class _UploadFileScreenState extends State<UploadFileScreen> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery); // Para demo; se puede extender a PDF/audio
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('seminarios/${widget.seminarioId}/secciones/${widget.seccionId}/${file.name}');
      await ref.putFile(File(file.path));
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('seminarios')
          .doc(widget.seminarioId)
          .collection('secciones')
          .doc(widget.seccionId)
          .collection('archivos')
          .add({
        'nombre': file.name,
        'url': url,
        'tipo': 'imagen',
        'version': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Archivo subido')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subir archivo')),
      body: Center(
        child: _uploading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                onPressed: _pickAndUpload,
                icon: const Icon(Icons.upload),
                label: const Text('Seleccionar y subir archivo'),
              ),
      ),
    );
  }
}
