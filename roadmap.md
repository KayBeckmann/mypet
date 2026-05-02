# MyPet - Roadmap

> Kleine, inkrementelle Meilensteine für die Entwicklung

---

## Phase 0: Projekt-Infrastruktur

### M0.1 - Repository-Grundstruktur ✅
- [x] Ordnerstruktur anlegen (backend/, web_owner/, web_vet/, web_provider/, shared/)
- [x] Root `.gitignore` erstellen
- [x] `README.md` mit Projektbeschreibung

### M0.2 - Docker-Setup ✅
- [x] `Dockerfile` für Backend (Dart)
- [x] `Dockerfile` für Web-Frontends (Flutter Web)
- [x] `docker-compose.yml` mit allen Services
- [x] PostgreSQL-Container konfigurieren
- [x] Nginx als Reverse-Proxy (in Frontend-Containern integriert)

### M0.3 - Konfiguration ✅
- [x] `.env.example` mit allen Umgebungsvariablen
- [x] `.env` zu `.gitignore` hinzufügen
- [x] Konfigurationsklasse im Backend für .env-Variablen
- [x] Dokumentation der Umgebungsvariablen

### M0.4 - Entwicklungsumgebung ✅
- [x] Docker Compose für Entwicklung (`docker-compose.dev.yml`)
- [x] Hot-Reload für Backend einrichten (`bin/dev_server.dart` + `hotreloader`)
- [x] Lokale PostgreSQL-Instanz
- [x] Basis-Skripte (`start-dev.sh`, `stop-dev.sh`, `reset-db.sh`)

---

## Phase 1: Backend-Grundlagen

### M1.1 - Dart Backend Setup ✅
- [x] Dart-Projekt initialisieren
- [x] Backend-Framework wählen und einrichten (Shelf)
- [x] Basis-Server mit Health-Check Endpoint (`GET /health`)
- [x] CORS-Middleware
- [x] Request-Logging

### M1.2 - Datenbank-Anbindung ✅
- [x] PostgreSQL-Verbindung einrichten
- [x] Datenbank-Migrationen-System
- [x] Connection-Pooling
- [x] Erste Migration: Benutzer-Tabelle

### M1.3 - Authentifizierung (Teil 1) ✅
- [x] Benutzer-Model erstellen
- [x] Passwort-Hashing (Argon2/Bcrypt)
- [x] `POST /auth/register` - Registrierung
- [x] `POST /auth/login` - Login mit JWT
- [x] JWT-Generierung und Validierung

### M1.4 - Authentifizierung (Teil 2) ✅
- [x] `POST /auth/refresh` - Token erneuern
- [x] `POST /auth/logout` - Logout
- [x] Auth-Middleware für geschützte Routen
- [x] Rollen-System (Besitzer/Tierarzt/Dienstleister)

### M1.5 - Benutzer-Verwaltung ✅
- [x] `GET /account` - Eigene Daten abrufen
- [x] `PUT /account` - Profil aktualisieren
- [x] `DELETE /account` - Konto löschen (DSGVO)
- [x] Passwort ändern

### M1.6 - Organisationen (Praxen & Firmen) ✅
> Multi-User-System für Tierärzte und Dienstleister

- [x] Migration: Organisation-Tabelle
- [x] Migration: Organisations-Mitgliedschaft-Tabelle
- [x] Migration: Berechtigungsgruppen-Tabelle
- [x] Migration: Einladungen-Tabelle
- [x] Organisation-Model erstellen
- [x] `POST /organizations` - Organisation erstellen (Ersteller wird Admin)
- [x] `GET /organizations` - Eigene Organisationen abrufen
- [x] `PUT /organizations/:id` - Organisation aktualisieren (nur Admin)
- [x] `DELETE /organizations/:id` - Organisation löschen (nur Gründer)

### M1.7 - Organisations-Mitglieder ✅
- [x] Mitgliedschafts-Model erstellen
- [x] `GET /organizations/:id/members` - Alle Mitglieder
- [x] `POST /organizations/:id/members/invite` - Einladung per E-Mail
- [x] Einladungs-E-Mail versenden (via EmailService, fire-and-forget wenn SMTP konfiguriert)
- [x] `POST /invitations/:code/accept` - Einladung annehmen
- [x] `POST /invitations/:code/reject` - Einladung ablehnen
- [x] `PUT /organizations/:id/members/:userId` - Rolle ändern
- [x] `DELETE /organizations/:id/members/:userId` - Mitglied entfernen

### M1.8 - Berechtigungsgruppen ✅
- [x] Berechtigungsgruppen-Model erstellen
- [x] Standard-Gruppen bei Organisation-Erstellung anlegen
  - Tierarztpraxis: Admin, Tierarzt, TFA, Azubi, Buchhaltung
  - Dienstleister: Admin, Mitarbeiter, Azubi
- [x] `GET /organizations/:id/permission-groups`
- [x] `POST /organizations/:id/permission-groups`
- [x] `PUT /permission-groups/:id`
- [x] `DELETE /permission-groups/:id`
- [x] Berechtigungs-Middleware: Prüfung bei jedem Request (org-level + user-level Permissions in pet_controller, medical_record, vaccination, medication)

### M1.9 - Organisations-Kontext ✅
- [x] Aktive Organisation im JWT-Token speichern
- [x] Organisation wechseln (für Benutzer in mehreren Orgs) via `POST /auth/switch-organization`
- [x] Header `X-Active-Organization` als Override unterstützt
- [x] Alle Daten werden im Kontext der aktiven Organisation gefiltert (pets list/get + appointments already filter by activeOrganizationId)
- [x] Audit-Log für Organisations-Aktionen (create/delete/invite über AuditService)

---

## Phase 2: Tier-Verwaltung (Backend)

### M2.1 - Tier-Model ✅
- [x] Migration: Tier-Tabelle
- [x] Tier-Model mit allen Feldern
- [x] Validierung der Eingaben

### M2.2 - Tier-CRUD ✅
- [x] `GET /pets` - Alle eigenen Tiere
- [x] `GET /pets/:id` - Einzelnes Tier
- [x] `POST /pets` - Tier anlegen
- [x] `PUT /pets/:id` - Tier aktualisieren
- [x] `DELETE /pets/:id` - Tier löschen

### M2.3 - Foto-Upload für Tiere ✅
- [x] Datei-Upload-Endpoint
- [x] Bild-Speicherung (lokal oder S3-kompatibel)
- [x] Bild-URL im Tier-Profil speichern
- [x] Bild-Größen-Validierung

---

## Phase 3: Web-Frontend Tierbesitzer (Basis)

### M3.1 - Flutter Web Setup ✅
- [x] Flutter Web-Projekt initialisieren
- [x] Ordnerstruktur (screens/, widgets/, services/, providers/)
- [x] Theme und Styling-Grundlagen
- [x] Router einrichten (go_router)

### M3.2 - Authentifizierung UI ✅
- [x] Login-Screen
- [x] Registrierungs-Screen
- [x] Token-Speicherung (secure storage)
- [x] Auth-State-Management
- [x] Logout-Funktion

### M3.3 - API-Service ✅
- [x] HTTP-Client einrichten (dio/http)
- [x] Base-URL aus Konfiguration
- [x] Auth-Token automatisch anhängen
- [x] Error-Handling

### M3.4 - Tier-Liste ✅
- [x] Tier-Liste Screen
- [x] Tier-Karte Widget
- [x] Pull-to-Refresh
- [x] Leerer Zustand (keine Tiere)

### M3.5 - Tier hinzufügen ✅
- [x] Formular: Tier anlegen
- [x] Foto-Upload
- [x] Validierung
- [x] Erfolgs-/Fehlermeldungen

### M3.6 - Tier-Detail ✅
- [x] Tier-Detail Screen
- [x] Tier bearbeiten
- [x] Tier löschen (mit Bestätigung)

---

## Phase 4: Familien & Freigaben (Backend)

### M4.1 - Familien-Model ✅
- [x] Migration: Familie-Tabelle
- [x] Migration: Familien-Mitgliedschaft-Tabelle
- [x] Models erstellen

### M4.2 - Familien-API ✅
- [x] `GET /families` - Eigene Familien
- [x] `POST /families` - Familie erstellen
- [x] `POST /families/:id/members` - Mitglied einladen
- [x] `DELETE /families/:id/members/:userId` - Mitglied entfernen

### M4.3 - Zugriffsberechtigung-Model ✅
- [x] Migration: Zugriffsberechtigung-Tabelle
- [x] Model erstellen
- [x] Berechtigungs-Prüfung implementieren (access_permissions geprüft in pet_controller, medical_record, vaccination, medication)

### M4.4 - Zugriffsberechtigung-API ✅
- [x] `GET /permissions` - Eigene Berechtigungen
- [x] `POST /permissions` - Berechtigung erteilen
- [x] `PUT /permissions/:id` - Berechtigung aktualisieren
- [x] `DELETE /permissions/:id` - Berechtigung widerrufen

---

## Phase 5: Familien & Freigaben (Frontend)

### M5.1 - Familie erstellen ✅
- [x] Familie erstellen Screen (Dialog)
- [x] Familien-Übersicht

### M5.2 - Mitglieder verwalten ✅
- [x] Mitglieder einladen (per E-Mail)
- [x] Mitglieder-Liste
- [x] Mitglied entfernen

### M5.3 - Urlaubsvertretung ✅
- [x] Berechtigung erteilen Screen (Dialog mit Tier, Empfänger, Stufe, Zeitraum, Notiz)
- [x] Zeitraum wählen (DatePicker für Start + Ende)
- [x] Aktive Berechtigungen anzeigen (Liste mit Status-Badges, Widerrufen-Button)

---

## Phase 6: Medizinische Daten (Backend)

### M6.1 - Medizinische Akte ✅
- [x] Migration 010: Medizinische Akte-Tabelle (mit record_type enum)
- [x] `GET /pets/:id/records` (Zugriffscheck, private Einträge gefiltert)
- [x] `POST /pets/:id/records`
- [x] `GET /pets/:id/records/:recordId`
- [x] `PUT /pets/:id/records/:recordId` (nur Ersteller)
- [x] `DELETE /pets/:id/records/:recordId`

### M6.2 - Impfungen ✅
- [x] Migration 011: Impfungen-Tabelle
- [x] `GET /pets/:id/vaccinations`
- [x] `POST /pets/:id/vaccinations`
- [x] `DELETE /pets/:id/vaccinations/:vacId`

### M6.3 - Medikationen ✅
- [x] Migration 012: Medikation-Tabelle (mit medication_frequency enum)
- [x] `GET /pets/:id/medications`
- [x] `POST /pets/:id/medications`
- [x] `PUT /pets/:id/medications/:medId`
- [x] `DELETE /pets/:id/medications/:medId`

### M6.4 - Medikations-Tracking ✅
- [x] Migration 013: Medikations-Verabreichung-Tabelle
- [x] `GET /pets/:id/medications/:medId/schedule`
- [x] `POST /pets/:id/medications/:medId/administer`
- [x] `POST /pets/:id/medications/:medId/skip`

---

## Phase 7: Web-Frontend Tierarzt (Basis)

### M7.1 - Projekt-Setup
- [x] Flutter Web-Projekt für Tierärzte
- [x] Gemeinsame Komponenten aus shared/
- [x] Auth-Flow (wie Besitzer-App)

### M7.2 - Praxis-Profil & Organisation ✅
- [x] Praxis/Organisation erstellen (Dialog)
- [x] Praxis-Profil bearbeiten (Name, Adresse, Tel, E-Mail, Website, Öffnungszeiten, Spezialisierung)
- [x] Organisations-Wechsler (Dropdown für mehrere Praxen)

### M7.3 - Mitarbeiter-Verwaltung (Praxis-Admin) ✅
- [x] Mitarbeiter-Liste anzeigen
- [x] Mitarbeiter einladen (E-Mail, Rolle, Position)
- [x] Mitarbeiter-Rolle ändern (Dropdown)
- [x] Mitarbeiter entfernen

### M7.4 - Patienten-Liste ✅
- [x] Tiere mit Zugriff anzeigen
- [x] Suche nach Name/Tierart

### M7.5 - Medizinische Akte führen ✅
- [x] Akte-Einträge anzeigen (Tab-Ansicht)
- [x] Neuer Eintrag (Typ, Titel, Diagnose, Behandlung, privat)
- [x] Diagnose und Behandlung dokumentieren

### M7.6 - Impfungen eintragen ✅
- [x] Impfungen anzeigen mit Ablauf-Status
- [x] Neue Impfung (Impfstoff, Charge, Hersteller, Gültigkeit)

### M7.7 - Medikamente verordnen ✅
- [x] Aktive/abgeschlossene Medikamente anzeigen
- [x] Medikament verordnen (Name, Dosierung, Häufigkeit, Anweisungen, Enddatum)

---

## Phase 8: Termine (Backend)

### M8.1 - Termine-Model
- [x] Migration: Termine-Tabelle
- [x] Model mit Status-Workflow

### M8.2 - Termine-API
- [x] `GET /appointments`
- [x] `POST /appointments`
- [x] `PUT /appointments/:id/confirm`
- [x] `PUT /appointments/:id/complete`
- [x] `DELETE /appointments/:id`

### M8.3 - Automatischer Zugriff
- [x] Bei Terminbestätigung Zugriff gewähren
- [x] Zugriff nach Termin-Abschluss entziehen

---

## Phase 9: Termine (Frontend)

### M9.1 - Termine buchen (Besitzer)
- [x] Tierarzt/Dienstleister suchen
- [x] Termin anfragen
- [x] Eigene Termine anzeigen

### M9.2 - Termine verwalten (Tierarzt)
- [x] Terminanfragen anzeigen
- [x] Termin bestätigen/ablehnen
- [x] Kalenderansicht

---

## Phase 10: Fütterungsmanagement (Backend)

### M10.1 - Futterplan-Models
- [x] Migration: Futterplan-Tabelle
- [x] Migration: Futterplan-Mahlzeit-Tabelle
- [x] Migration: Futterplan-Komponente-Tabelle

### M10.2 - Futterplan-API
- [x] `GET /pets/:id/feeding-plans`
- [x] `POST /pets/:id/feeding-plans`
- [x] `PUT /feeding-plans/:id`
- [x] Mahlzeiten und Komponenten CRUD

### M10.3 - Fütterungs-Protokoll
- [x] Migration: Fütterung-Protokoll-Tabelle
- [x] `GET /pets/:id/feeding-log`
- [x] `POST /pets/:id/feeding-log`

---

## Phase 11: Fütterungsmanagement (Frontend)

### M11.1 - Futterplan erstellen
- [x] Futterplan-Screen
- [x] Mahlzeiten hinzufügen
- [x] Komponenten mit Mengen

### M11.2 - Fütterung protokollieren
- [x] Tägliche Übersicht
- [x] Als gefüttert markieren
- [x] Notizen hinzufügen

---

## Phase 12: Web-Frontend Dienstleister (Basis)

### M12.1 - Projekt-Setup
- [x] Flutter Web-Projekt für Dienstleister
- [x] Auth-Flow
- [x] Dienstleister-Profil (Dashboard-Grundgerüst)

### M12.2 - Firmen-Profil & Organisation
- [x] Firma/Organisation erstellen
- [x] Firmen-Profil bearbeiten
- [x] Organisations-Übersicht (alle eigenen Firmen)

### M12.3 - Mitarbeiter-Verwaltung (Firmen-Admin)
- [x] Mitarbeiter-Liste anzeigen
- [x] Mitarbeiter einladen (E-Mail oder Link)
- [x] Einladung als neuer Benutzer annehmen
- [x] Mitarbeiter-Rolle ändern
- [x] Mitarbeiter deaktivieren/entfernen

### M12.4 - Kunden-Liste
- [x] Kunden mit Zugriff anzeigen
- [x] Tiere pro Kunde

### M12.5 - Leistungen dokumentieren
- [x] Neue Leistung erfassen
- [x] Leistungs-Historie

### M12.6 - Termine verwalten
- [x] Terminanfragen
- [x] Termin bestätigen/ablehnen/abschließen

---

## Phase 13: Medien & Dokumente (Backend)

### M13.1 - Medien-Upload ✅
- [x] Migration: Medien-Tabelle (migration 018, media_type enum)
- [x] Datei-Upload Service (ensureMediaDir, saveRaw)
- [x] Verschlüsselte Speicherung: AES-256-CBC via EncryptionService (Migration 024)

### M13.2 - Medien-API ✅
- [x] `GET /pets/:id/media`
- [x] `POST /pets/:id/media`
- [x] `GET /pets/:id/media/:mediaId`
- [x] `DELETE /pets/:id/media/:mediaId`

---

## Phase 14: Medien & Dokumente (Frontend)

### M14.1 - Besitzer: Dokumente ✅
- [x] Dokumente hochladen (file_picker, multipart upload)
- [x] Dokumente anzeigen (Grid-Ansicht, Tabs nach Typ)
- [x] MediaProvider + PetMedia-Model
- [x] Löschen mit Bestätigung

### M14.2 - Tierarzt: Röntgenbilder ✅
- [x] Bilder hochladen (file_picker im Upload-Dialog)
- [x] Bildarchiv als 4. Tab in PatientDetailScreen
- [x] VetMediaProvider + VetMedia-Model
- [x] Löschen mit Bestätigung

---

## Phase 15: Professionelle Notizen

### M15.1 - Backend ✅
- [x] Migration 019: pet_notes-Tabelle mit note_visibility ENUM
- [x] Sichtbarkeits-Logik (private/colleagues/all_professionals)
- [x] NoteController: GET/POST/PUT/DELETE /pets/:id/notes

### M15.2 - Frontend (Tierarzt & Dienstleister) ✅
- [x] VetNotesProvider + Notizen-Tab in PatientDetailScreen (5. Tab)
- [x] ProviderNotesProvider + Notizen-Dialog über Kunden-Karte
- [x] Sichtbarkeit wählen (Dropdown), Erstellen, Löschen

---

## Phase 16: Besitzerwechsel

### M16.1 - Backend ✅
- [x] Migration 020: ownership_transfers mit transfer_status ENUM
- [x] TransferController: POST initiieren, DELETE abbrechen, GET auflisten
- [x] Token-basierte Annahme/Ablehnung (POST /transfers/:token/accept|reject)
- [x] Besitzerwechsel: pets.owner_id auf neuen Benutzer aktualisiert

### M16.2 - Frontend ✅
- [x] TransferProvider (initiate, cancel, accept, reject)
- [x] "Besitz übertragen" Dialog in AnimalDetailScreen
- [x] TransferScreen mit Token-Eingabe zum Annehmen/Ablehnen
- [x] TRANSFER Nav-Item in Sidebar

---

## Phase 17: DSGVO & Sicherheit

### M17.1 - Datenexport ✅
- [x] `GET /account/export` — Benutzer, Tiere, Termine, Berechtigungen, Transfers als JSON
- [x] Content-Disposition Header für direkten Download
- [x] SettingsScreen mit Export-Button in owner app

### M17.2 - Verschlüsselung ✅
- [x] Sensible Felder verschlüsseln: pet_notes.content via AES-256-CBC (EncryptionService)
- [ ] Medien verschlüsselt speichern (offen – erfordert Storage-Backend-Änderung)

### M17.3 - Audit-Log ✅
- [x] Migration 021: audit_log-Tabelle
- [x] AuditService für einfaches Logging
- [x] `GET /account/audit-log` — eigene Einträge abrufen
- [x] Audit-Log-Ansicht in SettingsScreen

---

## Phase 18: Mobile Apps (Optional)

### M18.1 - Flutter Mobile Setup
- [ ] Bestehenden Web-Code für Mobile anpassen
- [ ] Plattform-spezifische Anpassungen
- [ ] Lokale Datenbank (Hive/Isar)

### M18.2 - Offline-Sync
- [ ] Lokale Datenspeicherung
- [ ] Sync-Logik
- [ ] Konfliktauflösung

### M18.3 - Push-Benachrichtigungen
- [ ] Firebase Cloud Messaging einrichten
- [ ] Erinnerungen (Impfungen, Medikamente, Fütterung)

---

## Phase 19: Erweiterte Features

### M19.1 - Compliance-Überwachung (Tierarzt) ✅
- [x] Verabreichungs-Protokoll anzeigen
- [x] Compliance-Statistik

### M19.2 - Gewichtsverlauf ✅
- [x] Migration 022: weight_history Tabelle
- [x] WeightController: GET/POST/DELETE /pets/:id/weight
- [x] WeightProvider + WeightScreen in owner app
- [x] Liniendiagramm (CustomPainter, keine externe Abhängigkeit)
- [x] Statistik-Karten (Aktuell, Min, Max, Anzahl)

### M19.3 - Erinnerungen ✅
- [x] Erinnerungs-System
- [x] E-Mail-Benachrichtigungen

---

## Phase 20: Produktion

### M20.1 - Produktion-Docker ✅
- [x] Optimierte Dockerfiles (multi-stage builds)
- [x] `docker-compose.prod.yml`
- [ ] SSL/TLS Zertifikate (erfordert externe Zertifikate / Reverse Proxy)

### M20.2 - CI/CD ✅
- [x] GitHub Actions für Tests (.github/workflows/ci.yml)
- [x] Automatische Builds (Dart AOT + Flutter Web)
- [ ] Deployment-Pipeline (erfordert Cloud-Infrastruktur)

### M20.3 - Monitoring ✅
- [x] Logging-System (Request-Logging mit Timing in logging_middleware.dart)
- [x] Health-Checks (GET /health, GET /health/ready)
- [x] Metriken (GET /health/metrics – uptime, requests, memory, DB stats)

---

## Umgebungsvariablen (.env)

```env
# Datenbank
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=mypet
POSTGRES_USER=mypet_user
POSTGRES_PASSWORD=secret

# Backend
BACKEND_PORT=8080
JWT_SECRET=your-super-secret-key
JWT_EXPIRY=3600

# Verschlüsselung
ENCRYPTION_KEY=your-encryption-key

# Datei-Upload
UPLOAD_PATH=/data/uploads
MAX_FILE_SIZE=10485760

# E-Mail (optional)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=noreply@example.com
SMTP_PASSWORD=secret

# Frontend URLs
OWNER_APP_URL=http://localhost:3001
VET_APP_URL=http://localhost:3002
PROVIDER_APP_URL=http://localhost:3003
```

---

## Docker Compose Struktur

```yaml
services:
  db:
    image: postgres:16
    # ...

  backend:
    build: ./backend
    depends_on: [db]
    # ...

  web-owner:
    build: ./web_owner
    # ...

  web-vet:
    build: ./web_vet
    # ...

  web-provider:
    build: ./web_provider
    # ...

  nginx:
    image: nginx:alpine
    # Reverse Proxy für alle Services
```

---

---

## Phase 21: Superadmin-System

> Kontrollierte Registrierung für Tierärzte und Dienstleister (Hufpfleger etc.) —
> keine offene Anmeldung für professionelle Rollen. Nur der Superadmin legt diese Accounts an.

### M21.1 - Superadmin-Rolle (Backend) ✅
- [x] Migration 009: `superadmin` zur `user_role` enum hinzufügen
- [x] `/auth/register` auf Rolle `owner` beschränken (vet/provider/superadmin gesperrt)
- [x] `requireSuperadmin`-Middleware

### M21.2 - Admin-API (Backend) ✅
- [x] `GET /admin/users` — alle Benutzer (mit Rollenfilter, Suche, Paginierung)
- [x] `POST /admin/users` — Benutzer mit Rolle vet/provider/owner anlegen
- [x] `GET /admin/users/:id` — Einzelnen Benutzer abrufen
- [x] `PUT /admin/users/:id` — Rolle, Name, Status ändern
- [x] `PUT /admin/users/:id/reset-password` — Passwort zurücksetzen
- [x] `DELETE /admin/users/:id` — Benutzer deaktivieren

### M21.3 - Web-Admin Frontend ✅
- [x] Flutter Web-Projekt `web_admin/` anlegen
- [x] Login-Screen (nur für superadmin, Rolle wird nach Login geprüft)
- [x] Benutzer-Liste mit Rollenfilter, Suche und Paginierung
- [x] Formular: Benutzer anlegen (Tierarzt / Dienstleister / Besitzer)
- [x] Benutzer-Detailansicht: Rolle & Status ändern, Passwort reset
- [x] Dockerfile + docker-compose Eintrag (Port 3004)

---

---

## Phase 22: Detail-Screen & Berechtigungen

### M22.1 - AnimalDetailScreen Verbesserungen ✅
- [x] Dokumente-Placeholder durch echte `_MediaCard` ersetzt (MediaProvider, 4 Vorschau-Einträge + Link zu /records)
- [x] `_MedicalRecordsCard` hinzugefügt — zeigt Einträge aus der med. Akte via OwnerHealthProvider (Typ-Badge, Datum, Diagnose, Tierarzt)
- [x] Leerer Zustand als wiederverwendbarer `_EmptyState`-Widget extrahiert

### M22.2 - „Teilen mit TA"-Dialog ✅
- [x] Button war dead code (`onPressed: (){}`), jetzt funktionierender Dialog
- [x] Eingabe: E-Mail der Person, Zugriffsstufe (lesen/schreiben/verwalten), optionales Ablaufdatum, Notiz
- [x] Ruft `PermissionProvider.grantPermission` mit `subjectEmail` auf

### M22.3 - Berechtigung erteilen (PermissionsScreen Fix) ✅
- [x] `PermissionProvider.grantPermission` unterstützt jetzt `subjectEmail` (Backend löst E-Mail → UUID serverseitig auf)
- [x] `permissions_screen.dart`: Berechtigung-erteilen-Dialog rief API bisher nie auf (TODO-Kommentar seit M5.3) — jetzt korrekt implementiert

### M22.4 - CLAUDE.md ✅
- [x] `CLAUDE.md` erstellt: Befehle, Architektur, Controller/Provider-Muster, Migrations-Workflow

---

## Phase 23: Dashboard, Medikamente, Gewicht & Bugfixes

### M23.1 - Medikations-Tracking (web_owner) ✅
- [x] `MedicationProvider` — `loadForPet`, `administer`, `skip` mit vollständigem Modell
- [x] `MedicationsScreen` — Pet-Selector, aktive/inaktive Medikamente, Gegeben/Übersprungen-Dialog
- [x] `AnimalDetailScreen` — `_MedicationsCard` mit 1-Klick-Gegeben-Button

### M23.2 - Dashboard Erinnerungen ✅
- [x] `_RemindersPanel` im Dashboard-Sidebar zeigt bis zu 4 ausstehende Erinnerungen
- [x] `ReminderProvider.load()` beim Login gestartet (nicht erst beim Navigieren zu /reminders)
- [x] "Kalender öffnen"-Button durch Link zu `/appointments` ersetzt

### M23.3 - Gewichtsverlauf im Tierprofil (web_owner) ✅
- [x] `AnimalDetailScreen` — `_WeightCard` mit Sparkline (CustomPainter), Trend-Badge, Quick-Add-Dialog
- [x] Lädt `WeightProvider` nur wenn `selectedPetId != petId`

### M23.4 - Compliance-Bug fix (web_vet) ✅
- [x] `patient_detail_screen`: `s['was_given']` existiert nicht → auf `s['status'] == 'given'` korrigiert
- [x] Adherence-Rate und Einzel-Einträge zeigten immer 0%/"Ausgelassen"

### M23.5 - services_screen API-Anbindung (web_provider) ✅
- [x] Leistungen wurden nur lokal in `_entries` gehalten (TODO seit Phase 12)
- [x] Pet-Auswahl lädt `GET /pets/:id/records`, Erfassen ruft `POST /pets/:id/records` auf
- [x] `Provider<ApiService>` in `web_provider/main.dart` ergänzt

---

---

## Phase 24: Kunden-Detailansicht, Transfer-Preview & Profilverwaltung

### M24.1 - web_provider: CustomerDetailScreen ✅
- [x] `CustomerDetailScreen` — 4-Tab-Ansicht (Übersicht, Akte, Meine Notizen, Meine Leistungen)
- [x] Parallel-API-Calls mit `Future.wait()` für Impfungen, Medikamente, Akteneinträge
- [x] Tab 1: Impfstatus (abgelaufen/bald ablaufend farblich markiert), aktive Medikamente
- [x] Tab 2: Med. Akte — nicht-private Einträge mit Typ-Badge, Tierarzt, Datum
- [x] Tab 3: Eigene Notizen mit CRUD (ProviderNotesProvider)
- [x] Tab 4: Eigene Leistungen mit Erfassen-Dialog
- [x] Route `/customers/:petId` verdrahtet; `_PetCard` navigiert per `context.go` statt Dialog

### M24.2 - Transfer-Preview (web_owner) ✅
- [x] Backend: `GET /transfers/:token` — liefert Tier-Name, Spezies, Rasse, Absender, Nachricht, Status
- [x] `TransferProvider.lookup()` — fragt Vorschau-Endpoint ab
- [x] `TransferScreen` — 2-Schritt-Flow: Token eingeben → Vorschau-Karte → Annehmen/Ablehnen
- [x] Nicht-ausstehende Transfers werden korrekt als inaktiv angezeigt (kein Accept/Reject-Button)

### M24.3 - Profil & Passwort (web_owner) ✅
- [x] `AuthProvider.updateProfile()` — ruft `PUT /account` auf, updated lokalen User
- [x] `AuthProvider.changePassword()` — ruft `PUT /account/password` auf
- [x] `User.copyWith()` hinzugefügt
- [x] `SettingsScreen` — "Profil bearbeiten"-Dialog (Name/E-Mail), "Passwort ändern"-Dialog

---

---

## Phase 25: Settings, Bugfixes & Admin Dashboard

### M25.1 - Settings-Screens (web_vet & web_provider) ✅
- [x] `VetSettingsScreen` — Profil bearbeiten (Name/E-Mail), Passwort ändern
- [x] `ProviderSettingsScreen` — identisch für web_provider
- [x] `VetAuthProvider` + `ProviderAuthProvider` — updateProfile() + changePassword()
- [x] `shared/User.copyWith(name, email)` hinzugefügt
- [x] Sidebar-NavItem "Einstellungen" in beiden Apps
- [x] Fehlende `/register`-Route in web_vet und web_provider verdrahtet

### M25.2 - ApiService-Bugfixes ✅
- [x] `marketplace_screen` + `_BookAppointmentDialog` nutzten `ApiService()` direkt → auf `context.read<ApiService>()` umgestellt
- [x] web_owner Sidebar: „Einstellungen"-Eintrag ergänzt
- [x] `_MedicalRecordsCard`: „+ X weitere →" Button öffnet Dialog mit vollständiger Liste

### M25.3 - Admin Dashboard ✅
- [x] Backend: `GET /admin/stats` — Nutzer/Tier/Org-Counts + 7-Tage-Delta
- [x] `AdminDashboardScreen` — Statistik-Grid (8 Kacheln) + Schnellzugriff
- [x] Route `/` zeigt jetzt Dashboard, `/users` zeigt Benutzerliste
- [x] `Provider<ApiService>` in web_admin MultiProvider ergänzt

---

## Phase 26: Media-Download, Einladungen & UI-Fixes

### M26.1 - Media Download/View ✅
- [x] `records_screen` (web_owner): Öffnen/Download-Button auf jeder Mediakarte (html.window.open)
- [x] `patient_detail_screen` (web_vet): identischer Button im Bildarchiv-Tab

### M26.2 - Einladungs-Management ✅
- [x] `OrganizationProvider` (web_vet + web_provider): loadInvitations(), acceptInvitation(), rejectInvitation()
- [x] Organisations-Screen zeigt Banner mit ausstehenden Einladungen (Annehmen/Ablehnen)

### M26.3 - UI-Fixes ✅
- [x] `patient_detail_screen` (web_vet): AppBar zeigt jetzt den Tiernamen statt "Patient"
- [x] `settings_screen` (web_owner): Gefahrenzone-Sektion mit Konto-Löschen + E-Mail-Bestätigung
- [x] `admin_controller`: GET /admin/organizations + organizations_screen in web_admin

---

## Phase 27: Akten-Tab, Marktplatz-Termin & Sidebar-Badge

### M27.1 - Krankenakte-Tab im records_screen ✅
- [x] 4. Tab „Krankenakte" in `records_screen` (web_owner) via OwnerHealthProvider
- [x] Pet-Selektor lädt jetzt auch Health-Daten; Titel zu „Akten & Medien" aktualisiert

### M27.2 - Marktplatz „Termin anfragen" ✅
- [x] `BookAppointmentDialog` zu öffentlicher Klasse gemacht
- [x] Marktplatz-OrgCard: „Termin anfragen"-Button öffnet Buchungsdialog vorausgewählt
- [x] `BookAppointmentDialog`: preselectedOrg-Parameter + Re-Matching nach Org-Ladelauf

### M27.3 - Sidebar-Badge für überfällige Erinnerungen ✅
- [x] `_BadgeIcon`-Widget in sidebar.dart (rote Zahl-Badge)
- [x] `Sidebar._buildBadges()` liest ReminderProvider aus; `/reminders`-Route erhält Badge
- [x] `_SidebarNavItem`: badge-Parameter + Expanded-Wrap für Label

---

## Phase 28: UX-Verbesserungen & Bugfixes II

### M28.1 - Appointment-Badge ✅
- [x] Sidebar (web_owner): Badge auf `/appointments` bei ausstehenden Terminanfragen

### M28.2 - Ablaufende Impfungen ✅
- [x] Backend: `GET /vaccinations/expiring?days=30` (aggregateRouter, joins pets + access_permissions)
- [x] web_vet Dashboard: Amber-Panel mit ablaufenden Impfungen; Einträge ≤7 Tage rot

### M28.3 - Navigation & Pre-selection ✅
- [x] Tier-Detail: Pet-Switcher-Dropdown wenn > 1 Tier vorhanden
- [x] Tier-Detail: „Zum Futterplan →" Button in Fütterungs-Karte (FeedingProvider.selectPet)
- [x] Medication-Screen pre-selects correctly from animal detail (MedicationProvider.selectedPetId)

### M28.4 - Bugfixes ✅
- [x] web_provider `_ServicesTab`: filtert Records jetzt auf eigene (`vet_id == currentUser.id`)
- [x] Backend GET /pets: JOIN users für owner_name + owner_email

---

## Phase 29: Badges, Eager-Loading & Dashboard-Quickactions

### M29.1 - Appointment-Badges in web_vet & web_provider ✅
- [x] VetAppShell und ProviderAppShell: Pending-Badge auf Termine-Eintrag
- [x] VetAppShell._NavItem + ProviderAppShell._NavItem unterstützt badge-Parameter

### M29.2 - Eager Data Loading ✅
- [x] web_vet: _AppShell lädt Termine + Patienten nach Login (StatefulWidget)
- [x] web_provider: _AppShell lädt Termine + Kunden nach Login (StatefulWidget)

### M29.3 - UX: Animal Detail Improvements ✅
- [x] `_AppointmentsCard`: zeigt anstehende Termine für das aktuelle Tier
- [x] Dashboard `_RemindersPanel`: Quick-Dismiss-Button (✓) für überfällige Erinnerungen
- [x] backend + web_vet: GET /vaccinations/expiring + ExpiringVaccinationsPanel im Vet-Dashboard
- [x] web_vet: Provider<ApiService> in MultiProvider ergänzt

---

## Legende

- [ ] Offen
- [x] Erledigt
- 🚧 In Arbeit

---

## Notizen

*Anpassungen und Änderungen an der Roadmap hier dokumentieren.*
