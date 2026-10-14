class LockAd {
  final String id;
  final String texto;
  final String imagenUrl;
  final String version;
  final bool activo;

  const LockAd({
    required this.id,
    required this.texto,
    required this.imagenUrl,
    required this.version,
    this.activo = true,
  });

  factory LockAd.fromMap(String id, Map<String, dynamic> map) {
    return LockAd(
      id: id,
      texto: (map['texto'] ?? '').toString().trim(),
      imagenUrl: (map['imagenUrl'] ?? '').toString(),
      version: (map['version'] ?? '').toString(),
      activo: map['activo'] != false,
    );
  }

  Map<String, dynamic> toCatalogJson(String imagePath) {
    return {
      'id': id,
      'texto': texto,
      'imagePath': imagePath,
    };
  }
}

class CachedLockAd {
  final LockAd ad;
  final String localPath;

  const CachedLockAd({required this.ad, required this.localPath});
}
