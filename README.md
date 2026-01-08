# MyPet - Tierverwaltung

> Open Source Plattform zur Verwaltung von Haustieren für Besitzer, Tierärzte und Dienstleister

## Projektübersicht

MyPet ist eine umfassende Plattform zur digitalen Verwaltung von Haustieren. Das System verbindet Tierbesitzer mit Tierärzten und Dienstleistern (Hufschmiede, Trainer, Pfleger, etc.) und ermöglicht eine lückenlose Dokumentation der Tiergesundheit.

### Benutzergruppen

| Rolle | Beschreibung |
|-------|--------------|
| **Tierbesitzer** | Verwalten ihre Tiere, buchen Termine, tracken Medikamente und Fütterung |
| **Tierärzte** | Führen medizinische Akten, verordnen Medikamente, laden Röntgenbilder hoch |
| **Dienstleister** | Dokumentieren Leistungen (Hufbeschlag, Pflege, Training, etc.) |

### Kernprinzip

> Alle medizinischen und dienstleistungsbezogenen Daten gehören zum **Tier**, nicht zum Besitzer. Bei einem Besitzerwechsel bleiben alle Daten erhalten.

---

## Features

### Tierbesitzer
- Tierprofil mit Foto und allen wichtigen Daten
- Digitaler Impfpass
- Medizinische Historie einsehen
- Medikamenten-Tracking (Verabreichung protokollieren)
- Fütterungsmanagement mit Mahlzeiten und Mengen
- Termine bei Tierärzten und Dienstleistern buchen
- Familien-Freigabe für gemeinsamen Zugriff
- Urlaubsvertretung mit zeitlich begrenztem Zugriff
- Besitzerwechsel bei Verkauf/Übergabe

### Tierärzte
- Medizinische Akten führen
- Diagnosen und Behandlungen dokumentieren
- Medikamente verordnen mit Dosierung und Einnahmeplan
- Compliance-Überwachung (Hat Besitzer Medikament gegeben?)
- Röntgenbilder und Laborberichte hochladen
- Impfungen eintragen
- Professionelle Notizen (privat oder für Kollegen)

### Dienstleister
- Leistungen dokumentieren
- Terminverwaltung
- Kundenübersicht
- Typspezifische Features (Hufbeschlag-Historie, Trainingsfortschritt, etc.)
- Professionelle Notizen

---

## Tech-Stack

### Backend
- **Sprache**: Dart
- **Framework**: Shelf / Dart Frog / Serverpod
- **Datenbank**: PostgreSQL
- **API**: REST

### Frontend
- **Framework**: Flutter (Web)
- **3 separate Web-Apps**: Besitzer, Tierarzt, Dienstleister

### Infrastruktur
- **Container**: Docker & Docker Compose
- **Reverse Proxy**: Nginx
- **Konfiguration**: Umgebungsvariablen (.env)

---

## Schnellstart

### Voraussetzungen
- Docker & Docker Compose
- Git

### Installation

```bash
# Repository klonen
git clone https://github.com/KayBeckmann/mypet.git
cd mypet

# Umgebungsvariablen konfigurieren
cp .env.example .env
# .env nach Bedarf anpassen

# Container starten
docker-compose up -d

# Logs anzeigen
docker-compose logs -f
```

### Zugriff

| Service | URL |
|---------|-----|
| Besitzer-App | http://localhost:3001 |
| Tierarzt-App | http://localhost:3002 |
| Dienstleister-App | http://localhost:3003 |
| Backend API | http://localhost:8080 |

---

## Projektstruktur

```
mypet/
├── backend/                 # Dart Backend
│   ├── bin/
│   ├── lib/
│   │   ├── models/
│   │   ├── controllers/
│   │   ├── services/
│   │   └── database/
│   ├── test/
│   └── pubspec.yaml
│
├── web_owner/              # Flutter Web - Tierbesitzer
├── web_vet/                # Flutter Web - Tierärzte
├── web_provider/           # Flutter Web - Dienstleister
├── shared/                 # Gemeinsame Models/Utils
│
├── docker-compose.yml
├── docker-compose.dev.yml
├── .env.example
│
├── brainstorming.md        # Feature-Ideen und Datenmodelle
├── roadmap.md              # Entwicklungs-Roadmap
└── README.md
```

---

## Konfiguration

Alle Einstellungen erfolgen über Umgebungsvariablen in der `.env`-Datei:

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
```

Siehe `.env.example` für alle verfügbaren Optionen.

---

## Entwicklung

### Lokale Entwicklungsumgebung

```bash
# Entwicklungs-Container starten (mit Hot-Reload)
docker-compose -f docker-compose.dev.yml up -d

# Backend-Logs
docker-compose logs -f backend

# Datenbank zurücksetzen
./scripts/reset-db.sh
```

### Tests ausführen

```bash
# Backend-Tests
cd backend
dart test

# Frontend-Tests
cd web_owner
flutter test
```

---

## Sicherheit & Datenschutz

- **Verschlüsselung**: Sensible Daten werden mit AES-256 verschlüsselt
- **Passwörter**: Argon2/Bcrypt Hashing
- **Übertragung**: TLS/HTTPS für alle Verbindungen
- **DSGVO-konform**:
  - Vollständige Datenlöschung bei Konto-Löschung
  - Datenexport auf Anfrage
  - Klare Einwilligungen

---

## Roadmap

Siehe [roadmap.md](roadmap.md) für die detaillierte Entwicklungs-Roadmap mit allen Meilensteinen.

### Aktuelle Phase
- [ ] Phase 0: Projekt-Infrastruktur (Docker, .env)

### Geplante Features
- Mobile Apps (iOS/Android)
- Push-Benachrichtigungen
- Offline-Synchronisation
- Chat zwischen Besitzer und Arzt/Dienstleister
- Tierregister-Integration (TASSO, Findefix)

---

## Mitwirken

Beiträge sind willkommen!

1. Fork erstellen
2. Feature-Branch anlegen (`git checkout -b feature/neue-funktion`)
3. Änderungen committen (`git commit -m 'Neue Funktion hinzugefügt'`)
4. Branch pushen (`git push origin feature/neue-funktion`)
5. Pull Request erstellen

### Coding Guidelines
- Dart: [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Flutter: [Flutter Style Guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo)
- Commits: [Conventional Commits](https://www.conventionalcommits.org/)

---

## Lizenz

Dieses Projekt ist Open Source. Lizenzdetails folgen.

---

## Kontakt

- **Repository**: [github.com/KayBeckmann/mypet](https://github.com/KayBeckmann/mypet)
- **Issues**: [GitHub Issues](https://github.com/KayBeckmann/mypet/issues)

---

## Dokumentation

| Dokument | Beschreibung |
|----------|--------------|
| [brainstorming.md](brainstorming.md) | Feature-Ideen, Datenmodelle, API-Entwürfe |
| [roadmap.md](roadmap.md) | Entwicklungs-Roadmap mit Meilensteinen |

---

## Unterstützen

Wenn dir dieses Projekt gefällt, kannst du die Entwicklung unterstützen:

- **Bitcoin**: `12QBn6eba71FtAUM4HFmSGgTY9iTPfRKLx`
- **Buy Me a Coffee**: [buymeacoffee.com/snuppedelua](https://www.buymeacoffee.com/snuppedelua)
