import 'dart:io';
import 'package:shelf/shelf.dart';
import '../services/encryption_service.dart';

/// Middleware zum Ausliefern statischer Dateien (Uploads)
///
/// Liefert Dateien aus dem angegebenen Verzeichnis aus,
/// wenn der Request-Pfad mit dem Prefix übereinstimmt.
///
/// Seit M17.2 liegen Uploads verschlüsselt auf Disk (siehe
/// `UploadService`/`EncryptionService`) — hier wird beim Ausliefern
/// transparent entschlüsselt, sodass sich für aufrufende Clients (Browser
/// `<img>`-Tags, `Image.network`, Downloads) nichts ändert. Dateien aus der
/// Zeit vor diesem Feature haben keine Verschlüsselungs-Kennung und werden
/// unverändert durchgereicht (siehe `decryptBytesOrRaw`).
Handler staticFilesHandler({
  required String basePath,
  required String urlPrefix,
}) {
  final encryption = EncryptionService();
  return (Request request) async {
    // Pfad bereinigen um Directory-Traversal zu verhindern
    final requestPath = request.url.path;
    if (requestPath.contains('..')) {
      return Response.forbidden('Ungültiger Pfad');
    }

    final filePath = '$basePath/$requestPath';
    final file = File(filePath);

    if (!await file.exists()) {
      return Response.notFound('Datei nicht gefunden');
    }

    // MIME-Type bestimmen
    final contentType = _mimeType(filePath);

    // Ganze Datei lesen (nicht streambar, da AES-CBC entschlüsselt werden
    // muss) — durch die bestehende maxFileSize-Grenze beim Upload
    // unproblematisch (Default 10 MB laut .env.example).
    final rawBytes = await file.readAsBytes();
    final bytes = encryption.decryptBytesOrRaw(rawBytes);

    // Cache-Header setzen (1 Jahr für Bild-Uploads mit UUID-Namen)
    return Response.ok(
      bytes,
      headers: {
        'Content-Type': contentType,
        'Cache-Control': 'public, max-age=31536000, immutable',
        'X-Content-Type-Options': 'nosniff',
      },
    );
  };
}

String _mimeType(String path) {
  final ext = path.split('.').last.toLowerCase();
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'svg':
      return 'image/svg+xml';
    case 'pdf':
      return 'application/pdf';
    default:
      return 'application/octet-stream';
  }
}
