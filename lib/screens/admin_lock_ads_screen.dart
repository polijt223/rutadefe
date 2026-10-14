// image_picker analyzer resolution fails on some Windows SDK setups.
// ignore_for_file: uri_does_not_exist, undefined_identifier, undefined_class

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/lock_ad.dart';
import '../services/lock_ads_admin_service.dart';
import '../widgets/async_stream_builder.dart';

class AdminLockAdsScreen extends StatefulWidget {
  const AdminLockAdsScreen({super.key});

  @override
  State<AdminLockAdsScreen> createState() => _AdminLockAdsScreenState();
}

class _AdminLockAdsScreenState extends State<AdminLockAdsScreen> {
  final _texto = TextEditingController();
  final _admin = LockAdsAdminService();
  File? _image;
  bool _saving = false;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _image = File(picked.path));
  }

  Future<void> _save() async {
    final image = _image;
    if (image == null || _texto.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega un texto y una imagen.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _admin.create(texto: _texto.text, image: image);
      _texto.clear();
      setState(() => _image = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anuncio de bloqueo publicado')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo publicar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anuncios de bloqueo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Cada aviso es una reflexión con imagen. Quien active la función la verá en la pantalla de bloqueo, rotando al desbloquear el teléfono.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _texto,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Consejo o reflexión'),
          ),
          const SizedBox(height: 12),
          if (_image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_image!, height: 180, fit: BoxFit.cover),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image_outlined),
            label: Text(_image == null ? 'Elegir imagen' : 'Cambiar imagen'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.publish_outlined),
            label: const Text('Publicar anuncio'),
          ),
          const SizedBox(height: 24),
          Text('Publicados', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          AsyncStreamBuilder<List<LockAd>>(
            streamFactory: _admin.watch,
            loadingMessage: 'Cargando anuncios...',
            builder: (context, ads) {
              if (ads.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Todavía no hay anuncios de bloqueo.'),
                );
              }
              return Column(
                children: ads
                    .map(
                      (ad) => Card(
                        child: ListTile(
                          leading: ad.imagenUrl.isEmpty
                              ? const Icon(Icons.image_not_supported_outlined)
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(ad.imagenUrl, width: 56, height: 56, fit: BoxFit.cover),
                                ),
                          title: Text(ad.texto, maxLines: 3, overflow: TextOverflow.ellipsis),
                          subtitle: Text(ad.activo ? 'Activo' : 'Pausado'),
                          trailing: Wrap(
                            children: [
                              Switch(
                                value: ad.activo,
                                onChanged: (value) => _admin.setActivo(ad.id, value),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _admin.delete(ad),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
