class Seminario {
  final String id;
  final String nombre;
  final String descripcion;
  final String? imagenPortada;
  final bool activo;
  final DateTime creadoEn;

  Seminario({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.imagenPortada,
    this.activo = true,
    required this.creadoEn,
  });

  factory Seminario.fromMap(String id, Map<String, dynamic> map) {
    return Seminario(
      id: id,
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      imagenPortada: map['imagenPortada'],
      activo: map['activo'] ?? true,
      creadoEn: ((map['creadoEn'] ?? map['createdAt']) as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'imagenPortada': imagenPortada,
      'activo': activo,
      'creadoEn': creadoEn,
    };
  }
}
