class MiniReflexion {
  final String id;
  final String seminarioId;
  final String texto;
  final String? imagenUrl;
  final int orden;

  MiniReflexion({
    required this.id,
    required this.seminarioId,
    required this.texto,
    this.imagenUrl,
    required this.orden,
  });

  factory MiniReflexion.fromMap(String id, Map<String, dynamic> map) {
    return MiniReflexion(
      id: id,
      seminarioId: map['seminarioId'] ?? '',
      texto: map['texto'] ?? '',
      imagenUrl: map['imagenUrl'],
      orden: map['orden'] ?? 0,
    );
  }
}
