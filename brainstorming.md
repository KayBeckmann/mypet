# MyPet - Tierverwaltung

## Projektübersicht

Eine Plattform zur Verwaltung von Tieren mit zwei Benutzergruppen:
- **Tierbesitzer**: Verwalten ihre eigenen Tiere
- **Tierärzte**: Zugriff auf Patientendaten und medizinische Dokumentation

---

## Technologie-Stack

### Backend
- **Sprache**: Dart
- **Framework**: Shelf / Dart Frog / Serverpod
- **Datenbank**: PostgreSQL / MySQL / SQLite
- **API**: REST oder GraphQL

### Frontends
- **Framework**: Flutter (Cross-Platform)
- **App 1**: Tierbesitzer-App
- **App 2**: Tierarzt-App

---

## Datenmodell (Erste Ideen)

### Benutzer
- `id`
- `email`
- `passwort_hash`
- `name`
- `rolle` (Besitzer / Tierarzt)
- `erstellt_am`

### Tier
- `id`
- `name`
- `tierart` (Hund, Katze, Vogel, etc.)
- `rasse`
- `geburtsdatum`
- `geschlecht`
- `chip_nummer`
- `besitzer_id`
- `foto_url`

### Tierarzt-Praxis
- `id`
- `name`
- `adresse`
- `telefon`
- `öffnungszeiten`

### Medizinische Akte
- `id`
- `tier_id`
- `tierarzt_id`
- `datum`
- `diagnose`
- `behandlung`
- `medikamente`
- `notizen`

### Impfungen
- `id`
- `tier_id`
- `impfstoff`
- `datum`
- `gültig_bis`
- `tierarzt_id`

### Termine
- `id`
- `tier_id`
- `tierarzt_id`
- `datum_zeit`
- `grund`
- `status` (geplant, abgeschlossen, abgesagt)

---

## Features - Tierbesitzer-App

### Kernfunktionen
- [ ] Registrierung / Login
- [ ] Tierprofil anlegen und verwalten
- [ ] Mehrere Tiere pro Account
- [ ] Foto-Upload für Tiere
- [ ] Impfpass digital einsehen
- [ ] Medizinische Historie einsehen
- [ ] Termine bei Tierärzten buchen
- [ ] Erinnerungen (Impfungen, Termine, Medikamente)
- [ ] Tierarzt-Suche in der Nähe

### Erweiterte Features
- [ ] Gewichtsverlauf tracken
- [ ] Fütterungsprotokoll
- [ ] Notfallkontakte
- [ ] QR-Code für Chip-Nummer
- [ ] Dokumente hochladen (Kaufvertrag, Versicherung)
- [ ] Push-Benachrichtigungen

---

## Features - Tierarzt-App

### Kernfunktionen
- [ ] Praxis-Registrierung / Login
- [ ] Patientenliste (Tiere)
- [ ] Medizinische Akte führen
- [ ] Diagnosen und Behandlungen dokumentieren
- [ ] Impfungen eintragen
- [ ] Terminverwaltung
- [ ] Rezepte ausstellen

### Erweiterte Features
- [ ] Kalenderansicht für Termine
- [ ] Statistiken und Berichte
- [ ] Rechnungserstellung
- [ ] Labor-Ergebnisse anhängen
- [ ] Kommunikation mit Tierbesitzern
- [ ] Notfall-Modus für Bereitschaftsdienst

---

## API-Endpunkte (Entwurf)

### Authentifizierung
- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/refresh`
- `POST /auth/logout`

### Tiere
- `GET /pets` - Alle Tiere des Besitzers
- `GET /pets/:id` - Einzelnes Tier
- `POST /pets` - Neues Tier anlegen
- `PUT /pets/:id` - Tier aktualisieren
- `DELETE /pets/:id` - Tier löschen

### Medizinische Akten
- `GET /pets/:id/records` - Alle Einträge eines Tiers
- `POST /pets/:id/records` - Neuer Eintrag (nur Tierarzt)

### Impfungen
- `GET /pets/:id/vaccinations`
- `POST /pets/:id/vaccinations` (nur Tierarzt)

### Termine
- `GET /appointments`
- `POST /appointments`
- `PUT /appointments/:id`
- `DELETE /appointments/:id`

---

## Projektstruktur

```
mypet/
├── backend/
│   ├── bin/
│   ├── lib/
│   │   ├── models/
│   │   ├── controllers/
│   │   ├── services/
│   │   ├── middleware/
│   │   └── database/
│   ├── test/
│   └── pubspec.yaml
│
├── app_owner/          # Flutter App für Tierbesitzer
│   ├── lib/
│   │   ├── models/
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── services/
│   │   └── providers/
│   └── pubspec.yaml
│
├── app_vet/            # Flutter App für Tierärzte
│   ├── lib/
│   │   ├── models/
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── services/
│   │   └── providers/
│   └── pubspec.yaml
│
└── shared/             # Gemeinsame Models/Utils
    └── lib/
```

---

## Offene Fragen

1. **Backend-Framework**: Shelf, Dart Frog oder Serverpod?
2. **Datenbank**: PostgreSQL für Produktion, SQLite für Entwicklung?
3. **Authentifizierung**: JWT oder Session-basiert?
4. **State Management (Flutter)**: Riverpod, Bloc oder Provider?
5. **Deployment**: Docker? Cloud-Anbieter?
6. **Shared Code**: Gemeinsames Package für Models zwischen Apps?

---

## Nächste Schritte

1. Backend-Framework evaluieren und entscheiden
2. Datenbankschema finalisieren
3. Backend-Grundstruktur aufsetzen
4. API-Dokumentation mit OpenAPI/Swagger
5. Flutter-Projekte initialisieren
6. Authentifizierung implementieren
7. Erste CRUD-Operationen für Tiere

---

## Notizen

*Hier können weitere Ideen und Anmerkungen gesammelt werden.*
