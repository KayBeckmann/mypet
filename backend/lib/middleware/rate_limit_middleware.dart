import 'dart:convert';
import 'package:shelf/shelf.dart';

/// Einfaches In-Memory Rate-Limiting für Auth-Endpoints.
/// Blockiert eine IP nach [maxAttempts] Versuchen für [windowSeconds] Sekunden.
Middleware rateLimitMiddleware({
  int maxAttempts = 10,
  int windowSeconds = 60,
}) {
  final attempts = <String, List<DateTime>>{};

  return (Handler inner) {
    return (Request request) async {
      final ip = request.headers['x-forwarded-for'] ??
          request.headers['x-real-ip'] ??
          'unknown';

      final now = DateTime.now();
      final window = now.subtract(Duration(seconds: windowSeconds));

      final list = attempts.putIfAbsent(ip, () => []);
      list.removeWhere((t) => t.isBefore(window));

      if (list.length >= maxAttempts) {
        return Response(
          429,
          body: jsonEncode({
            'error': 'Zu viele Versuche. Bitte warte $windowSeconds Sekunden.',
          }),
          headers: {
            'Content-Type': 'application/json',
            'Retry-After': '$windowSeconds',
          },
        );
      }

      final response = await inner(request);

      // Nur Fehler-Antworten (4xx) zählen als fehlgeschlagene Versuche
      if (response.statusCode == 401 || response.statusCode == 403) {
        list.add(now);
      } else if (response.statusCode == 200 || response.statusCode == 201) {
        // Erfolgreicher Login → Zähler zurücksetzen
        list.clear();
      }

      attempts[ip] = list;
      return response;
    };
  };
}
