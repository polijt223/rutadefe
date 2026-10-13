import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

/// Servicio de caché local con versionado.
/// Solo descarga si la versión remota es diferente a la local.
class LocalCacheService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'ruta_de_fe_cache.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE archivos_locales (
            id TEXT PRIMARY KEY,
            seminarioId TEXT,
            seccionId TEXT,
            nombre TEXT,
            tipo TEXT,
            version TEXT,
            rutaLocal TEXT,
            fechaDescarga INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE historial_notificaciones (
            id TEXT PRIMARY KEY,
            seminarioId TEXT,
            miniReflexionId TEXT,
            texto TEXT,
            imagenUrl TEXT,
            fechaRecepcion INTEGER
          )
        ''');
      },
    );
  }

  /// Verifica si el archivo local está actualizado.
  /// Devuelve la ruta local si está al día, o null si hay que descargar.
  static Future<String?> getLocalPathIfUpToDate({
    required String fileId,
    required String remoteVersion,
  }) async {
    final db = await database;
    final result = await db.query(
      'archivos_locales',
      where: 'id = ? AND version = ?',
      whereArgs: [fileId, remoteVersion],
    );
    if (result.isNotEmpty) {
      final path = result.first['rutaLocal'] as String;
      if (await File(path).exists()) return path;
    }
    return null;
  }

  /// Descarga el archivo, guarda localmente y elimina versión anterior.
  static Future<String> downloadAndCache({
    required String fileId,
    required String seminarioId,
    required String seccionId,
    required String nombre,
    required String tipo,
    required String remoteUrl,
    required String remoteVersion,
  }) async {
    final db = await database;
    final dir = await getApplicationDocumentsDirectory();
    final fileExtension = extension(nombre);
    final localPath = join(dir.path, '${fileId}_$remoteVersion$fileExtension');
    final temporaryPath = '$localPath.download';
    final old = await db.query('archivos_locales', where: 'id = ?', whereArgs: [fileId]);
    final oldPath = old.isEmpty ? null : old.first['rutaLocal'] as String?;

    try {
      final response = await http.get(Uri.parse(remoteUrl)).timeout(const Duration(seconds: 45));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Descarga fallida (${response.statusCode})', uri: Uri.parse(remoteUrl));
      }

      final temporaryFile = File(temporaryPath);
      if (await temporaryFile.exists()) await temporaryFile.delete();
      await temporaryFile.writeAsBytes(response.bodyBytes, flush: true);

      final finalFile = File(localPath);
      if (await finalFile.exists()) await finalFile.delete();
      await temporaryFile.rename(localPath);

      await db.insert(
        'archivos_locales',
        {
          'id': fileId,
          'seminarioId': seminarioId,
          'seccionId': seccionId,
          'nombre': nombre,
          'tipo': tipo,
          'version': remoteVersion,
          'rutaLocal': localPath,
          'fechaDescarga': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (oldPath != null && oldPath != localPath) {
        final oldFile = File(oldPath);
        if (await oldFile.exists()) await oldFile.delete();
      }
      return localPath;
    } catch (_) {
      for (final path in [temporaryPath, localPath]) {
        final file = File(path);
        if (await file.exists() && path != oldPath) await file.delete();
      }
      rethrow;
    }
  }

  /// Guarda una notificación recibida en el historial (sin duplicados).
  static Future<void> saveNotificationHistory({
    required String seminarioId,
    required String miniReflexionId,
    required String texto,
    String? imagenUrl,
  }) async {
    final db = await database;
    final id = '${seminarioId}_$miniReflexionId';
    await db.insert(
      'historial_notificaciones',
      {
        'id': id,
        'seminarioId': seminarioId,
        'miniReflexionId': miniReflexionId,
        'texto': texto,
        'imagenUrl': imagenUrl,
        'fechaRecepcion': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore, // no duplicados
    );
  }

  static Future<List<Map<String, dynamic>>> getHistoryForSeminario(String seminarioId) async {
    final db = await database;
    return db.query(
      'historial_notificaciones',
      where: 'seminarioId = ?',
      whereArgs: [seminarioId],
      orderBy: 'fechaRecepcion DESC',
    );
  }
}
