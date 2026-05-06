# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development (Docker)
```bash
# Alle Services starten (Dev mit Hot-Reload)
./scripts/start-dev.sh
# oder: docker-compose -f docker-compose.dev.yml up -d

# Logs
docker-compose logs -f backend

# DB zurücksetzen (löscht alle Daten, führt Migrationen aus)
./scripts/reset-db.sh
```

### Backend (Dart)
```bash
cd backend
dart pub get
dart run bin/server.dart                    # Server starten
dart run bin/server.dart --migrate          # Migrationen ausführen
dart run bin/server.dart --status           # Migrations-Status
dart run bin/server.dart --rollback         # Letzte Migration zurückrollen
dart analyze                                # Linter
dart test                                   # Tests
dart test test/path/to/test.dart            # Einzelner Test
```

### Flutter Web Apps
```bash
cd web_owner   # oder web_vet / web_provider / web_admin
flutter pub get
flutter run -d chrome                       # Im Browser starten
flutter build web --release                 # Production Build
flutter analyze                             # Linter
flutter test                                # Tests
```

### Service-URLs (Development)
| Service | URL |
|---------|-----|
| Besitzer-App (Web) | http://localhost:3001 |
| Tierarzt-App (Web) | http://localhost:3002 |
| Dienstleister-App (Web) | http://localhost:3003 |
| Admin-App (Web) | http://localhost:3004 |
| Backend API | http://localhost:8080 |

### Konfigurationsregel: NIEMALS hardcoden — immer .env

**Pflicht:** Alle konfigurierbaren Werte kommen aus `.env` / `.env.example`. Dies gilt für:
- Ports (BACKEND_PORT, OWNER_PORT, VET_PORT, PROVIDER_PORT, ADMIN_PORT)
- URLs (ANDROID_API_URL, etc.)
- Credentials (Passwörter, Secrets, API-Keys)
- Feature-Flags oder externe Service-Adressen

**Vorgehen:**
1. Neuen Config-Wert in `.env.example` eintragen (mit Kommentar und sinnvollem Default)
2. Selben Wert in `.env` ergänzen (mit echtem Wert für Dev-Umgebung)
3. In `docker-compose.yml` über `environment:` oder `build.args:` referenzieren: `${VAR:-default}`
4. Im Code nur über Umgebungsvariablen (`String.fromEnvironment`, `Platform.environment`, etc.) — niemals direkt als String-Literal

**Falsch:** `API_BASE_URL = "http://localhost:8080"` im Code
**Richtig:** `const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080')`

### Android APK bauen
```bash
# APK mit Docker bauen (nutzt Android SDK im Flutter-Image):
docker-compose build android-owner
docker-compose run --rm android-owner

# APK aus dem Volume extrahieren:
docker run --rm -v mypet_android-apk:/data alpine cp /data/mypet-owner.apk /tmp/
# oder direkt beim Build:
docker build -t mypet-android -f android_owner/Dockerfile . && \
  docker run --rm mypet-android cat /app/mypet-owner.apk > mypet-owner.apk
```

---

## Architektur

### Monorepo-Struktur

```
mypet/
├── backend/          Dart/Shelf REST-API
├── web_owner/        Flutter Web — Tierbesitzer
├── web_vet/          Flutter Web — Tierärzte
├── web_provider/     Flutter Web — Dienstleister
├── web_admin/        Flutter Web — Superadmin
├── android_owner/    Flutter Android — Tierbesitzer App (APK)
├── shared/           Gemeinsame Models/Services (ApiService, User — kein dart:html, läuft auf Web+Android)
└── scripts/          Dev-Hilfsskripte
```

**Wichtig:** `web_owner` und andere Web-Apps nutzen `dart:html` (web-only). Das `android_owner`-Projekt vermeidet `dart:html` und nutzt stattdessen `shared_preferences` und `image_picker`.

### Backend (Dart/Shelf)

**Request-Flow:**
```
Request → corsMiddleware → loggingMiddleware → [authMiddleware] → Router → Controller → Database
```

- `bin/server.dart` — Einstiegspunkt, registriert alle Router und Middlewares
- `lib/config/config.dart` — Singleton, liest alle `.env`-Variablen
- `lib/database/database.dart` — Singleton (`Database()`), wraps `postgres` Connection. Alle Queries über `db.queryAll()`, `db.queryOne()`, `db.query()`, `db.transaction()`
- `lib/database/migrations/migrations.dart` — Alle Migrationen als `const`-Objekte in einer Liste. Neue Migration: Eintrag in dieser Datei hinzufügen, Version hochzählen
- `lib/middleware/auth_middleware.dart` — JWT verifizieren, `userId`/`userRole`/`activeOrganizationId` in `request.context` schreiben
- `lib/utils/pet_access.dart` — `petHasAccess()` zentrale Zugriffslogik für alle pet-bezogenen Endpunkte

**Controller-Muster:** Jeder Controller nimmt `Database _db` im Konstruktor, gibt einen `Router` zurück. Der Router wird in `server.dart` unter einem Prefix gemountet (z.B. `/pets`). Authentifizierte Routen lesen `userId` und `activeOrganizationId` aus `request.context`.

**Berechtigungen:**
- Globale Rollen: `owner`, `vet`, `provider`, `superadmin` (im JWT)
- Tier-Zugriff: Eigentümer ODER aktive `access_permissions` (direkt für User oder via Organisation)
- Organisations-Berechtigungsgruppen: eigene Tabelle `permission_groups`, geprüft in Controllern die Organisations-Ressourcen verwalten

**Enum-Werte** aus PostgreSQL kommen als `UndecodedBytes` zurück (postgres 3.x Bug). `Database._decodeRow()` dekodiert sie automatisch als UTF-8.

### Flutter Web Apps

Alle vier Apps haben identisches Muster:
- **State Management:** Provider (`ChangeNotifier`)
- **Routing:** `go_router` mit Auth-Guard in `config/routes.dart`
- **API:** `ApiService` (singleton, `String.fromEnvironment('API_BASE_URL')` konfigurierbar beim Build)
- **Token:** In Memory im `AuthProvider`, kein Persistent-Storage außer bei explizitem "remember"

`main.dart` erstellt den `ApiService`, gibt ihn an alle Provider weiter via `MultiProvider`. Nach Login lädt `_AppWithAuth` automatisch die Initialdaten (Tiere, Termine).

**Provider-Muster:** Jeder Provider hält eine Liste von Objekten (`List<Pet> pets`) und eine Fehler-/Loading-State. Methoden rufen `ApiService` auf und triggern `notifyListeners()`.

**Demo-Modus:** `AuthProvider.isDemoMode` — wenn aktiv, laden Provider lokale Testdaten statt API-Calls zu machen (nur `web_owner`).

### Datenbank

38 Migrationen (in `migrations.dart`), alle als `const Migration(version, name, up, down)`. Kernentitäten:

| Tabelle | Zweck |
|---------|-------|
| `users` | Benutzeraccounts, Rollen-Enum |
| `pets` | Tiere, gehören immer einem `owner_id` |
| `access_permissions` | Zeitlich begrenzte Zugriffe (User oder Org) auf Tiere |
| `organizations` | Praxen/Firmen |
| `organization_members` | Mitgliedschaften mit Rolle |
| `families` | Familiengruppen für Besitzer |
| `pet_notes` | Verschlüsselt gespeichert (AES-256-CBC via `EncryptionService`) |
| `media` | Datei-Metadaten, Binärdaten lokal im `UPLOAD_PATH` |
| `temperature_history` | Körpertemperatur-Verlauf (Migration 033) |
| `lab_results` | Laborbefunde vom Tierarzt (Migration 034) |
| `organization_ratings` | 1–5 Sterne Bewertungen für Praxen (Migration 035) |
| `patient_assignments` | Patientenzuweisung an Teammitglieder (Migration 037) |

`updated_at`-Spalten werden automatisch via PostgreSQL-Trigger aktualisiert (in Migration 001 angelegt, für alle Tabellen wiederverwendet).

### Neue Migration hinzufügen

1. In `backend/lib/database/migrations/migrations.dart` neues `const _migration0XX...`-Objekt anlegen (nächste Version)
2. In der `migrations`-Liste am Ende eintragen
3. `dart run bin/server.dart --migrate` ausführen

### Neue Controller-Route hinzufügen

1. Methode im zuständigen Controller (`lib/controllers/`) implementieren
2. In `Router get router` registrieren
3. Falls neuer Controller: in `bin/server.dart` instanziieren und als `.mount('/prefix', ...)` einhängen

### Neuer Provider (Frontend)

1. `lib/providers/new_provider.dart` anlegen, `ChangeNotifier` extenden, `ApiService api` im Konstruktor
2. In `main.dart` in `MultiProvider` eintragen
