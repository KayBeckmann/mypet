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
- [ ] Hot-Reload für Backend einrichten
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

### M1.3 - Authentifizierung (Teil 1)
- [ ] Benutzer-Model erstellen
- [ ] Passwort-Hashing (Argon2/Bcrypt)
- [ ] `POST /auth/register` - Registrierung
- [ ] `POST /auth/login` - Login mit JWT
- [ ] JWT-Generierung und Validierung

### M1.4 - Authentifizierung (Teil 2)
- [ ] `POST /auth/refresh` - Token erneuern
- [ ] `POST /auth/logout` - Logout
- [ ] Auth-Middleware für geschützte Routen
- [ ] Rollen-System (Besitzer/Tierarzt/Dienstleister)

### M1.5 - Benutzer-Verwaltung
- [ ] `GET /account` - Eigene Daten abrufen
- [ ] `PUT /account` - Profil aktualisieren
- [ ] `DELETE /account` - Konto löschen (DSGVO)
- [ ] Passwort ändern

---

## Phase 2: Tier-Verwaltung (Backend)

### M2.1 - Tier-Model
- [ ] Migration: Tier-Tabelle
- [ ] Tier-Model mit allen Feldern
- [ ] Validierung der Eingaben

### M2.2 - Tier-CRUD
- [ ] `GET /pets` - Alle eigenen Tiere
- [ ] `GET /pets/:id` - Einzelnes Tier
- [ ] `POST /pets` - Tier anlegen
- [ ] `PUT /pets/:id` - Tier aktualisieren
- [ ] `DELETE /pets/:id` - Tier löschen

### M2.3 - Foto-Upload für Tiere
- [ ] Datei-Upload-Endpoint
- [ ] Bild-Speicherung (lokal oder S3-kompatibel)
- [ ] Bild-URL im Tier-Profil speichern
- [ ] Bild-Größen-Validierung

---

## Phase 3: Web-Frontend Tierbesitzer (Basis)

### M3.1 - Flutter Web Setup
- [ ] Flutter Web-Projekt initialisieren
- [ ] Ordnerstruktur (screens/, widgets/, services/, providers/)
- [ ] Theme und Styling-Grundlagen
- [ ] Router einrichten (go_router)

### M3.2 - Authentifizierung UI
- [ ] Login-Screen
- [ ] Registrierungs-Screen
- [ ] Token-Speicherung (secure storage)
- [ ] Auth-State-Management
- [ ] Logout-Funktion

### M3.3 - API-Service
- [ ] HTTP-Client einrichten (dio/http)
- [ ] Base-URL aus Konfiguration
- [ ] Auth-Token automatisch anhängen
- [ ] Error-Handling

### M3.4 - Tier-Liste
- [ ] Tier-Liste Screen
- [ ] Tier-Karte Widget
- [ ] Pull-to-Refresh
- [ ] Leerer Zustand (keine Tiere)

### M3.5 - Tier hinzufügen
- [ ] Formular: Tier anlegen
- [ ] Foto-Upload
- [ ] Validierung
- [ ] Erfolgs-/Fehlermeldungen

### M3.6 - Tier-Detail
- [ ] Tier-Detail Screen
- [ ] Tier bearbeiten
- [ ] Tier löschen (mit Bestätigung)

---

## Phase 4: Familien & Freigaben (Backend)

### M4.1 - Familien-Model
- [ ] Migration: Familie-Tabelle
- [ ] Migration: Familien-Mitgliedschaft-Tabelle
- [ ] Models erstellen

### M4.2 - Familien-API
- [ ] `GET /families` - Eigene Familien
- [ ] `POST /families` - Familie erstellen
- [ ] `POST /families/:id/members` - Mitglied einladen
- [ ] `DELETE /families/:id/members/:userId` - Mitglied entfernen

### M4.3 - Zugriffsberechtigung-Model
- [ ] Migration: Zugriffsberechtigung-Tabelle
- [ ] Model erstellen
- [ ] Berechtigungs-Prüfung implementieren

### M4.4 - Zugriffsberechtigung-API
- [ ] `GET /permissions` - Eigene Berechtigungen
- [ ] `POST /permissions` - Berechtigung erteilen
- [ ] `PUT /permissions/:id` - Berechtigung aktualisieren
- [ ] `DELETE /permissions/:id` - Berechtigung widerrufen

---

## Phase 5: Familien & Freigaben (Frontend)

### M5.1 - Familie erstellen
- [ ] Familie erstellen Screen
- [ ] Familien-Übersicht

### M5.2 - Mitglieder verwalten
- [ ] Mitglieder einladen (per E-Mail)
- [ ] Mitglieder-Liste
- [ ] Mitglied entfernen

### M5.3 - Urlaubsvertretung
- [ ] Berechtigung erteilen Screen
- [ ] Zeitraum wählen
- [ ] Aktive Berechtigungen anzeigen

---

## Phase 6: Medizinische Daten (Backend)

### M6.1 - Medizinische Akte
- [ ] Migration: Medizinische Akte-Tabelle
- [ ] Model erstellen
- [ ] `GET /pets/:id/records`
- [ ] `POST /pets/:id/records` (nur Tierarzt)

### M6.2 - Impfungen
- [ ] Migration: Impfungen-Tabelle
- [ ] Model erstellen
- [ ] `GET /pets/:id/vaccinations`
- [ ] `POST /pets/:id/vaccinations` (nur Tierarzt)

### M6.3 - Medikationen (Teil 1)
- [ ] Migration: Medikation-Tabelle
- [ ] Model erstellen
- [ ] `GET /pets/:id/medications`
- [ ] `POST /pets/:id/medications` (nur Tierarzt)

### M6.4 - Medikations-Tracking
- [ ] Migration: Medikations-Verabreichung-Tabelle
- [ ] `GET /medications/:id/schedule`
- [ ] `POST /medications/:id/administer`
- [ ] `POST /medications/:id/skip`

---

## Phase 7: Web-Frontend Tierarzt (Basis)

### M7.1 - Projekt-Setup
- [ ] Flutter Web-Projekt für Tierärzte
- [ ] Gemeinsame Komponenten aus shared/
- [ ] Auth-Flow (wie Besitzer-App)

### M7.2 - Praxis-Profil
- [ ] Praxis-Registrierung
- [ ] Praxis-Profil bearbeiten

### M7.3 - Patienten-Liste
- [ ] Tiere mit Zugriff anzeigen
- [ ] Suche/Filter

### M7.4 - Medizinische Akte führen
- [ ] Akte-Einträge anzeigen
- [ ] Neuer Eintrag erstellen
- [ ] Diagnose und Behandlung dokumentieren

### M7.5 - Impfungen eintragen
- [ ] Impfungen anzeigen
- [ ] Neue Impfung eintragen
- [ ] Gültigkeitsdatum setzen

### M7.6 - Medikamente verordnen
- [ ] Medikation erstellen
- [ ] Dosierung und Anweisungen
- [ ] Einnahmeplan erstellen

---

## Phase 8: Termine (Backend)

### M8.1 - Termine-Model
- [ ] Migration: Termine-Tabelle
- [ ] Model mit Status-Workflow

### M8.2 - Termine-API
- [ ] `GET /appointments`
- [ ] `POST /appointments`
- [ ] `PUT /appointments/:id/confirm`
- [ ] `PUT /appointments/:id/complete`
- [ ] `DELETE /appointments/:id`

### M8.3 - Automatischer Zugriff
- [ ] Bei Terminbestätigung Zugriff gewähren
- [ ] Zugriff nach Termin-Abschluss entziehen

---

## Phase 9: Termine (Frontend)

### M9.1 - Termine buchen (Besitzer)
- [ ] Tierarzt/Dienstleister suchen
- [ ] Termin anfragen
- [ ] Eigene Termine anzeigen

### M9.2 - Termine verwalten (Tierarzt)
- [ ] Terminanfragen anzeigen
- [ ] Termin bestätigen/ablehnen
- [ ] Kalenderansicht

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
- [ ] Flutter Web-Projekt für Dienstleister
- [ ] Auth-Flow
- [ ] Dienstleister-Profil

### M12.2 - Kunden-Liste
- [ ] Kunden mit Zugriff anzeigen
- [ ] Tiere pro Kunde

### M12.3 - Leistungen dokumentieren
- [ ] Neue Leistung erfassen
- [ ] Leistungs-Historie

### M12.4 - Termine verwalten
- [ ] Terminanfragen
- [ ] Kalenderansicht

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

## Legende

- [ ] Offen
- [x] Erledigt
- 🚧 In Arbeit

---

## Notizen

*Anpassungen und Änderungen an der Roadmap hier dokumentieren.*
