import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/lock_ad.dart';
import 'lock_ads_diff.dart';

class LockAdsStore {
  static Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      join(dir.path, 'lock_ads.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE anuncios (
            id TEXT PRIMARY KEY,
            texto TEXT NOT NULL,
            imagenUrl TEXT NOT NULL,
            version TEXT NOT NULL,
            rutaLocal TEXT NOT NULL,
            fechaDescarga INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<List<LockAdLocalRow>> all() async {
    final db = await _database;
    final rows = await db.query('anuncios', orderBy: 'fechaDescarga ASC');
    return rows.map(LockAdLocalRow.fromMap).toList();
  }

  Future<String> download(LockAd ad) async {
    final dir = await _lockDir();
    final localPath = join(dir.path, '${ad.id}_${ad.version}.jpg');
    final temporaryPath = '$localPath.download';
    final response = await http.get(Uri.parse(ad.imagenUrl)).timeout(const Duration(seconds: 45));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Descarga fallida (${response.statusCode})', uri: Uri.parse(ad.imagenUrl));
    }
    final temporaryFile = File(temporaryPath);
    if (await temporaryFile.exists()) await temporaryFile.delete();
    await temporaryFile.writeAsBytes(response.bodyBytes, flush: true);
    final finalFile = File(localPath);
    if (await finalFile.exists()) await finalFile.delete();
    await temporaryFile.rename(localPath);

    final db = await _database;
    final old = await db.query('anuncios', where: 'id = ?', whereArgs: [ad.id]);
    await db.insert(
      'anuncios',
      {
        'id': ad.id,
        'texto': ad.texto,
        'imagenUrl': ad.imagenUrl,
        'version': ad.version,
        'rutaLocal': localPath,
        'fechaDescarga': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (old.isNotEmpty) {
      final oldPath = old.first['rutaLocal'] as String?;
      if (oldPath != null && oldPath != localPath) {
        final oldFile = File(oldPath);
        if (await oldFile.exists()) await oldFile.delete();
      }
    }
    return localPath;
  }

  Future<void> updateMeta(LockAd ad) async {
    final db = await _database;
    await db.update(
      'anuncios',
      {
        'texto': ad.texto,
        'version': ad.version,
        'imagenUrl': ad.imagenUrl,
      },
      where: 'id = ?',
      whereArgs: [ad.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _database;
    final old = await db.query('anuncios', where: 'id = ?', whereArgs: [id]);
    await db.delete('anuncios', where: 'id = ?', whereArgs: [id]);
    if (old.isNotEmpty) {
      final path = old.first['rutaLocal'] as String?;
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    }
  }

  Future<File> writeCatalog(List<LockAdLocalRow> rows) async {
    final dir = await _lockDir();
    final file = File(join(dir.path, 'catalog.json'));
    final payload = {
      'items': rows
          .where((row) => File(row.localPath).existsSync())
          .map((row) => {
                'id': row.id,
                'texto': row.texto,
                'imagePath': row.localPath,
              })
          .toList(),
    };
    await file.writeAsString(jsonEncode(payload), flush: true);
    return file;
  }

  Future<Directory> _lockDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final lockDir = Directory(join(dir.path, 'lock_ads'));
    if (!await lockDir.exists()) await lockDir.create(recursive: true);
    return lockDir;
  }
}

class LockAdLocalRow {
  final String id;
  final String texto;
  final String imagenUrl;
  final String version;
  final String localPath;

  const LockAdLocalRow({
    required this.id,
    required this.texto,
    required this.imagenUrl,
    required this.version,
    required this.localPath,
  });

  factory LockAdLocalRow.fromMap(Map<String, dynamic> map) {
    return LockAdLocalRow(
      id: map['id'] as String,
      texto: map['texto'] as String,
      imagenUrl: map['imagenUrl'] as String,
      version: map['version'] as String,
      localPath: map['rutaLocal'] as String,
    );
  }

  LockAdLocalRef get asRef => LockAdLocalRef(
        id: id,
        version: version,
        imagenUrl: imagenUrl,
      );
}
