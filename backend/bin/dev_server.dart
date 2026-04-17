// Entwicklungs-Server mit Hot-Reload
//
// Starten mit:
//   cd backend
//   dart --enable-vm-service --disable-service-auth-codes run bin/dev_server.dart
//
// Bei Codeänderungen werden Isolates automatisch neu geladen.

import 'package:hotreloader/hotreloader.dart';

import 'server.dart' as server;

void main(List<String> args) async {
  print('🔥 Hot-Reload-Modus aktiv');
  try {
    await HotReloader.create(
      onAfterReload: (ctx) {
        print('♻️  Reload: ${ctx.result}');
      },
    );
  } catch (e) {
    print('⚠️  Hot-Reload konnte nicht gestartet werden: $e');
    print('    (Server läuft trotzdem.)');
  }

  await server.main(args);
}
