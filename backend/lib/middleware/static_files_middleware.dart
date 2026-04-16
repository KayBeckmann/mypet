import 'dart:io';
import 'package:shelf/shelf.dart';

/// Middleware zum Ausliefern statischer Dateien (Uploads)
///
/// Liefert Dateien aus dem angegebenen Verzeichnis aus,
/// wenn der Request-Pfad mit dem Prefix übereinstimmt.
Handler staticFilesHandler({
  required String basePath,
  required String urlPrefix,
}) {
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

    // Cache-Header setzen (1 Jahr für Bild-Uploads mit UUID-Namen)
    return Response.ok(
      file.openRead(),
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
