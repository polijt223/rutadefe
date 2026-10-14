class Seccion {
  final String id;
  final String seminarioId;
  final String titulo;
  final String contenidoTexto;
  final int orden;
  final String version; // para control de caché
  final List<ArchivoMaterial> archivos;
  final String? youtubeUrl;

  Seccion({
    required this.id,
    required this.seminarioId,
    required this.titulo,
    required this.contenidoTexto,
    required this.orden,
    required this.version,
    this.archivos = const [],
    this.youtubeUrl,
  });

  factory Seccion.fromMap(String id, Map<String, dynamic> map) {
    return Seccion(
      id: id,
      seminarioId: map['seminarioId'] ?? '',
      titulo: map['titulo'] ?? '',
      contenidoTexto: map['contenidoTexto'] ?? '',
      orden: map['orden'] ?? 0,
      version: map['version'] ?? '1',
      youtubeUrl: map['youtubeUrl'],
      archivos: (map['archivos'] as List<dynamic>?)
              ?.map((e) => ArchivoMaterial.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ArchivoMaterial {
  final String nombre;
  final String url;
  final String tipo; // pdf, imagen
  final String version;

  ArchivoMaterial({
    required this.nombre,
    required this.url,
    required this.tipo,
    required this.version,
  });

  factory ArchivoMaterial.fromMap(Map<String, dynamic> map) {
    return ArchivoMaterial(
      nombre: map['nombre'] ?? '',
      url: map['url'] ?? '',
      tipo: map['tipo'] ?? 'pdf',
      version: map['version'] ?? '1',
    );
  }

  bool get isPdf {
    final kind = tipo.toLowerCase();
    return kind == 'pdf' || nombre.toLowerCase().endsWith('.pdf');
  }

  bool get isImage {
    final kind = tipo.toLowerCase();
    if (kind == 'imagen' || kind == 'image' || kind == 'img') return true;
    final lower = nombre.toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic']
        .any(lower.endsWith);
  }
}
