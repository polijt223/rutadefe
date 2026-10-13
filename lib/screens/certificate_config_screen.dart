import 'package:flutter/material.dart';

class CertificateConfigScreen extends StatelessWidget {
  const CertificateConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Certificados')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Los certificados se generan automáticamente cuando el usuario completa un seminario al 100%.\n\n'
          'El diseño actual incluye el nombre del seminario y del usuario.\n\n'
          'Si quieres personalizar el texto o el diseño del PDF, se puede ajustar en CertificateService.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
