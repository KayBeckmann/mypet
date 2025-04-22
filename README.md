# mypet - Haustierverwaltung

Verwalte alle deine Tiere. Dieses Projekt ist eine Monorepository-Anwendung zur Verwaltung von Haustieren, die aus zwei Frontends (für Tierbesitzer und Tierärzte) und einem gemeinsamen Backend besteht.

## ✨ Projektübersicht

* **Besitzer-Frontend:** Eine Vue 3 Anwendung für Haustierbesitzer zur Verwaltung ihrer Tiere und Termine.
* **Tierarzt-Frontend:** Eine Vue 3 Anwendung für Tierärzte zur Verwaltung von Patientenakten und Terminen.
* **Backend-API:** Eine modulare Express.js REST-API, die als zentrale Datenquelle dient und mit einer SQL-Datenbank kommuniziert.
* **Geteilte Typen:** Ein separates Paket (`packages/shared-types`) enthält TypeScript-Klassen und -Interfaces, die von beiden Frontends und dem Backend verwendet werden, um Konsistenz sicherzustellen.

## 🚀 Tech Stack

* **Monorepo Management:** pnpm Workspaces
* **Frontend:** Vue 3 (mit Vite), TypeScript, Pinia (optional, für State Management), CSS/SCSS
* **Backend:** Node.js, Express.js, TypeScript
* **Datenbank:** SQL (z.B. PostgreSQL, MySQL - spezifische Wahl noch offen)
* **Typisierung:** TypeScript durchgehend
* **(Optional) ORM:** Prisma oder TypeORM für die Datenbankinteraktion im Backend

## 📂 Monorepo Struktur

Dieses Projekt verwendet `pnpm` Workspaces zur Verwaltung der Pakete innerhalb des Monorepos.

```plaintext
/
├── apps/
│   ├── frontend-besitzer/  # Vue 3 App für Besitzer
│   ├── frontend-tierarzt/  # Vue 3 App für Tierärzte
│   └── backend-api/        # Express.js Backend API
├── packages/
│   └── shared-types/       # Geteilte TypeScript Klassen & Interfaces
├── package.json            # Root package.json (definiert pnpm workspace)
├── pnpm-workspace.yaml     # pnpm Workspace Konfiguration
├── tsconfig.base.json      # Gemeinsame TypeScript Basis-Konfiguration
└── README.md               # Diese Datei

