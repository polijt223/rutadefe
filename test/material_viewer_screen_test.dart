import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutadefe/screens/material_viewer_screen.dart';

final _pngBytes = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows an image file inside the app', (tester) async {
    final file = File('${Directory.systemTemp.path}/ruta_de_fe_test.png');
    await file.writeAsBytes(_pngBytes, flush: true);
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: MaterialViewerScreen(
          title: 'mapa.png',
          path: file.path,
          isPdf: false,
          isImage: true,
        ),
      ),
    );

    expect(find.text('mapa.png'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byTooltip('Abrir con otra app'), findsOneWidget);
  });

  testWidgets('offers a system app fallback for unknown files', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MaterialViewerScreen(
          title: 'notas.docx',
          path: 'missing.docx',
          isPdf: false,
          isImage: false,
        ),
      ),
    );

    expect(find.text('Este tipo de archivo se abre con una aplicación del sistema.'), findsOneWidget);
    expect(find.text('Abrir con otra app'), findsOneWidget);
  });
}
