# MyPet - Tierverwaltung

## Projektübersicht

Eine Plattform zur Verwaltung von Tieren mit drei Benutzergruppen:
- **Tierbesitzer**: Verwalten ihre eigenen Tiere
- **Tierärzte**: Zugriff auf Patientendaten und medizinische Dokumentation
- **Dienstleister**: Hufschmiede, Tierpfleger, Trainer, Physiotherapeuten, etc.

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
- **App 3**: Dienstleister-App (Hufschmied, Pfleger, Trainer, etc.)
- **Lokale Datenbank**: SQLite / Hive / Isar (Offline-First für schnellen Zugriff)

---

## Datenmodell (Erste Ideen)

### Benutzer
- `id`
- `email`
- `passwort_hash`
- `name`
- `rolle` (Besitzer / Tierarzt / Dienstleister)
- `erstellt_am`

### Familie / Gruppe
- `id`
- `name` (z.B. "Familie Müller")
- `erstellt_von` (Benutzer-ID)
- `erstellt_am`

### Familien-Mitgliedschaft
- `id`
- `familie_id`
- `benutzer_id`
- `rolle` (Admin / Mitglied)
- `beigetreten_am`

### Zugriffsberechtigung (Urlaubsvertretung etc.)
- `id`
- `tier_id` (oder `null` für alle Tiere)
- `gewährt_von` (Benutzer-ID)
- `gewährt_an` (Benutzer-ID)
- `berechtigung_typ` (Lesen / Schreiben / Verwalten)
- `gültig_von`
- `gültig_bis` (zeitlich begrenzt)
- `notizen` (z.B. "Urlaubsvertretung Juli 2025")

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

### Dienstleister
- `id`
- `benutzer_id`
- `firmenname`
- `dienstleister_typ` (Hufschmied, Tierpfleger, Trainer, Physiotherapeut, Hundefriseur, etc.)
- `beschreibung`
- `adresse`
- `telefon`
- `mobil` (oft mobiler Service)
- `arbeitsgebiet_radius`
- `spezialisierung` (z.B. "Pferde", "Hunde", "Exoten")

### Dienstleistung
- `id`
- `dienstleister_id`
- `tier_id`
- `datum`
- `leistung_typ`
- `beschreibung`
- `notizen`
- `nächster_termin`

### Medizinische Akte
- `id`
- `tier_id`
- `tierarzt_id`
- `datum`
- `diagnose`
- `behandlung`
- `notizen`

### Medikation
- `id`
- `tier_id`
- `tierarzt_id`
- `medikament_name`
- `wirkstoff`
- `dosierung` (z.B. "10mg")
- `einheit` (Tabletten, ml, Tropfen, etc.)
- `anzahl_packungen`
- `menge_pro_packung`
- `einnahme_frequenz` (z.B. "2x täglich")
- `einnahme_dauer` (z.B. "7 Tage", "dauerhaft")
- `start_datum`
- `end_datum`
- `anweisungen` (z.B. "vor dem Füttern")
- `verordnet_am`
- `status` (aktiv / abgeschlossen / pausiert)

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
- [ ] Dienstleistungs-Historie einsehen (Hufschmied, Pflege, etc.)
- [ ] Termine bei Tierärzten buchen
- [ ] Termine bei Dienstleistern buchen
- [ ] Erinnerungen (Impfungen, Termine, Medikamente)
- [ ] Tierarzt-Suche in der Nähe
- [ ] Dienstleister-Suche (Hufschmied, Trainer, etc.)

### Offline & Synchronisation
- [ ] Lokale Speicherung aller eigenen Tierdaten
- [ ] Offline-Zugriff auf alle wichtigen Informationen
- [ ] Automatische Synchronisation bei Internetverbindung
- [ ] Konfliktauflösung bei gleichzeitigen Änderungen

### Familie & Freigaben
- [ ] Familie/Gruppe erstellen
- [ ] Familienmitglieder einladen
- [ ] Gemeinsamer Zugriff auf Haustiere innerhalb der Familie
- [ ] Urlaubsvertretung: Zeitlich begrenzten Zugriff gewähren
- [ ] Berechtigungen verwalten (Lesen / Bearbeiten)
- [ ] Freigabe-Übersicht (wer hat Zugriff auf was)

### Medikamenten-Verwaltung
- [ ] Aktuelle Medikationen einsehen
- [ ] Medikamenten-Erinnerungen
- [ ] Restmenge tracken (Nachkauf-Warnung)
- [ ] Medikamenten-Historie

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

### Medikamenten-Verordnung
- [ ] Medikamente verordnen (Name, Wirkstoff, Dosierung)
- [ ] Anzahl und Menge festlegen
- [ ] Einnahmeplan erstellen (Frequenz, Dauer)
- [ ] Anweisungen hinzufügen
- [ ] Medikationshistorie des Tiers einsehen
- [ ] Wechselwirkungen prüfen (optional)

### Erweiterte Features
- [ ] Kalenderansicht für Termine
- [ ] Statistiken und Berichte
- [ ] Rechnungserstellung
- [ ] Labor-Ergebnisse anhängen
- [ ] Kommunikation mit Tierbesitzern
- [ ] Notfall-Modus für Bereitschaftsdienst

---

## Features - Dienstleister-App

### Kernfunktionen
- [ ] Registrierung / Login
- [ ] Profil mit Dienstleistungstyp anlegen
- [ ] Kundenliste (Tierbesitzer + deren Tiere)
- [ ] Leistungen dokumentieren
- [ ] Terminverwaltung / Kalender
- [ ] Fahrtrouten-Planung (mobiler Service)
- [ ] Erinnerungen für wiederkehrende Termine

### Spezifische Features je nach Typ

#### Hufschmied
- [ ] Beschlag-Historie pro Pferd
- [ ] Hufzustand dokumentieren (mit Fotos)
- [ ] Intervall-Empfehlungen (alle X Wochen)
- [ ] Material-Verwaltung (Hufeisen, Nägel, etc.)

#### Tierpfleger / Hundefriseur
- [ ] Pflegehistorie
- [ ] Fell-/Hautzustand dokumentieren
- [ ] Vorher/Nachher Fotos
- [ ] Stammkunden-Rabatte

#### Trainer
- [ ] Trainingsfortschritt dokumentieren
- [ ] Übungspläne erstellen
- [ ] Video-Uploads von Trainingseinheiten
- [ ] Ziele und Meilensteine

#### Physiotherapeut
- [ ] Behandlungsverlauf
- [ ] Übungen für zuhause
- [ ] Zusammenarbeit mit Tierarzt (Verordnungen)

### Erweiterte Features
- [ ] Rechnungserstellung
- [ ] Statistiken (Umsatz, Kunden, etc.)
- [ ] Kommunikation mit Tierbesitzern
- [ ] Bewertungen / Referenzen
- [ ] Online-Buchung durch Tierbesitzer

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

### Medikationen
- `GET /pets/:id/medications` - Alle Medikationen eines Tiers
- `GET /pets/:id/medications/active` - Aktive Medikationen
- `POST /pets/:id/medications` - Neue Medikation verordnen (nur Tierarzt)
- `PUT /medications/:id` - Medikation aktualisieren
- `PUT /medications/:id/status` - Status ändern (aktiv/pausiert/abgeschlossen)

### Familien & Gruppen
- `GET /families` - Eigene Familien/Gruppen
- `POST /families` - Neue Familie erstellen
- `POST /families/:id/members` - Mitglied einladen
- `DELETE /families/:id/members/:userId` - Mitglied entfernen
- `PUT /families/:id/members/:userId` - Rolle ändern

### Zugriffsberechtigungen
- `GET /permissions` - Eigene erteilte/erhaltene Berechtigungen
- `POST /permissions` - Neue Berechtigung erteilen (Urlaubsvertretung etc.)
- `PUT /permissions/:id` - Berechtigung aktualisieren
- `DELETE /permissions/:id` - Berechtigung widerrufen

### Impfungen
- `GET /pets/:id/vaccinations`
- `POST /pets/:id/vaccinations` (nur Tierarzt)

### Termine
- `GET /appointments`
- `POST /appointments`
- `PUT /appointments/:id`
- `DELETE /appointments/:id`

### Dienstleister
- `GET /providers` - Alle Dienstleister (mit Filter)
- `GET /providers/:id` - Einzelner Dienstleister
- `POST /providers` - Dienstleister-Profil anlegen
- `PUT /providers/:id` - Profil aktualisieren

### Dienstleistungen
- `GET /pets/:id/services` - Alle Dienstleistungen eines Tiers
- `POST /pets/:id/services` - Neue Dienstleistung dokumentieren
- `GET /providers/:id/services` - Alle Leistungen eines Dienstleisters

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
├── app_provider/       # Flutter App für Dienstleister
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
7. **Offline-Sync**: Welche Strategie? (Last-Write-Wins, Merge, Conflict-Resolution-UI?)
8. **Lokale DB (Flutter)**: Hive, Isar oder SQLite?

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
