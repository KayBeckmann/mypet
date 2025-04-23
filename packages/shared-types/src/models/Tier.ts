// In packages/shared-types/src/models/Tier.ts (oder ähnlich)

// Importiere ggf. andere Typen, falls nötig (z.B. Besitzer)
// import { Besitzer } from './Besitzer'; // Falls du eine direkte Objekt-Referenz möchtest (oft nur ID besser)

// --- Hilfstypen für komplexe Eigenschaften ---

export enum Spezies {
    HUND = 'Hund',
    KATZE = 'Katze',
    MAUS = 'Maus',
    PFERD = 'Pferd',
    VOGEL = 'Vogel',
    REPTIL = 'Reptil',
    FISCH = 'Fisch',
    ANDERES = 'Anderes', // Für Flexibilität
  }
  
  export enum Tageszeit {
    MORGENS = 'Morgens',
    MITTAGS = 'Mittags',
    ABENDS = 'Abends',
    NACHTS = 'Nachts', // Nur für Medikation relevant laut Beschreibung
  }
  
  export interface ZeitWertPaar<T> {
    datum: Date;
    wert: T;
    // Optional: Einheit (z.B. 'cm', 'kg')
    einheit?: string;
  }
  
  export interface FuetterungsPlan {
    bestandteile: string; // Beschreibung des Futters
    menge: number;
    einheit: string; // z.B. 'g', 'ml', 'Stück'
    tageszeit: Exclude<Tageszeit, Tageszeit.NACHTS>[]; // Array, falls Fütterung zu mehreren Zeiten stattfindet
  }
  
  export interface MedikationsPlan {
    produkt: string; // Name des Medikaments/Produkts
    menge: number;
    einheit: string; // z.B. 'mg', 'ml', 'Tablette(n)'
    tageszeit: Tageszeit[]; // Array, falls Medikation zu mehreren Zeiten stattfindet
    // Optional: Dauer, Grund, etc.
    anwendungsdauer?: string;
    grund?: string;
  }
  
  export interface KrankenakteEintrag {
    datum: Date;
    diagnose: string;
    behandlung?: string; // Optional
    tierarzt?: string; // Optional, Name/ID des behandelnden Arztes
    notizen?: string; // Optional
  }
  
  export enum BildTyp {
    PROFIL = 'Profil',
    ROENTGEN = 'Röntgen',
    ULTRASCHALL = 'Ultraschall',
    DOKUMENT = 'Dokument', // z.B. Laborbericht
    SONSTIGES = 'Sonstiges',
  }
  
  export interface Bild {
    url: string; // Pfad/URL zum Bild
    typ: BildTyp;
    beschreibung?: string; // Optional
    datum: Date;
  }
  
  // --- Die Hauptklasse 'Tier' ---
  
  export class Tier {
    id: number; // Eindeutige ID des Tieres (typischerweise von der Datenbank)
    name: string;
    geburtsdatum?: Date; // Optional, falls unbekannt
    spezies: Spezies;
    rasse?: string; // Optional, da nicht für alle Spezies relevant oder bekannt
    besitzerId: number; // Fremdschlüssel zum Besitzer (1:n Beziehung)
  
    // Verlaufsdaten als Arrays von Objekten
    groesseVerlauf: ZeitWertPaar<number>[]; // Wert z.B. in cm
    gewichtVerlauf: ZeitWertPaar<number>[]; // Wert z.B. in kg
  
    fuetterung: FuetterungsPlan[]; // Ein Array, falls es verschiedene Fütterungen gibt
    krankenakte: KrankenakteEintrag[];
    medikation: MedikationsPlan[];
    bilder: Bild[];
  
    // --- Berechtigungs-bezogene Daten (Beispielhaft!) ---
    // Diese Struktur ist nur ein Beispiel, die Logik liegt im Backend!
    // Die tatsächliche Implementierung der Freigabe ist komplexer und gehört ins Backend.
    // Man könnte hier höchstens Metadaten speichern, WER Zugriff HAT, aber nicht die Logik selbst.
    // freigaben: { benutzerId: number, berechtigung: 'lesen' | 'schreiben' }[];
  
    constructor(
      id: number,
      name: string,
      spezies: Spezies,
      besitzerId: number,
      geburtsdatum?: Date,
      rasse?: string
      // Initialisiere Arrays leer oder übergebe sie im Konstruktor
    ) {
      this.id = id;
      this.name = name;
      this.spezies = spezies;
      this.besitzerId = besitzerId;
      this.geburtsdatum = geburtsdatum;
      this.rasse = rasse;
  
      // Initialisiere Verläufe und Listen als leere Arrays
      this.groesseVerlauf = [];
      this.gewichtVerlauf = [];
      this.fuetterung = [];
      this.krankenakte = [];
      this.medikation = [];
      this.bilder = [];
      // this.freigaben = [];
    }
  
    // --- Optionale Methoden ---
  
    getAlter(): number | undefined {
      if (!this.geburtsdatum) return undefined;
      const heute = new Date();
      let alter = heute.getFullYear() - this.geburtsdatum.getFullYear();
      const monatDifferenz = heute.getMonth() - this.geburtsdatum.getMonth();
      if (monatDifferenz < 0 || (monatDifferenz === 0 && heute.getDate() < this.geburtsdatum.getDate())) {
        alter--;
      }
      return alter;
    }
  
    addGroesse(wert: number, datum: Date = new Date(), einheit: string = 'cm'): void {
      this.groesseVerlauf.push({ datum, wert, einheit });
      // Optional: Sortieren nach Datum
      this.groesseVerlauf.sort((a, b) => a.datum.getTime() - b.datum.getTime());
    }
  
    addGewicht(wert: number, datum: Date = new Date(), einheit: string = 'kg'): void {
      this.gewichtVerlauf.push({ datum, wert, einheit });
      this.gewichtVerlauf.sort((a, b) => a.datum.getTime() - b.datum.getTime());
    }
  
    // Ähnliche Methoden für addFuetterung, addKrankenakteEintrag etc. könnten hier hinzugefügt werden.
  }