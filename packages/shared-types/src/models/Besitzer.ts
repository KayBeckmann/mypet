export class Besitzer {
    id: number;
    name: string;
    email: string;
    // Weitere Eigenschaften...
  
    constructor(id: number, name: string, email: string) {
      this.id = id;
      this.name = name;
      this.email = email;
    }
  
    // Eventuell gemeinsame Methoden
    getDisplayName(): string {
      return `<span class="math-inline">\{this\.name\} \(</span>{this.email})`;
    }
  }
  
  // Evtl. zugehörige Interfaces für API-Daten
  export interface BesitzerData {
      id: number;
      name: string;
      email: string;
      // ...
  }