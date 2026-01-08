# MyPet - Tierverwaltung

> **Open Source Projekt** - Quellcode frei verfügbar

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

## Sicherheit & Datenschutz

### Verschlüsselung
- **Datenbank**: Alle sensiblen Daten verschlüsselt speichern (AES-256)
- **Übertragung**: TLS/HTTPS für alle API-Kommunikation
- **Passwörter**: Bcrypt/Argon2 Hashing
- **Lokale Daten**: Verschlüsselte lokale Datenbank auf Endgeräten
- **Medien**: Verschlüsselte Speicherung von Röntgenbildern, Dokumenten, etc.

### DSGVO & Datenschutz
- **Konto-Löschung**: Bei Löschung des Benutzerkontos werden ALLE Benutzerdaten automatisch und vollständig gelöscht
  - Eigene Tiere (wenn kein anderer Besitzer)
  - Alle persönlichen Daten
  - Hochgeladene Medien
  - Berechtigungen und Freigaben
- **Datenexport**: Benutzer können alle ihre Daten exportieren (DSGVO Art. 20)
- **Einwilligungen**: Klare Zustimmung für Datenverarbeitung
- **Datenminimierung**: Nur notwendige Daten erheben
- **Transparenz**: Klare Datenschutzerklärung

### Authentifizierung
- [ ] Sichere Passwort-Anforderungen
- [ ] Zwei-Faktor-Authentifizierung (2FA) optional
- [ ] Session-Management
- [ ] Passwort-Reset per E-Mail

### Audit & Logging
- [ ] Audit-Log für sensible Aktionen (Besitzerwechsel, Löschungen, etc.)
- [ ] Login-Historie
- [ ] Zugriffs-Protokollierung für medizinische Daten

---

## Datenmodell (Erste Ideen)

> **Wichtiges Prinzip**: Alle medizinischen und dienstleistungsbezogenen Daten gehören zum **Tier**, nicht zum Besitzer. Bei einem Besitzerwechsel bleiben alle Daten erhalten und gehen mit dem Tier zum neuen Besitzer über.

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
- `aktueller_besitzer_id`
- `foto_url`

### Besitzerwechsel (Historie)
- `id`
- `tier_id`
- `alter_besitzer_id`
- `neuer_besitzer_id`
- `wechsel_datum`
- `grund` (Verkauf, Schenkung, Erbschaft, etc.)
- `notizen`
- `bestätigt_von_neuem_besitzer` (boolean)
- `bestätigt_am`

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

### Medikations-Verabreichung (Tracking)
- `id`
- `medikation_id`
- `geplant_am` (Datum + Uhrzeit der geplanten Einnahme)
- `verabreicht` (boolean)
- `verabreicht_am` (tatsächlicher Zeitpunkt)
- `verabreicht_von` (Benutzer-ID, z.B. Besitzer)
- `notizen` (z.B. "Tier hat sich gewehrt", "nur halbe Dosis genommen")
- `übersprungen` (boolean, falls Dosis ausgelassen)
- `grund_übersprungen` (z.B. "Tier hat erbrochen")

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
- `anbieter_typ` (Tierarzt / Dienstleister)
- `anbieter_id` (tierarzt_id oder dienstleister_id)
- `gebucht_von` (Benutzer-ID)
- `datum_zeit`
- `grund`
- `status` (angefragt / bestätigt / abgeschlossen / abgesagt)
- `zugriff_gewährt` (boolean, automatisch bei Bestätigung)
- `zugriff_typ` (medizinisch / dienstleistung)

### Medien / Dokumente
- `id`
- `tier_id`
- `hochgeladen_von` (Benutzer-ID)
- `typ` (Röntgenbild, Laborbericht, Ultraschall, Foto, Dokument, etc.)
- `datei_url`
- `datei_name`
- `beschreibung`
- `verknüpft_mit` (medizinische_akte_id, nullable)
- `hochgeladen_am`

### Professionelle Notizen (Ärzte & Dienstleister)
- `id`
- `tier_id`
- `besitzer_id` (optional, für Notizen zum Besitzer)
- `erstellt_von` (Benutzer-ID)
- `ersteller_typ` (Tierarzt / Dienstleister)
- `inhalt`
- `sichtbarkeit` (privat / kollegial)
  - **privat**: Nur für den Ersteller sichtbar
  - **kollegial**: Für alle Ärzte ODER alle Dienstleister sichtbar (je nach Ersteller-Typ)
  - **NIE für Tierbesitzer sichtbar!**
- `erstellt_am`
- `aktualisiert_am`

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

### Besitzerwechsel
- [ ] Tier zum Verkauf/Übergabe freigeben
- [ ] Neuen Besitzer einladen (per E-Mail/Code)
- [ ] Alle Daten werden automatisch übertragen
- [ ] Medizinische Historie bleibt beim Tier
- [ ] Alter Besitzer verliert Zugriff nach Bestätigung
- [ ] Besitzerwechsel-Historie einsehbar

### Medikamenten-Verwaltung
- [ ] Verordnete Medikationen einsehen (vom Tierarzt)
- [ ] Dosierung und Anweisungen anzeigen
- [ ] Verabreichung als "gegeben" markieren
- [ ] Notizen zur Verabreichung hinzufügen (z.B. Probleme)
- [ ] Dosis als "übersprungen" markieren mit Begründung
- [ ] Medikamenten-Erinnerungen (Push-Benachrichtigung)
- [ ] Verabreichungs-Historie einsehen
- [ ] Restmenge tracken (Nachkauf-Warnung)
- [ ] Medikamenten-Historie (alle vergangenen Medikationen)

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

### Compliance-Überwachung
- [ ] Verabreichungs-Protokoll des Besitzers einsehen
- [ ] Sehen ob/wann Medikation gegeben wurde
- [ ] Übersprungene Dosen und Gründe einsehen
- [ ] Notizen des Besitzers zur Verabreichung lesen
- [ ] Compliance-Übersicht (% der gegebenen Dosen)
- [ ] Bei Problemen: Direkt Kontakt aufnehmen

### Terminbestätigung & Zugriff
- [ ] Terminanfragen von Tierbesitzern erhalten
- [ ] Bei Bestätigung: Automatischer Zugriff auf medizinische Unterlagen
- [ ] Zugriff endet nach Termin-Abschluss (oder konfigurierbar)

### Medien-Upload
- [ ] Röntgenbilder hochladen
- [ ] Ultraschallbilder hochladen
- [ ] Laborberichte anhängen
- [ ] Bilder mit medizinischer Akte verknüpfen
- [ ] Bildarchiv pro Tier

### Professionelle Notizen
- [ ] Private Notizen zu Tier anlegen (nur selbst sichtbar)
- [ ] Kollegiale Notizen (für alle Tierärzte sichtbar)
- [ ] Notizen zum Tierbesitzer (z.B. "zahlt immer pünktlich", "Compliance-Probleme")
- [ ] **Notizen sind NIE für Tierbesitzer sichtbar**

### Erweiterte Features
- [ ] Kalenderansicht für Termine
- [ ] Statistiken und Berichte
- [ ] Rechnungserstellung
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

### Terminbestätigung & Zugriff
- [ ] Terminanfragen von Tierbesitzern erhalten
- [ ] Bei Bestätigung: Automatischer Zugriff auf bisherige Dienstleistungen
- [ ] **KEIN Zugriff auf medizinische Daten** (nur eigene Dienstleistungskategorie)
- [ ] Zugriff endet nach Termin-Abschluss

### Professionelle Notizen
- [ ] Private Notizen zu Tier anlegen (nur selbst sichtbar)
- [ ] Kollegiale Notizen (für alle Dienstleister sichtbar)
- [ ] Notizen zum Tierbesitzer
- [ ] **Notizen sind NIE für Tierbesitzer sichtbar**

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

### Benutzerkonto & DSGVO
- `GET /account` - Eigene Kontodaten
- `PUT /account` - Kontodaten aktualisieren
- `DELETE /account` - Konto löschen (löscht ALLE Benutzerdaten)
- `GET /account/export` - Alle eigenen Daten exportieren (DSGVO)

### Tiere
- `GET /pets` - Alle Tiere des Besitzers
- `GET /pets/:id` - Einzelnes Tier
- `POST /pets` - Neues Tier anlegen
- `PUT /pets/:id` - Tier aktualisieren
- `DELETE /pets/:id` - Tier löschen

### Besitzerwechsel
- `POST /pets/:id/transfer` - Besitzerwechsel initiieren
- `GET /transfers/pending` - Ausstehende Übernahmen
- `POST /transfers/:id/confirm` - Übernahme bestätigen
- `POST /transfers/:id/reject` - Übernahme ablehnen
- `GET /pets/:id/ownership-history` - Besitzerhistorie

### Medizinische Akten
- `GET /pets/:id/records` - Alle Einträge eines Tiers
- `POST /pets/:id/records` - Neuer Eintrag (nur Tierarzt)

### Medikationen
- `GET /pets/:id/medications` - Alle Medikationen eines Tiers
- `GET /pets/:id/medications/active` - Aktive Medikationen
- `POST /pets/:id/medications` - Neue Medikation verordnen (nur Tierarzt)
- `PUT /medications/:id` - Medikation aktualisieren
- `PUT /medications/:id/status` - Status ändern (aktiv/pausiert/abgeschlossen)

### Medikations-Verabreichung (Tracking)
- `GET /medications/:id/schedule` - Geplante Verabreichungen
- `GET /medications/:id/administrations` - Verabreichungs-Historie
- `POST /medications/:id/administer` - Als verabreicht markieren (Besitzer)
- `POST /medications/:id/skip` - Als übersprungen markieren mit Grund (Besitzer)
- `GET /pets/:id/compliance` - Compliance-Übersicht für Tierarzt

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
- `GET /appointments` - Eigene Termine
- `POST /appointments` - Termin anfragen (Besitzer)
- `PUT /appointments/:id` - Termin aktualisieren
- `PUT /appointments/:id/confirm` - Termin bestätigen (Arzt/Dienstleister) → Zugriff wird gewährt
- `PUT /appointments/:id/complete` - Termin abschließen
- `DELETE /appointments/:id` - Termin absagen

### Medien / Dokumente
- `GET /pets/:id/media` - Alle Medien eines Tiers
- `POST /pets/:id/media` - Medium hochladen (Röntgen, Labor, etc.)
- `GET /media/:id` - Einzelnes Medium abrufen
- `DELETE /media/:id` - Medium löschen
- `PUT /media/:id` - Medium-Metadaten aktualisieren

### Professionelle Notizen
- `GET /pets/:id/notes` - Notizen zu einem Tier (nur für Profis)
- `GET /users/:id/notes` - Notizen zu einem Besitzer (nur für Profis)
- `POST /notes` - Neue Notiz anlegen
- `PUT /notes/:id` - Notiz bearbeiten
- `DELETE /notes/:id` - Notiz löschen
- `PUT /notes/:id/visibility` - Sichtbarkeit ändern (privat ↔ kollegial)

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

## Zukünftige Erweiterungen (Ideen)

### Geschäftlich / Finanzen
- [ ] Preislisten für Tierärzte und Dienstleister
- [ ] Rechnungen als PDF generieren
- [ ] Kostenübersicht pro Tier (Was hat das Tier bisher "gekostet"?)
- [ ] Versicherungsdaten des Tiers (Tierkrankenversicherung)

### Kommunikation
- [ ] Chat/Messaging zwischen Besitzer und Arzt/Dienstleister
- [ ] Videosprechstunde für Tierärzte

### Notfall & Sicherheit
- [ ] Notfall-Modus: Schnellzugriff auf wichtige Infos (Allergien, Blutgruppe, Medikamente)
- [ ] QR-Code Tier-Steckbrief für Finder (bei entlaufenem Tier)
- [ ] Notfallkontakte schnell erreichbar

### Erinnerungen & Automatisierung
- [ ] Automatische Erinnerungen für regelmäßige Termine (Entwurmung alle 3 Monate)
- [ ] Impf-Erinnerungen basierend auf Gültigkeitsdatum
- [ ] Medikamenten-Nachkauf-Warnung

### Integrationen
- [ ] Tierregister-Anbindung (TASSO, Findefix, etc.)
- [ ] Kalender-Integration (Google Calendar, Apple Calendar)
- [ ] Export für andere Systeme

### Tier-Gesundheit
- [ ] Futter- und Allergiemanagement (Was darf das Tier nicht fressen?)
- [ ] Gewichtskurve mit Zielgewicht
- [ ] Aktivitätstracking (optional, z.B. GPS-Tracker-Integration)

### Plattformen
- [ ] Web-Version zusätzlich zu den Apps
- [ ] Admin-Panel für Support und Verwaltung

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
