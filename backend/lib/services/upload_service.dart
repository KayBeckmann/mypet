import 'dart:io';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../config/config.dart';

/// Service für Datei-Uploads
class UploadService {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();

  final _config = Config();
  final _uuid = const Uuid();

  /// Erlaubte Bild-MIME-Types
  static const allowedImageTypes = {
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/webp': '.webp',
    'image/gif': '.gif',
  };

  /// Upload-Verzeichnis sicherstellen
  Future<void> ensureUploadDir() async {
    final dir = Directory('${_config.uploadPath}/pets');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      print('📁 Upload-Verzeichnis erstellt: ${dir.path}');
    }
  }

  /// Bild speichern und Dateinamen zurückgeben
  ///
  /// Gibt den relativen Pfad zurück (z.B. `pets/abc-123.jpg`)
  Future<String> saveImage({
    required Uint8List bytes,
    required String contentType,
    required String petId,
  }) async {
    // MIME-Type prüfen
    final extension = allowedImageTypes[contentType];
    if (extension == null) {
      throw UploadException(
        'Ungültiger Dateityp: $contentType. '
        'Erlaubt: ${allowedImageTypes.keys.join(", ")}',
      );
    }

    // Dateigröße prüfen
    if (bytes.length > _config.maxFileSize) {
      final maxMb = _config.maxFileSize / (1024 * 1024);
      throw UploadException(
        'Datei zu groß. Maximale Größe: ${maxMb.toStringAsFixed(0)} MB',
      );
    }

    await ensureUploadDir();

    // Eindeutiger Dateiname
    final filename = '${_uuid.v4()}$extension';
    final relativePath = 'pets/$filename';
    final fullPath = '${_config.uploadPath}/$relativePath';

    // Datei schreiben
    final file = File(fullPath);
    await file.writeAsBytes(bytes);

    return relativePath;
  }

  /// Bild löschen
  Future<void> deleteImage(String relativePath) async {
    if (relativePath.isEmpty) return;

    final fullPath = '${_config.uploadPath}/$relativePath';
    final file = File(fullPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Media-Verzeichnis sicherstellen
  Future<void> ensureMediaDir() async {
    final dir = Directory('${_config.uploadPath}/media');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      print('📁 Media-Verzeichnis erstellt: ${dir.path}');
    }
  }

  /// Beliebige Datei unter relativem Pfad speichern
  Future<void> saveRaw(Uint8List bytes, String relativePath) async {
    if (bytes.length > _config.maxFileSize) {
      final maxMb = _config.maxFileSize / (1024 * 1024);
      throw UploadException(
        'Datei zu groß. Maximale Größe: ${maxMb.toStringAsFixed(0)} MB',
      );
    }
    final fullPath = '${_config.uploadPath}/$relativePath';
    final file = File(fullPath);
    await file.writeAsBytes(bytes);
  }

  /// Vollständigen Dateipfad aus relativem Pfad erstellen
  String getFullPath(String relativePath) {
    return '${_config.uploadPath}/$relativePath';
  }

  /// URL-Pfad für API-Antworten generieren
  String getUrlPath(String relativePath) {
    return '/uploads/$relativePath';
  }
}

/// Exception für Upload-Fehler
class UploadException implements Exception {
  final String message;
  UploadException(this.message);

  @override
  String toString() => 'UploadException: $message';
}
