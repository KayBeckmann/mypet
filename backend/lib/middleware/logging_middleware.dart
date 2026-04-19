import 'package:shelf/shelf.dart';
import '../controllers/health_controller.dart';

/// Middleware für Request-Logging
Middleware loggingMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      HealthController.incrementRequests();
      final stopwatch = Stopwatch()..start();
      final method = request.method;
      final path = request.requestedUri.path;

      print('[${DateTime.now().toIso8601String()}] $method $path');

      try {
        final response = await innerHandler(request);
        stopwatch.stop();

        final statusCode = response.statusCode;
        final duration = stopwatch.elapsedMilliseconds;

        print(
            '[${DateTime.now().toIso8601String()}] $method $path -> $statusCode (${duration}ms)');

        return response;
      } catch (e, stackTrace) {
        stopwatch.stop();
        print(
            '[${DateTime.now().toIso8601String()}] $method $path -> ERROR: $e');
        print(stackTrace);
        rethrow;
      }
    };
  };
}
