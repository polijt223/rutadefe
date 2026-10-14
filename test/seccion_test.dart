import 'package:flutter_test/flutter_test.dart';
import 'package:rutadefe/models/seccion.dart';

void main() {
  test('detects PDF materials by type or filename', () {
    expect(
      ArchivoMaterial(nombre: 'clase.pdf', url: '', tipo: 'pdf', version: '1').isPdf,
      isTrue,
    );
    expect(
      ArchivoMaterial(nombre: 'clase.PDF', url: '', tipo: 'archivo', version: '1').isPdf,
      isTrue,
    );
    expect(
      ArchivoMaterial(nombre: 'foto.png', url: '', tipo: 'imagen', version: '1').isPdf,
      isFalse,
    );
  });

  test('detects image materials by type or filename', () {
    expect(
      ArchivoMaterial(nombre: 'mapa', url: '', tipo: 'imagen', version: '1').isImage,
      isTrue,
    );
    expect(
      ArchivoMaterial(nombre: 'diagrama.WEBP', url: '', tipo: 'otro', version: '1').isImage,
      isTrue,
    );
    expect(
      ArchivoMaterial(nombre: 'guia.pdf', url: '', tipo: 'pdf', version: '1').isImage,
      isFalse,
    );
  });
}
