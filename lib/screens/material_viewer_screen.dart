import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:pdfx/pdfx.dart';

class MaterialViewerScreen extends StatefulWidget {
  final String title;
  final String path;
  final bool isPdf;
  final bool isImage;

  const MaterialViewerScreen({
    super.key,
    required this.title,
    required this.path,
    required this.isPdf,
    required this.isImage,
  });

  @override
  State<MaterialViewerScreen> createState() => _MaterialViewerScreenState();
}

class _MaterialViewerScreenState extends State<MaterialViewerScreen> {
  PdfControllerPinch? _pdfController;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isPdf) {
      try {
        _pdfController = PdfControllerPinch(
          document: PdfDocument.openFile(widget.path),
        );
      } catch (error) {
        _error = error.toString();
      }
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _openExternally() async {
    final result = await OpenFile.open(widget.path);
    if (!mounted) return;
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir con otra app: ${result.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Abrir con otra app',
            icon: const Icon(Icons.open_in_new),
            onPressed: _openExternally,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _Fallback(
        message: 'No se pudo mostrar el archivo aquí.',
        onOpenExternal: _openExternally,
      );
    }

    if (widget.isImage) {
      final file = File(widget.path);
      if (!file.existsSync()) {
        return _Fallback(
          message: 'El archivo local ya no está disponible.',
          onOpenExternal: _openExternally,
        );
      }
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Center(
          child: Image.file(file, fit: BoxFit.contain),
        ),
      );
    }

    if (widget.isPdf && _pdfController != null) {
      return PdfViewPinch(controller: _pdfController!);
    }

    return _Fallback(
      message: 'Este tipo de archivo se abre con una aplicación del sistema.',
      onOpenExternal: _openExternally,
    );
  }
}

class _Fallback extends StatelessWidget {
  final String message;
  final VoidCallback onOpenExternal;

  const _Fallback({required this.message, required this.onOpenExternal});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onOpenExternal,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir con otra app'),
            ),
          ],
        ),
      ),
    );
  }
}
