import '../migrator.dart';

/// Alle Migrationen (in Reihenfolge)
const List<Migration> migrations = [
  _migration001CreateUsers,
];

/// Migration 001: Benutzer-Tabelle erstellen
const _migration001CreateUsers = Migration(
  version: 1,
  name: 'create_users_table',
  up: '''
    -- Enum für Benutzerrollen
    CREATE TYPE user_role AS ENUM ('owner', 'vet', 'provider');

    -- Benutzer-Tabelle
    CREATE TABLE users (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      email VARCHAR(255) NOT NULL UNIQUE,
      password_hash VARCHAR(255) NOT NULL,
      name VARCHAR(255) NOT NULL,
      role user_role NOT NULL DEFAULT 'owner',
      is_active BOOLEAN NOT NULL DEFAULT true,
      email_verified BOOLEAN NOT NULL DEFAULT false,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW()
    );

    -- Index für E-Mail-Suche
    CREATE INDEX idx_users_email ON users(email);

    -- Index für Rolle
    CREATE INDEX idx_users_role ON users(role);

    -- Trigger für updated_at
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS \$\$
    BEGIN
      NEW.updated_at = NOW();
      RETURN NEW;
    END;
    \$\$ language 'plpgsql';

    CREATE TRIGGER update_users_updated_at
      BEFORE UPDATE ON users
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  ''',
  down: '''
    DROP TRIGGER IF EXISTS update_users_updated_at ON users;
    DROP FUNCTION IF EXISTS update_updated_at_column();
    DROP TABLE IF EXISTS users;
    DROP TYPE IF EXISTS user_role;
  ''',
);
