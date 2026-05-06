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

## Phase 30: UX-Verbesserungen Termine & Detailansichten ✅ *(2026-05-03)*

### M30.1 - No-Show & Ablaufende Impfungen für Dienstleister ✅
- [x] `web_provider`: `markNoShow()` + "Nicht erschienen"-Button bei bestätigten Terminen
- [x] `web_provider` Dashboard: Ablaufende-Impfungen-Panel (GET /vaccinations/expiring, 30 Tage)
- [x] Klick → navigiert zur Kundendetailansicht

### M30.2 - Navigation & Termine in Detailansichten ✅
- [x] `web_vet` + `web_provider`: Terminkarten anklickbar → navigieren zur Patienten-/Kundendetailansicht
- [x] `web_vet` PatientDetailScreen: 7. Tab "Termine" (gefiltert nach petId, chronologisch)
- [x] `web_provider` CustomerDetailScreen: 5. Tab "Termine"

### M30.3 - Bugfixes ✅
- [x] `web_owner/auth_provider.dart`: Duplikat-Deklarationen `updateProfile`/`changePassword` entfernt
- [x] `web_owner/marketplace_screen.dart`: fehlendes `],` + `_BookAppointmentDialog` → `BookAppointmentDialog`

---

## Phase 31: Termin anlegen, Gewicht & Fütterung in Detailansichten ✅ *(2026-05-03)*

### M31.1 - Termin anlegen von Tierarzt- und Dienstleister-Seite ✅
- [x] `web_vet` Termine-Screen: "Neuer Termin"-Button + Dialog (Patient, Datum/Zeit, Titel, Dauer, Ort)
- [x] `web_provider` Termine-Screen: "Neuer Termin"-Button + Dialog (Kunde aus CustomersProvider)
- [x] POST /appointments mit provider_id (Standard: eingeloggter User)

### M31.2 - Gewichtsverlauf-Tab im Patientendetail ✅
- [x] `web_vet` PatientDetailScreen: 8. Tab "Gewicht" (GET /pets/:id/weight)
- [x] Aktuelles Gewicht + Trend-Anzeige (↑/↓ vs. Voreintrag), Liste aller Einträge mit Datum/Notiz

### M31.3 - Fütterungsplan-Tab in Detailansichten ✅
- [x] `web_vet` PatientDetailScreen: 9. Tab "Fütterung" (aktive Pläne, Mahlzeiten mit Zutaten, read-only)
- [x] `web_provider` CustomerDetailScreen: 6. Tab "Fütterung" (parallel geladen, read-only)

---

## Phase 32: Appointment-UX, Impfungs-Reminder & Gewicht Dienstleister ✅ *(2026-05-03)*

### M32.1 - Appointment-Karten verbessert (web_owner) ✅
- [x] Karte zeigt jetzt Dauer, Ort, Beschreibung, Praxisname
- [x] Absagegrund als farbiges Info-Banner bei abgesagten Terminen
- [x] "Absagen"-Link direkt in Karte (statt separatem IconButton)
- [x] Aufteilung in Sektionen: "Ausstehend" / "Bestätigt" / "Vergangen"
- [x] "Vergangen": max. 5 Einträge, erweiterbar über "Alle X anzeigen"
- [x] Sektions-Header mit Anzahl-Badge

### M32.2 - Impfungs-Erinnerung (web_owner) ✅
- [x] AnimalDetailScreen: Alarm-Icon bei Impfungen mit ≤ 60 Tagen Restlaufzeit
- [x] Klick legt automatisch Erinnerung 14 Tage vor Ablauf an

### M32.3 - Gewichts-Tab CustomerDetailScreen (web_provider) ✅
- [x] 7. Tab "Gewicht" mit aktuellem Wert, Trend-Anzeige (↑/↓) und Eintrags-Liste

---

## Phase 33: Owner-Dashboard Impfungen & Pet-Alter ✅ *(2026-05-03)*

### M33.1 - Ablaufende Impfungen im Besitzer-Dashboard ✅
- [x] `DashboardScreen` zu `StatefulWidget` umgebaut
- [x] Lädt `GET /vaccinations/expiring?days=30` beim Start
- [x] Zeigt Amber-Panel mit Ampelfarben (≤7 Tage = rot), Link zu /animals

### M33.2 - Pet-Alter auf der Karte ✅
- [x] `PetCard`: zeigt Alter in Jahren neben Rasse (z.B. "LABRADOR · 3 J.")

---

## Phase 34: No-show Fix, Medikamenten-Erinnerung & Dashboard-Panel ✅ *(2026-05-03)*

### M34.1 - Backend: no-show widerruft Zugriff ✅
- [x] `_noShow` im AppointmentController setzt terminbezogene access_permissions auf NOW() (wie `_complete`)

### M34.2 - Medikamenten-Erinnerung (web_owner) ✅
- [x] MedicationsScreen: "Erinnerung anlegen"-Button wenn Medikament ≤3 Tage bis Ablauf
- [x] Legt Reminder 1 Tag vor Enddate an, Typ = 'medication'

### M34.3 - Dashboard Medikamenten-Panel (web_owner) ✅
- [x] Rechtes Panel zeigt aktive Medikamente (max 4) mit Dosierung, Frequenz, Link zu /medications
- [x] Ablaufende Medikamente (endsSoon) in Amber-Farbe hervorgehoben

---

## Phase 35: Termin-Validierung, Tier-Suche & Erinnerungs-Filter ✅ *(2026-05-03)*

### M35.1 - Backend: Appointment-Validierung ✅
- [x] `POST /appointments`: scheduled_at in der Vergangenheit → 400 (5-Min-Puffer)

### M35.2 - web_owner Animals-Screen Suche ✅
- [x] Suchfeld erscheint ab 3 Tieren, filtert nach Name/Rasse/Spezies
- [x] Subtitle zeigt "X von Y Tieren" wenn gefiltert

### M35.3 - web_owner Erinnerungs-Filter ✅
- [x] Typ-Filter-Chips: Alle / Impfungen / Medikamente / Termine / Sonstiges
- [x] Animierter Filter-Chip-Style

### M35.4 - Dashboard Medikamenten-Fix ✅
- [x] Medikamenten-Panel lädt jetzt alle Tiere in `initState` (nicht nur aktiv gewähltes)

---

## Phase 36: Impfungen für Besitzer & Patienten-Sortierung ✅ *(2026-05-03)*

### M36.1 - Impfungs-CRUD für Besitzer ✅
- [x] `OwnerHealthProvider`: `addVaccination()` + `deleteVaccination()`
- [x] `_VaccinationCard`: "Impfung eintragen"-Button (Impfstoff/Charge/Hersteller/Datum/Ablauf)
- [x] `_VaccinationCard`: Löschen-Button auf jeder Impfzeile
- [x] `_DetailCard`: optionaler `action`-Parameter im Header

### M36.2 - web_vet Patienten-Sortierung ✅
- [x] Sortier-Chips: Name / Tierart / Besitzer
- [x] Suche jetzt auch auf Besitzername
- [x] Patienten-Zähler neben Sortierung

---

## Phase 37: Familien-Zugriff, Einladungscodes & QR-Code ✅ *(2026-05-03)*

### M37.1 - Kritischer Bugfix: Terminbestätigung HTTP 500 ✅
- [x] `appointment_controller._confirm/_complete/_noShow`: access_permissions-INSERT/UPDATE
  verwendete falsche Spaltennamen → `subject_user_id`, `permission`, `ends_at`, `note`

### M37.2 - Familienmitglieder sehen Tiere ✅
- [x] `pet_access.dart`: Familien-Check via JOIN über `family_members` beider User
- [x] Familienmitglieder bekommen automatisch Lesezugriff (kein `requireWrite` nötig)

### M37.3 - Familien-Einladungscodes ✅
- [x] Migration 025: Tabelle `family_invite_codes` (UNIQUE pro Familie, expires_at, used_by)
- [x] `POST /families/:id/invite-code` → 8-stelliger Code, 7 Tage gültig
- [x] `GET /families/join/:code` → Familien-Vorschau ohne Beitritt
- [x] `POST /families/join/:code` → Beitritt, Code wird als used markiert

### M37.4 - QR-Code & Beitreten-Dialog (web_owner) ✅
- [x] `_FamilyCard`: QR-Icon öffnet Dialog mit QR-Code (qr_flutter) + kopierbarem Code
- [x] Header: "Per Code beitreten"-Button mit Such-Dialog und Familien-Vorschau

---

---

## Phase 38: System-Einladungen, CanvasKit-Fix & Familien-Admin ✅ *(2026-05-03)*

### M38.1 - Interne Familieneinladungen (kein E-Mail) ✅
- [x] Migration 026: Tabelle `family_invitations` (invitee_id, invited_by, status enum, message)
- [x] `POST /families/:id/members` erstellt jetzt interne Einladung statt direktem Beitritt
- [x] `GET /families/invitations`, `POST /families/invitations/:id/accept`, `.../reject`
- [x] `FamilyInvitationProvider` in web_owner (load, accept, reject, pendingCount)
- [x] `_InvitationBanner` auf FamiliesScreen + Dashboard
- [x] Badge auf Sidebar-Eintrag `/families` bei ausstehenden Einladungen
- [x] `main.dart`: FamilyInvitationProvider registriert, lädt nach Login

### M38.2 - CanvasKit-Fix (kein CDN-Abruf mehr) ✅
- [x] Alle Dockerfiles: `flutter build web --release --dart-define=FLUTTER_WEB_CANVASKIT_URL=canvaskit/`
- [x] CanvasKit wird aus dem lokalen Build-Output geladen (kein gstatic.com)

### M38.3 - Familien-Admin: Umbenennen & Löschen ✅
- [x] `FamilyProvider.renameFamily()` + `deleteFamily()` hinzugefügt
- [x] `_FamilyCard`: Bearbeiten-Button (Stift) öffnet Umbenennen-Dialog
- [x] `_FamilyCard`: Löschen-Button (Papierkorb, nur für Admin) mit Bestätigungsdialog
- [x] Admin-Erkennung via `family.createdBy == authProvider.user?.id`

---

## Phase 39: Benachrichtigungszentrale (web_owner) ✅ *(2026-05-03)*

### M39.1 - Notifications-Screen ✅
- [x] `notifications_screen.dart`: Aggregiert aus FamilyInvitationProvider, ReminderProvider, AppointmentProvider
- [x] Typen: Familieneinladung, überfällige/heute fällige Erinnerungen, ausstehende Terminanfragen
- [x] Familieneinladungen mit Accept/Reject direkt im Screen
- [x] Sortierung: Kritische zuerst (überfällig/Einladungen), dann nach Datum
- [x] Leerer Zustand mit "Alles erledigt!"-Meldung

### M39.2 - Sidebar-Integration ✅
- [x] Neuer Eintrag "Benachrichtigungen" (Bell-Icon) in der Konto-Sektion
- [x] Badge-Zähler: Summe aus Familieneinladungen + überfälligen + heute fälligen Erinnerungen + Terminanfragen
- [x] Route `/notifications` in go_router registriert

---

## Phase 40: Rezepte-Verwaltung (web_vet + web_owner) ✅ *(2026-05-03)*

### M40.1 - Backend: Rezepte-Tabelle + Endpunkte ✅
- [x] Migration 027: Tabelle `prescriptions` (drug_name, dosage, frequency, duration_days, instructions, valid_until, refills_remaining)
- [x] `PrescriptionController`: `GET/POST /pets/:id/prescriptions`, `DELETE /pets/:id/prescriptions/:prescId`
- [x] Nur Tierärzte können Rezepte ausstellen, Löschen nur durch Aussteller
- [x] In petsCascade eingehängt

### M40.2 - web_vet: Rezepte-Tab in PatientDetailScreen ✅
- [x] `PrescriptionProvider` (load, create, delete)
- [x] 10. Tab „Rezepte" in `patient_detail_screen.dart` (TabBar scrollable gemacht)
- [x] Ausstellungs-Dialog: Medikament, Dosierung, Häufigkeit, Dauer, Anweisungen, Gültig bis, Wiederholungen
- [x] Abgelaufene Rezepte werden durchgestrichen + Badge „Abgelaufen"
- [x] In `main.dart` registriert

### M40.3 - web_owner: Rezepte-Karte im Tier-Profil ✅
- [x] `OwnerPrescriptionProvider` (read-only view)
- [x] `_PrescriptionsCard` im AnimalDetailScreen (zwischen Medikamente und Gewicht)
- [x] Zeigt ausstellenden Arzt, Dosierung, Datum
- [x] In `main.dart` registriert

---

## Phase 41: QR-Code & Tier-Identifikation (web_owner) ✅ *(2026-05-03)*

### M41.1 - Pet QR-Code ✅
- [x] "QR-Code"-Button im AnimalDetailScreen-Header (neben Bearbeiten/Teilen)
- [x] Dialog zeigt QR-Code mit Name, Tierart/Rasse, Chip-Nummer
- [x] "Kopieren"-Button kopiert Tier-Info in die Zwischenablage
- [x] Nutzung von `qr_flutter` (bereits als Dependency vorhanden)
- [x] `flutter/services.dart` für Clipboard importiert

---

## Phase 42: Service-Honorar Tracking (web_provider + Backend) ✅ *(2026-05-03)*

### M42.1 - Backend: Honorar-Felder für Termine ✅
- [x] Migration 028: `service_fee_cents`, `service_fee_currency`, `service_fee_note` zu `appointments`
- [x] `PUT /appointments/:id/fee` — nur Dienstleister des Termins kann Honorar setzen
- [x] `_sanitize` in AppointmentController gibt Honorar-Felder zurück

### M42.2 - web_provider: Honorar setzen & anzeigen ✅
- [x] `ProviderAppointment` Model: Felder `serviceFeeCents`, `serviceFeeNote`, Getter `serviceFeeFormatted`
- [x] `ProviderAppointmentProvider.setFee()` — PUT /appointments/:id/fee
- [x] Vergangene Termine: „Honorar setzen / bearbeiten" Button
- [x] Dialog: Betrag (€) + optionale Notiz
- [x] Appointment-Karte zeigt Honorar mit Euro-Icon wenn gesetzt
- [x] Dashboard: Neues Summary-Kachel „Umsatz diesen Monat" (Summe aller Honorare im aktuellen Monat)

---

## Phase 43: Geburtstags-Benachrichtigungen (web_owner) ✅ *(2026-05-03)*

### M43.1 - Dashboard: Geburtstags-Panel ✅
- [x] `_BirthdayPanel`: zeigt Tiere mit Geburtstag in nächsten 14 Tagen
- [x] Anzeige: Tierart-Emoji, Name, „wird X Jahre", Tage bis Geburtstag
- [x] Lokale Berechnung auf Basis von `pet.birthDate` (kein API-Call)

### M43.2 - Notification Center: Geburtstag-Typ ✅
- [x] Neuer `_NotifType.birthday` in `notifications_screen.dart`
- [x] Kuchen-Icon (pink) für Geburtstags-Benachrichtigungen
- [x] Sidebar-Badge zählt auch bevorstehende Geburtstage

---

## Phase 44: Pet-Notizen für Besitzer (web_owner) ✅ *(2026-05-03)*

### M44.1 - Notizen-Feature im Tier-Profil ✅
- [x] `OwnerNotesProvider` (CRUD: load, create, update, delete)
- [x] `_NotesCard` in `animal_detail_screen.dart` (unter Terminen)
- [x] Dialog: Titel + Inhaltsfeld, Bearbeiten-Dialog mit Vorbelegen
- [x] Direkt-Löschen per Papierkorb-Icon
- [x] `+`-Button im Card-Header für schnelles Hinzufügen
- [x] In `main.dart` registriert

---

## Phase 45: Android App — Tierbesitzer (android_owner) ✅ *(2026-05-03)*

### M45.1 - Flutter Android Projekt & Infrastruktur ✅
- [x] `android_owner/` — neues Flutter-Projekt, kein `dart:html`
- [x] `pubspec.yaml`: `shared_preferences`, `image_picker`, `qr_flutter`, `mypet_shared`
- [x] `AndroidManifest.xml`: INTERNET, CAMERA, READ_EXTERNAL_STORAGE Permissions
- [x] `android_owner/Dockerfile` — Multi-Stage Build: Flutter-Image → Alpine mit APK
- [x] `docker-compose.yml`: Service `android-owner` (profile: android)
- [x] `CLAUDE.md` aktualisiert mit Android-Build-Anleitung

### M45.2 - App-Screens ✅
- [x] `LoginScreen` — Login + Registrierung, Token-Speicherung via `shared_preferences`
- [x] `MobileAuthProvider` — JWT-Login mit persistentem Token
- [x] `MainShell` — Bottom Navigation Bar (5 Tabs mit Badges)
- [x] `DashboardScreen` — Begrüßung, Stats-Chips, überfällige Erinnerungen, nächste Termine
- [x] `PetsScreen` + `PetDetailScreen` — Tierliste + Detail (3 Tabs: Impfungen, Medikamente, Akte)
- [x] `RemindersScreen` — Offene Erinnerungen, Hinzufügen-Dialog, Erledigt-Funktion
- [x] `AppointmentsScreen` — Bevorstehend/Vergangen, Statusanzeige
- [x] `ProfileScreen` — Benutzerdaten, Abmelden
- [x] API-URL: `http://10.0.2.2:8080` (Android-Emulator → Host-Machine)

---

## Legende

- [ ] Offen
- [x] Erledigt
- 🚧 In Arbeit

---

---

## Phase 46: Allergie-Management ✅ *(2026-05-04)*

### M46.1 - Backend: Allergien-Tabelle + Endpunkte ✅
- [x] Migration 029: Tabelle `pet_allergies` (allergen, category, severity enum, reaction, diagnosed_at)
- [x] `AllergyController`: `GET/POST/PUT/DELETE /pets/:id/allergies`
- [x] Zugriffskontrolle via `petHasAccess()`, Schreibschutz für Fremdzugriff
- [x] In petsCascade eingehängt

### M46.2 - web_owner: Allergie-Karte im Tierprofil ✅
- [x] `AllergyProvider` (loadForPet, addAllergy, updateAllergy, deleteAllergy)
- [x] `_AllergiesCard` in `animal_detail_screen.dart` (zwischen Rezepte-Karte und Medikamente)
- [x] Add/Edit-Dialog mit Allergen, Kategorie, Schweregrad, Reaktion, Diagnosedatum
- [x] Farbige Severity-Badges (grün/orange/rot)
- [x] In `main.dart` registriert

### M46.3 - web_vet: Allergien-Tab im Patientendetail ✅
- [x] `VetAllergyProvider` (loadForPet, add, delete)
- [x] 5. Tab „Allergien" in `patient_detail_screen.dart` (nach Rezepte, vor Bildarchiv)
- [x] Tierarzt kann Allergien eintragen und löschen
- [x] In `main.dart` registriert

### M46.4 - web_provider: Allergien-Tab (read-only) ✅
- [x] `ProviderAllergyProvider` (loadForPet, read-only)
- [x] 2. Tab „Allergien" in `customer_detail_screen.dart`
- [x] Dienstleister sieht Allergien, kann aber keine anlegen (Sicherheit)
- [x] In `main.dart` registriert

---

## Phase 47: Notfallkontakte (web_owner) ✅ *(2026-05-04)*

### M47.1 - Backend: Notfallkontakte-Tabelle + Endpunkte ✅
- [x] Migration 030: Tabelle `emergency_contacts` (name, relationship, phone, email, is_primary)
- [x] `EmergencyContactController`: `GET/POST/PUT/DELETE /emergency-contacts`
- [x] Primärkontakt-Logik: beim Setzen von `is_primary = true` werden andere zurückgesetzt
- [x] In `server.dart` als `/emergency-contacts` gemountet

### M47.2 - web_owner: Notfallkontakte-Screen ✅
- [x] `EmergencyContactProvider` (load, add, update, delete)
- [x] `EmergencyContactsScreen` — Listenansicht mit Add/Edit/Delete
- [x] Primärkontakt-Badge, Telefon/E-Mail-Anzeige
- [x] Route `/emergency-contacts` in go_router registriert
- [x] Sidebar-Eintrag unter „Konto"
- [x] Link aus Einstellungen-Screen
- [x] Laden nach Login
- [x] In `main.dart` registriert

---

## Phase 48: DSGVO Datenexport (erweiterter Export) ✅ *(2026-05-04)*

### M48.1 - Backend: Umfassender Datenexport ✅
- [x] `GET /account/export` erweitert: Impfungen, Medikamente, Allergien, Termine, Erinnerungen, Notfallkontakte
- [x] Content-Disposition Header für direkten Browser-Download
- [x] `format_version: "1.0"` für zukünftige Kompatibilität

---

## Phase 49: Gewichtsziel-Tracking ✅ *(2026-05-04)*

### M49.1 - Backend: Gewichtsziel-Felder ✅
- [x] Migration 031: `weight_goal_kg` + `weight_goal_note` zu `pets`
- [x] `PUT /pets/:id/weight/goal` in `WeightController`
- [x] `_sanitizePet` gibt `weight_goal_kg` + `weight_goal_note` zurück
- [x] Alle SELECT-/RETURNING-Queries um die neuen Felder erweitert

### M49.2 - web_owner: Ziel-Anzeige & Setzen ✅
- [x] `Pet`-Model: `weightGoalKg` + `weightGoalNote`
- [x] `WeightProvider.setGoal()` — PUT /pets/:id/weight/goal
- [x] `_WeightCard`: Flag-Button öffnet Ziel-Dialog (Wert + Notiz)
- [x] `_WeightGoalBadge` — zeigt Differenz zum Ziel, bei Erreichen grüner Erfolgstext

---

## Phase 50: Admin-Aktivitätsprotokoll ✅ *(2026-05-04)*

### M50.1 - Backend: Admin Audit-Log Endpoint ✅
- [x] `GET /admin/audit-log` mit Filter (action, user_id) und Paginierung (limit/offset)
- [x] JOIN mit users für Name + E-Mail des Akteurs
- [x] Gesamt-Count für Seitenwechsel

### M50.2 - web_admin: AuditLogScreen ✅
- [x] Filterbar (nach Aktion), Paginierung (50 Einträge/Seite)
- [x] Aktionstyp-Icons (Login/Create/Delete/Update/Transfer)
- [x] Ressourcentyp-Badge, IP-Adresse, Benutzer-Info
- [x] Quicklink-Kachel im Admin-Dashboard

---

## Phase 51: Passwort-Stärke-Indikator ✅ *(2026-05-04)*

### M51.1 - Passwort-Stärke-Widget ✅
- [x] `PasswordStrengthIndicator`-Widget in web_owner (4-stufige Farbbalken-Anzeige)
- [x] Bewertung nach Länge (≥8, ≥12), Großbuchstaben, Zahlen, Sonderzeichen
- [x] Stufen: Schwach / Mittel / Gut / Stark (rot/orange/grün/dunkelgrün)
- [x] In `RegisterScreen` (web_owner) eingebaut
- [x] Inline `_PasswordStrengthBar` in web_vet + web_provider Register-Screens

---

## Phase 52: Tier-Statistiken im Dashboard ✅ *(2026-05-04)*

### M52.1 - Dashboard Übersichts-Panel ✅
- [x] `_PetStatsSummary`: zeigt Anzahl Tiere, Durchschnittsalter, Artverteilung
- [x] `_StatChip`: Icon + Wert + Label im kompakten Chip-Format
- [x] Erscheint nur wenn mindestens 1 Tier vorhanden

---

## Phase 53: Suche im Erinnerungs-Screen ✅ *(2026-05-04)*

### M53.1 - Textsuchfeld in RemindersScreen ✅
- [x] Suchfeld mit Clear-Button über den Filter-Chips
- [x] Filtert nach Titel und Notiz-Text
- [x] Leertext-Meldung zeigt Suchbegriff: „Keine Ergebnisse für „{query}""

---

## Phase 54: Gewichtsziel-Integration im Gewichts-Screen ✅ *(2026-05-04)*

### M54.1 - Gewichtsziel im WeightScreen ✅
- [x] "Ziel setzen / anpassen"-Button in der Stats-Zeile
- [x] Ziel-StatCard wenn Ziel gesetzt (teal)
- [x] `_showGoalDialog()` direkt im WeightScreen (setzt Ziel via WeightProvider.setGoal)
- [x] "Ziel entfernen"-Option wenn Ziel schon gesetzt

---

## Phase 55: Erweiterter Notfall-QR-Dialog (web_owner) ✅ *(2026-05-04)*

### M55.1 - Umfassender Notfall-Info-Dialog ✅
- [x] QR-Code enthält jetzt: Name, Tierart/Rasse, Chip, schwere Allergien, aktive Medikamente, Primär-Notfallkontakt
- [x] Dialog-UI: strukturierte `_InfoSection`-Karten mit farbiger Hervorhebung
- [x] Allergie-Sektion (rot) und Notfallkontakt-Sektion (blau)
- [x] Import von EmergencyContactProvider + AllergyProvider
- [x] `_InfoSection`-Widget am Ende der Datei

---

## Phase 56: Vet-Patienten nach letztem Termin sortieren ✅ *(2026-05-04)*

### M56.1 - Sortierkriterium "Letzter Termin" ✅
- [x] `_sortBy = 'recent'` in PatientsScreen
- [x] `_lastAppt(petId)` — sucht letzten vergangenen Termin aus VetAppointmentProvider
- [x] Patienten ohne Termin erscheinen zuletzt
- [x] Sortier-Chip "Letzter Termin" neben den bestehenden Chips

---

## Phase 57: Provider-Dashboard erweiterte Statistiken ✅ *(2026-05-04)*

### M57.1 - Zusätzliche Stat-Kacheln ✅
- [x] "Heute"-Kachel: Anzahl der Termine heute (blau)
- [x] "Abgeschlossen (Monat)"-Kachel: completed appointments im laufenden Monat (teal)
- [x] Stats-Grid auf `Wrap` umgestellt (responsive Layout)
- [x] "Bestätigt" statt "Bestätigte Termine" (kompaktere Beschriftung)

---

## Phase 58: Transfer-Historie im Tier-Profil (web_owner) ✅ *(2026-05-04)*

### M58.1 - Besitzerhistorie-Karte ✅
- [x] `_TransferHistoryCard`: zeigt vergangene Übergaben via `TransferProvider.loadForPet()`
- [x] Status-Badge (ausstehend/abgeschlossen/abgelehnt/storniert) mit Farbe
- [x] Empfänger-E-Mail, Absender-Name, Datum
- [x] Karte erscheint nur wenn Transfers vorhanden
- [x] Platziert zwischen Notizen-Karte und Transfer-Buttons

---

## Phase 59: Backend - Termin-Überschneidungs-Check ✅ *(2026-05-04)*

### M59.1 - Overlap-Validierung bei Terminerstellung ✅
- [x] POST /appointments: Prüft ob Provider/Org bereits einen Termin ±30 Min. hat
- [x] Nur für vet und provider Rollen aktiv (Owner-Buchungen werden nicht blockiert)
- [x] Gibt HTTP 409 Conflict zurück: „Es gibt bereits einen Termin in diesem Zeitfenster (±30 Min.)"

---

## Phase 60: Medikamenten-Restmenge-Anzeige (web_owner) ✅ *(2026-05-04)*

### M60.1 - Verbleibende Dosen & Tage ✅
- [x] `Medication.daysRemaining` — verbleibende Tage bis `endDate`
- [x] `Medication.dosesPerDay` — Dosen pro Tag je nach Frequenz
- [x] `Medication.estimatedDosesLeft` — geschätzte Restdosen
- [x] `MedicationsScreen`: `_MetaChip` "X Tage · ~Y Dosen" in Medikamenten-Karte
- [x] Chip erscheint nur wenn `endDate` gesetzt und noch verbleibende Tage > 0

---

## Phase 61 & 62: Vet-Kalender-Ansicht & Provider Appointments ✅ *(2026-05-04)*

### M62.1 - Kalender-Tab im Vet-Appointments-Screen ✅
- [x] 4. Tab „Kalender" in `VetAppointmentsScreen` (TabController: 3 → 4)
- [x] `_CalendarView`: 7-Tage-Wochenansicht (Mo-So)
- [x] Navigation: Zurück/Weiter (±7 Tage) + "Heute"-Button
- [x] Termine als farbige Kacheln je nach Status (orange/grün/grau/rot)
- [x] Klick auf Termin navigiert zur Patienten-Detailansicht
- [x] Heutige Spalte wird hellblau hinterlegt
- [x] `_mondayOf()` berechnet Wochenanfang (ISO Monday)

---

## Phase 63: Fütterungs-Compliance-Anzeige (web_owner) ✅ *(2026-05-04)*

### M63.1 - Compliance-Balken im Fütterungs-Protokoll ✅
- [x] `_ComplianceBar`: zeigt % der gefütterten Mahlzeiten der letzten 7 Tage
- [x] Farbcodierung: ≥90% grün, ≥70% orange, <70% rot
- [x] Linearer Fortschrittsbalken + Text (X/Y Mahlzeiten)
- [x] Erscheint über dem Protokoll wenn mindestens ein Eintrag vorhanden

---

---

## Phase 64: Behandlungsnotizen für Termine ✅ *(2026-05-06)*

### M64.1 - Backend: Behandlungsnotizen ✅
- [x] Migration 032: `treatment_notes` + `diagnosis` zu `appointments`
- [x] `PUT /appointments/:id/notes` — nur Tierarzt/Dienstleister des Termins

### M64.2 - web_vet: Notizen setzen ✅
- [x] `VetAppointment`: `treatmentNotes` + `diagnosis` Felder
- [x] `VetAppointmentProvider.setNotes()` — PUT /appointments/:id/notes
- [x] Vergangene Termine: „Behandlungsnotizen"-Button + Dialog (Diagnose + Notizen)
- [x] Terminkarte zeigt Diagnose (blau) + Notizen inline an

### M64.3 - web_owner: Behandlungsbericht anzeigen ✅
- [x] `Appointment`-Model: `treatmentNotes` + `diagnosis`
- [x] Abgeschlossene Termine zeigen Behandlungsbericht-Panel (Diagnose + Notizen)

---

## Phase 65: Körpertemperatur-Tracking ✅ *(2026-05-06)*

### M65.1 - Backend ✅
- [x] Migration 033: Tabelle `temperature_history` (temperature_celsius, measurement_method, note)
- [x] `TemperatureController`: GET/POST/DELETE /pets/:id/temperature
- [x] Validierung 25–45 °C, in petsCascade eingehängt

### M65.2 - web_owner ✅
- [x] `TemperatureProvider` (loadForPet, add, delete)
- [x] `TemperatureScreen` — Pet-Selector, Stats-Row, Liniendiagramm (CustomPainter, Normalbereich-Shading), Eintrags-Liste
- [x] Farbcodierung: Normal (grün) / Erhöht (rot) / Niedrig (blau)
- [x] Route `/temperature` + Sidebar-Eintrag
- [x] `_TemperatureCard` im AnimalDetailScreen (letzter Messwert + Status)

---

## Phase 66: Laborbefunde für Tierärzte ✅ *(2026-05-06)*

### M66.1 - Backend ✅
- [x] Migration 034: Tabelle `lab_results` (test_name, test_category, result_value, unit, reference_range, is_abnormal, notes, tested_at)
- [x] `LabResultController`: GET/POST/PUT/DELETE /pets/:id/lab-results
- [x] Nur Tierärzte können Befunde eintragen, in petsCascade eingehängt

### M66.2 - web_vet: Labor-Tab im PatientDetailScreen ✅
- [x] `VetLabResultProvider` (loadForPet, create, delete)
- [x] 12. Tab „Labor" in `patient_detail_screen.dart`
- [x] Ergebnis mit Einheit, Referenzbereich, Kategorie-Badge, Auffällig-Warnung
- [x] In `main.dart` registriert

### M66.3 - web_owner: Laborbefunde read-only ✅
- [x] `OwnerLabResultProvider` (loadForPet, read-only)
- [x] `_LabResultsCard` im AnimalDetailScreen (Vorschau mit Auffällig-Banner)
- [x] In `main.dart` registriert

---

---

## Phase 67: Gesundheitspass (Druckansicht) ✅ *(2026-05-06)*

### M67.1 - Backend ✅
- [x] `GET /pets/:id/health-passport` — aggregiert Tier, Besitzer, Impfungen, Allergien, Medikamente, Laborbefunde, Notfallkontakte

### M67.2 - web_owner: HealthPassportScreen ✅
- [x] Pet-Selector, Übersichts-Vorschau (Karten je Kategorie)
- [x] „Drucken / PDF"-Button öffnet druckfertiges HTML im neuen Tab + löst window.print() aus
- [x] Route `/health-passport` + Sidebar-Eintrag

---

---

## Phase 68: Tierarzt-Bewertungen ✅ *(2026-05-06)*

### M68.1 - Backend ✅
- [x] Migration 035: Tabelle `organization_ratings` (rating 1–5, review, appointment_id)
- [x] `RatingController`: GET/POST/DELETE /organizations/:id/ratings
- [x] Durchschnitts-Stats (avg_rating, total_count) in GET-Antwort
- [x] Upsert bei doppelter Bewertung für gleichen Termin

### M68.2 - web_owner ✅
- [x] „Bewerten"-Button auf abgeschlossenen Terminen mit Organisation
- [x] 5-Sterne-Dialog + optionaler Kommentar
- [x] `_OrgCard` im Marktplatz: lädt Durchschnittsbewertung, zeigt Sterne + Anzahl

---

---

## Phase 69: Tier-Kalender (web_owner) ✅ *(2026-05-06)*

### M69.1 - Kalender-Screen ✅
- [x] `PetCalendarScreen` — Monatsansicht mit Farbpunkt-Markierungen je Ereignistyp
- [x] Aggregiert: Termine, Impfungs-Ablaufdaten, Medikamenten-Enddaten, Erinnerungen
- [x] Tier-Filter (alle oder einzelnes Tier)
- [x] Klick auf Tag zeigt Ereignis-Liste des Tages
- [x] Legende (Farben je Typ), "Heute"-Markierung
- [x] Route `/calendar` + Sidebar-Eintrag

---

## Phase 70: Provider Tages-Agenda ✅ *(2026-05-06)*

### M70.1 - Agenda-Panel im Dashboard ✅
- [x] Heute-Termine chronologisch als kompakte Liste
- [x] Vergangene Termine abgedimmt, inkl. Tier + Besitzername
- [x] Nur sichtbar wenn Termine heute vorhanden

---

---

## Phase 71: Vet-Dashboard — Zuletzt gesehene Patienten ✅ *(2026-05-06)*

### M71.1 ✅
- [x] `_RecentlySeenPatients`-Chips im Vet-Dashboard
- [x] Zeigt die letzten 5 Patienten (aus vergangenen Terminen, dedupliziert)
- [x] Klick navigiert direkt zur Patientendetailansicht

---

## Phase 72: Dashboard Medikament „Schnell-Geben" ✅ *(2026-05-06)*

### M72.1 ✅
- [x] Check-Icon-Button auf jedem Medikament im Dashboard-Panel
- [x] Ruft `MedicationProvider.administer()` direkt aus dem Dashboard auf

---

---

## Phase 73: Admin Wachstums-Grafik ✅ *(2026-05-06)*

### M73.1 - Backend ✅
- [x] `GET /admin/growth` — neue Nutzer, Tiere und Termine pro Tag (letzte 30 Tage)

### M73.2 - web_admin ✅
- [x] `_GrowthChart`-Widget mit Balkendiagramm (CustomPainter, 3 Datensätze)
- [x] Parallel geladen neben `/admin/stats` beim Dashbaord-Init
- [x] Farb-Legende (Nutzer / Tiere / Termine)

---

---

## Phase 74: Tier-Timeline (web_owner) ✅ *(2026-05-06)*

### M74.1 ✅
- [x] `PetTimelineScreen` — chronologische Übersicht aller Ereignisse (Termine, Impfungen, Gewicht, Labor)
- [x] Tier-Selector als FilterChips, Farbkodierung je Typ
- [x] Vertikale Timeline-Darstellung mit Verbindungslinien
- [x] Route `/timeline` + Sidebar-Eintrag

---

## Phase 75: Diagnosen-Vorschläge (web_vet) ✅ *(2026-05-06)*

### M75.1 ✅
- [x] 10 häufige Tier-Diagnosen als Schnellauswahl-Chips im Behandlungsnotizen-Dialog
- [x] Klick füllt Diagnose-Feld automatisch vor (überschreibbar)

---

## Phase 76: Kunden-Arten-Filter (web_provider) ✅ *(2026-05-06)*

### M76.1 ✅
- [x] FilterChips in Kunden-Liste: Alle / Hund / Katze / etc. (automatisch aus vorhandenen Daten)
- [x] Kombination mit bestehender Text-Suche

---

---

## Phase 77: Admin CSV-Export ✅ *(2026-05-06)*

### M77.1 ✅
- [x] CSV-Export-Button in der Benutzerverwaltung (web_admin)
- [x] Direkter Browser-Download via `dart:html` Blob + Anchor
- [x] Felder: ID, E-Mail, Name, Rolle, Aktiv, Verifiziert, Erstellt

---

## Phase 78: Vet Patienten-Dossier-Druck ✅ *(2026-05-06)*

### M78.1 ✅
- [x] Drucken-Button in der AppBar des PatientDetailScreen
- [x] `_printDossier()`: Impfungen, aktive Medikamente, letzte 10 Akte-Einträge als HTML
- [x] Öffnet neuen Tab + löst window.print() aus

---

---

## Phase 79: Rate-Limiting für Auth-Endpoints ✅ *(2026-05-06)*

### M79.1 ✅
- [x] `rate_limit_middleware.dart` — In-Memory, 10 Versuche / 60 Sekunden pro IP
- [x] Auf `/auth`-Route angewendet
- [x] Erfolgreicher Login setzt Zähler zurück; 401/403 erhöhen ihn

---

## Phase 80: Tier-Statistiken (Backend + web_owner) ✅ *(2026-05-06)*

### M80.1 - Backend ✅
- [x] `GET /pets/:id/stats` — aggregiert Impfungen, Medikamente, Termine, Akte, Labor, Allergien, letzte Messwerte, nächste Impfablauffrist

### M80.2 - web_owner ✅
- [x] `_QuickStatsRow` mit farbigen Chips direkt im AnimalDetailScreen
- [x] Lädt beim initState asynchron, erscheint wenn verfügbar

---

---

## Phase 81: Globale Suche (web_owner) ✅ *(2026-05-06)*

### M81.1 ✅
- [x] TopBar-Suchfeld ist jetzt funktional (statt Dummy-Platzhalter)
- [x] Durchsucht Tiere (Name, Rasse, Art), Termine (Titel, Praxis), Erinnerungen (Titel)
- [x] Dropdown mit max. 6 Ergebnissen, Klick navigiert direkt
- [x] Clear-Button, Schließen nach Auswahl

---

---

## Phase 82: Leistungs-Vorlage & Service-Duplizierung (web_provider) ✅ *(2026-05-06)*

### M82.1 ✅
- [x] „Als Vorlage"-Button auf jedem Leistungs-Eintrag
- [x] Öffnet den Leistungs-Dialog mit vorausgefülltem Titel + Typ

---

---

## Phase 83: Tier-Archivierung ✅ *(2026-05-06)*

### M83.1 - Backend ✅
- [x] Migration 036: `archived_at` + `archived_reason` zu `pets`
- [x] `PUT /pets/:id/archive` — setzt archived_at auf NOW()
- [x] `PUT /pets/:id/unarchive` — setzt archived_at auf NULL

### M83.2 - web_owner ✅
- [x] „Archivieren"-Button im AnimalDetailScreen (neben Löschen)
- [x] Dialog mit optionalem Grund, navigiert nach Archivierung zurück zur Liste

---

---

## Phase 84: Quick-Add Erinnerung im Dashboard ✅ *(2026-05-06)*

### M84.1 ✅
- [x] „+"-Button im Erinnerungs-Panel auf dem Dashboard
- [x] Dialog: Titel + Datum → `ReminderProvider.create()` direkt

---

## Phase 85: API-Fehlerbehandlung verbessert ✅ *(2026-05-06)*

### M85.1 ✅
- [x] ApiService._handleResponse: Typisierte Fehlermeldungen je HTTP-Status (401, 403, 404, 409, 429, 5xx)
- [x] Body wird sicher geparst, auch wenn leer

---

## Phase 86: Fütterungs-Streak ✅ *(2026-05-06)*

### M86.1 ✅
- [x] `_StreakBadge` im Fütterungs-Protokoll: Anzahl aufeinanderfolgender Fütterungs-Tage
- [x] 🔥 Emoji + "X Tage"-Badge, erscheint nur wenn Streak > 0

---

## Phase 87: Impf-Zertifikat Ausdruck (web_vet) ✅ *(2026-05-06)*

### M87.1 ✅
- [x] „Zertifikat"-Button im Impfungen-Tab von PatientDetailScreen
- [x] Druckbares HTML: Tabelle aller Impfungen (Impfstoff, Hersteller, Charge, Datum, Gültig bis, Tierarzt)

---

---

## Phase 88: Patienten-Zuweisung (web_vet) ✅ *(2026-05-06)*

### M88.1 - Backend ✅
- [x] Migration 037: Tabelle `patient_assignments` (pet_id, org_id, assigned_to, note) UNIQUE per Pet+Org
- [x] `PatientAssignmentController`: GET/PUT/DELETE /pets/:petId/assignment

### M88.2 - web_vet ✅
- [x] Zuweisung laden in initState
- [x] AppBar zeigt zuständigen Mitarbeiter als Chip
- [x] „Zuweisen"-Button öffnet Dialog (Dropdown: alle Org-Mitglieder + Notiz)
- [x] DELETE bei "Keine Zuweisung" Auswahl

---

---

## Phase 89: Wiederholungs-Termine (web_vet + Backend) ✅ *(2026-05-06)*

### M89.1 - Backend ✅
- [x] Migration 038: `is_recurring`, `recurrence_interval` (enum), `recurrence_count`, `parent_appointment_id` zu appointments
- [x] POST /appointments erstellt automatisch Follow-up-Termine (max 12 Wiederholungen)

### M89.2 - web_vet ✅
- [x] „Wiederholungstermin"-Switch im Neu-Termin-Dialog
- [x] Dropdown: Täglich / Wöchentlich / Monatlich / Jährlich + Anzahl
- [x] SnackBar zeigt Anzahl erstellter Wiederholungen

---

---

## Phase 90: Admin Benutzer-Aktivität ✅ *(2026-05-06)*

### M90.1 - Backend ✅
- [x] `GET /admin/users/:id` gibt jetzt zusätzlich `stats` (Tier-Anzahl, Termin-Anzahl) und `recent_activity` (letzte 5 Audit-Log-Einträge) zurück

### M90.2 - web_admin ✅
- [x] UserDetailScreen lädt direkt via API statt aus Cache
- [x] Statistik-Karte: Tiere + Termine-Anzahl
- [x] Letzte Aktivität als Liste (Action + Ressource + Datum)
- [x] `_StatTile`-Widget für kompakte Stat-Anzeige

---

---

## Phase 91: Tier-Vergleich (web_owner) ✅ *(2026-05-06)*

### M91.1 ✅
- [x] `PetComparisonScreen` — bis zu 3 Tiere gleichzeitig vergleichen
- [x] Tabellen-Ansicht: Tierart, Rasse, Alter, Gewicht, Impfungen, Medikamente, Termine, Allergien, Chip
- [x] Stats via /pets/:id/stats geladen (async)
- [x] Route `/compare` + Sidebar-Eintrag

---

## Phase 92: Gesundheits-Score ✅ *(2026-05-06)*

### M92.1 - Backend ✅
- [x] `health_score` (0–100) in GET /pets/:id/stats: berechnet aus Impfstatus, Ablauffristen, Gewichts-Tracking

### M92.2 - web_owner ✅
- [x] `_HealthScoreBar` im AnimalDetailScreen: Fortschrittsbalken + Label (Gut/Mittel/Aufmerksamkeit)
- [x] Farbkodierung: grün ≥80, orange ≥50, rot <50

---

---

## Phase 93: API-Info Endpoint & Dashboard Quick-Actions ✅ *(2026-05-06)*

### M93.1 ✅
- [x] GET / gibt jetzt strukturierte API-Info (version, migrations, endpoints) zurück
- [x] Dashboard Quick-Actions um Kalender, Gesundheitspass, Tier-Vergleich erweitert

---

---

## Phase 94: Medikamenten-Duplikat-Warnung ✅ *(2026-05-06)*

### M94.1 - Backend ✅
- [x] POST /pets/:id/medications: Prüft ob ähnliches Medikament bereits aktiv → `warning` in Response

### M94.2 - web_vet ✅
- [x] `MedicalProvider.medicationWarning` gespeichert nach `createMedication()`
- [x] Orange SnackBar mit Warnung (5 Sekunden) wenn Duplikat gefunden

---

---

## Phase 95: Jahresrückblick (web_owner) ✅ *(2026-05-06)*

### M95.1 ✅
- [x] `YearReviewScreen` — Jahr-Selector, Pet-Selector
- [x] Hero-Statistik-Chips (Termine, Abgeschlossen, Impfungen, Gewichtsmessungen)
- [x] Monatliches Balkendiagramm der Termine
- [x] Gewichtsverlauf-Zusammenfassung (Start → Ende + Delta)
- [x] Persönlicher Summary-Text je nach Aktivitätslevel
- [x] Route `/year-review` + Sidebar-Eintrag

---

---

## Phase 96: Impfstatus-Ampel im Dashboard ✅ *(2026-05-06)*

### M96.1 ✅
- [x] `_VaccinationStatusRow` im Dashboard: Tier-Badges mit grün (OK) oder orange (bald ablaufend)
- [x] Nutzt bereits geladene `_expiringVaccinations`-Daten

---

## Phase 97: Input-Sanitizer Utility ✅ *(2026-05-06)*

### M97.1 ✅
- [x] `InputSanitizer`-Klasse in backend/lib/utils/sanitizer.dart
- [x] sanitizeText, sanitizeEmail, sanitizeName, sanitizePhone, clampInt, isValidUuid/Email

---

## Phase 98: Skeleton-Loading (web_owner) ✅ *(2026-05-06)*

### M98.1 ✅
- [x] `SkeletonBox`, `PetCardSkeleton`, `PetListSkeleton` Widgets (pulsierende Animation)
- [x] AnimalsScreen zeigt Skeleton während pets.isLoading && pets.isEmpty

---

---

## Phase 99: Schnell-Notiz auf Patientenliste (web_vet) ✅ *(2026-05-06)*

### M99.1 ✅
- [x] Notiz-Button auf jedem Patienten-Listeneintrag in PatientsScreen
- [x] Dialog mit Freitext → POST /pets/:id/notes (visibility: colleagues)

---

## Phase 100: CLAUDE.md & Memory aktualisiert ✅ *(2026-05-06)*

### M100.1 ✅
- [x] CLAUDE.md: Migrations-Zähler auf 38, neue Tabellen dokumentiert
- [x] Memory: Vollständiger Stand nach Phase 100

---

## Notizen

*Anpassungen und Änderungen an der Roadmap hier dokumentieren.*
