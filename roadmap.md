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
- [ ] Einladungs-E-Mail versenden (SMTP-Setup offen)
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
- [ ] Berechtigungs-Middleware: Prüfung bei jedem Request (Folge-Tickets bei Einbindung in Phase 7/12)

### M1.9 - Organisations-Kontext ✅
- [x] Aktive Organisation im JWT-Token speichern
- [x] Organisation wechseln (für Benutzer in mehreren Orgs) via `POST /auth/switch-organization`
- [x] Header `X-Active-Organization` als Override unterstützt
- [ ] Alle Daten werden im Kontext der aktiven Organisation gefiltert (offen, je Endpunkt)
- [ ] Audit-Log für Organisations-Aktionen (siehe M17.3)

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
- [ ] Berechtigungs-Prüfung implementieren (offen, je Endpunkt)

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
- [ ] Migration: Futterplan-Tabelle
- [ ] Migration: Futterplan-Mahlzeit-Tabelle
- [ ] Migration: Futterplan-Komponente-Tabelle

### M10.2 - Futterplan-API
- [ ] `GET /pets/:id/feeding-plans`
- [ ] `POST /pets/:id/feeding-plans`
- [ ] `PUT /feeding-plans/:id`
- [ ] Mahlzeiten und Komponenten CRUD

### M10.3 - Fütterungs-Protokoll
- [ ] Migration: Fütterung-Protokoll-Tabelle
- [ ] `GET /pets/:id/feeding-log`
- [ ] `POST /pets/:id/feeding-log`

---

## Phase 11: Fütterungsmanagement (Frontend)

### M11.1 - Futterplan erstellen
- [ ] Futterplan-Screen
- [ ] Mahlzeiten hinzufügen
- [ ] Komponenten mit Mengen

### M11.2 - Fütterung protokollieren
- [ ] Tägliche Übersicht
- [ ] Als gefüttert markieren
- [ ] Notizen hinzufügen

---

## Phase 12: Web-Frontend Dienstleister (Basis)

### M12.1 - Projekt-Setup
- [x] Flutter Web-Projekt für Dienstleister
- [x] Auth-Flow
- [x] Dienstleister-Profil (Dashboard-Grundgerüst)

### M12.2 - Firmen-Profil & Organisation
- [ ] Firma/Organisation erstellen
- [ ] Firmen-Profil bearbeiten
- [ ] Organisations-Übersicht (alle eigenen Firmen)

### M12.3 - Mitarbeiter-Verwaltung (Firmen-Admin)
- [ ] Mitarbeiter-Liste anzeigen
- [ ] Mitarbeiter einladen (E-Mail oder Link)
- [ ] Einladung als neuer Benutzer annehmen
- [ ] Berechtigungsgruppen verwalten
- [ ] Mitarbeiter einer Gruppe zuordnen
- [ ] Mitarbeiter-Rolle ändern
- [ ] Mitarbeiter deaktivieren/entfernen
- [ ] Termine an Mitarbeiter zuweisen

### M12.4 - Kunden-Liste
- [ ] Kunden mit Zugriff anzeigen
- [ ] Tiere pro Kunde

### M12.5 - Leistungen dokumentieren
- [ ] Neue Leistung erfassen
- [ ] Leistungs-Historie

### M12.6 - Termine verwalten
- [ ] Terminanfragen
- [ ] Kalenderansicht
- [ ] Termine an Mitarbeiter zuweisen

---

## Phase 13: Medien & Dokumente (Backend)

### M13.1 - Medien-Upload
- [ ] Migration: Medien-Tabelle
- [ ] Datei-Upload Service
- [ ] Verschlüsselte Speicherung

### M13.2 - Medien-API
- [ ] `GET /pets/:id/media`
- [ ] `POST /pets/:id/media`
- [ ] `DELETE /media/:id`

---

## Phase 14: Medien & Dokumente (Frontend)

### M14.1 - Besitzer: Dokumente
- [ ] Dokumente hochladen
- [ ] Dokumente anzeigen

### M14.2 - Tierarzt: Röntgenbilder
- [ ] Bilder hochladen
- [ ] Mit Akte verknüpfen
- [ ] Bildarchiv

---

## Phase 15: Professionelle Notizen

### M15.1 - Backend
- [ ] Migration: Notizen-Tabelle
- [ ] Sichtbarkeits-Logik (privat/kollegial)
- [ ] API-Endpunkte

### M15.2 - Frontend (Tierarzt & Dienstleister)
- [ ] Notiz erstellen
- [ ] Sichtbarkeit wählen
- [ ] Notizen anzeigen

---

## Phase 16: Besitzerwechsel

### M16.1 - Backend
- [ ] Migration: Besitzerwechsel-Tabelle
- [ ] Transfer initiieren
- [ ] Transfer bestätigen/ablehnen
- [ ] Daten übertragen

### M16.2 - Frontend
- [ ] Transfer starten
- [ ] Einladung senden
- [ ] Transfer bestätigen

---

## Phase 17: DSGVO & Sicherheit

### M17.1 - Datenexport
- [ ] `GET /account/export`
- [ ] Alle Daten als JSON/ZIP
- [ ] Download-Link generieren

### M17.2 - Verschlüsselung
- [ ] Sensible Felder verschlüsseln
- [ ] Medien verschlüsselt speichern

### M17.3 - Audit-Log
- [ ] Migration: Audit-Log-Tabelle
- [ ] Sensible Aktionen protokollieren
- [ ] Log-Ansicht für Benutzer

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

### M19.1 - Compliance-Überwachung (Tierarzt)
- [ ] Verabreichungs-Protokoll anzeigen
- [ ] Compliance-Statistik

### M19.2 - Gewichtsverlauf
- [ ] Gewicht erfassen
- [ ] Diagramm anzeigen

### M19.3 - Erinnerungen
- [ ] Erinnerungs-System
- [ ] E-Mail-Benachrichtigungen

---

## Phase 20: Produktion

### M20.1 - Produktion-Docker
- [ ] Optimierte Dockerfiles (multi-stage builds)
- [ ] `docker-compose.prod.yml`
- [ ] SSL/TLS Zertifikate

### M20.2 - CI/CD
- [ ] GitHub Actions für Tests
- [ ] Automatische Builds
- [ ] Deployment-Pipeline

### M20.3 - Monitoring
- [ ] Logging-System
- [ ] Health-Checks
- [ ] Metriken

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

## Legende

- [ ] Offen
- [x] Erledigt
- 🚧 In Arbeit

---

## Notizen

*Anpassungen und Änderungen an der Roadmap hier dokumentieren.*
