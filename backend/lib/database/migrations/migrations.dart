import '../migrator.dart';

/// Alle Migrationen (in Reihenfolge)
const List<Migration> migrations = [
  _migration001CreateUsers,
  _migration002CreatePets,
  _migration003CreateOrganizations,
  _migration004CreateOrganizationMembers,
  _migration005CreatePermissionGroups,
  _migration006CreateOrganizationInvitations,
  _migration007CreateFamilies,
  _migration008CreateAccessPermissions,
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

/// Migration 002: Tier-Tabelle erstellen
const _migration002CreatePets = Migration(
  version: 2,
  name: 'create_pets_table',
  up: '''
    -- Enum für Tierarten
    CREATE TYPE pet_species AS ENUM (
      'dog', 'cat', 'horse', 'bird', 'rabbit', 'reptile', 'other'
    );

    -- Tier-Tabelle
    CREATE TABLE pets (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      name VARCHAR(255) NOT NULL,
      species pet_species NOT NULL DEFAULT 'dog',
      breed VARCHAR(255),
      birth_date DATE,
      weight_kg DECIMAL(8,2),
      microchip_id VARCHAR(50),
      image_url TEXT,
      notes TEXT,
      is_active BOOLEAN NOT NULL DEFAULT true,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW()
    );

    -- Indizes
    CREATE INDEX idx_pets_owner ON pets(owner_id);
    CREATE INDEX idx_pets_species ON pets(species);
    CREATE INDEX idx_pets_microchip ON pets(microchip_id) WHERE microchip_id IS NOT NULL;

    -- Trigger für updated_at
    CREATE TRIGGER update_pets_updated_at
      BEFORE UPDATE ON pets
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  ''',
  down: '''
    DROP TRIGGER IF EXISTS update_pets_updated_at ON pets;
    DROP TABLE IF EXISTS pets;
    DROP TYPE IF EXISTS pet_species;
  ''',
);

/// Migration 003: Organisationen (Praxen & Firmen)
const _migration003CreateOrganizations = Migration(
  version: 3,
  name: 'create_organizations_table',
  up: '''
    -- Enum für Organisationstyp
    CREATE TYPE organization_type AS ENUM ('vet_practice', 'provider_company');

    -- Organisations-Tabelle
    CREATE TABLE organizations (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name VARCHAR(255) NOT NULL,
      type organization_type NOT NULL,
      provider_type VARCHAR(100),
      description TEXT,
      address TEXT,
      phone VARCHAR(50),
      mobile VARCHAR(50),
      email VARCHAR(255),
      website VARCHAR(255),
      opening_hours TEXT,
      service_radius_km INTEGER,
      specialization VARCHAR(255),
      created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
      is_active BOOLEAN NOT NULL DEFAULT true,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW()
    );

    CREATE INDEX idx_organizations_type ON organizations(type);
    CREATE INDEX idx_organizations_created_by ON organizations(created_by);

    CREATE TRIGGER update_organizations_updated_at
      BEFORE UPDATE ON organizations
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  ''',
  down: '''
    DROP TRIGGER IF EXISTS update_organizations_updated_at ON organizations;
    DROP TABLE IF EXISTS organizations;
    DROP TYPE IF EXISTS organization_type;
  ''',
);

/// Migration 004: Organisations-Mitgliedschaften
const _migration004CreateOrganizationMembers = Migration(
  version: 4,
  name: 'create_organization_members_table',
  up: '''
    -- Enum für Mitglieds-Rolle
    CREATE TYPE organization_member_role AS ENUM ('admin', 'member', 'readonly');

    -- Organisations-Mitgliedschaften
    CREATE TABLE organization_members (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
      user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      role organization_member_role NOT NULL DEFAULT 'member',
      position VARCHAR(100),
      permission_group_id UUID,
      invited_by UUID REFERENCES users(id) ON DELETE SET NULL,
      joined_at TIMESTAMP NOT NULL DEFAULT NOW(),
      is_active BOOLEAN NOT NULL DEFAULT true,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
      UNIQUE (organization_id, user_id)
    );

    CREATE INDEX idx_org_members_org ON organization_members(organization_id);
    CREATE INDEX idx_org_members_user ON organization_members(user_id);
    CREATE INDEX idx_org_members_role ON organization_members(role);

    CREATE TRIGGER update_organization_members_updated_at
      BEFORE UPDATE ON organization_members
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  ''',
  down: '''
    DROP TRIGGER IF EXISTS update_organization_members_updated_at ON organization_members;
    DROP TABLE IF EXISTS organization_members;
    DROP TYPE IF EXISTS organization_member_role;
  ''',
);

/// Migration 005: Berechtigungsgruppen
const _migration005CreatePermissionGroups = Migration(
  version: 5,
  name: 'create_permission_groups_table',
  up: '''
    CREATE TABLE permission_groups (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
      name VARCHAR(100) NOT NULL,
      description TEXT,
      permissions JSONB NOT NULL DEFAULT '{}'::jsonb,
      is_system BOOLEAN NOT NULL DEFAULT false,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
      UNIQUE (organization_id, name)
    );

    CREATE INDEX idx_permission_groups_org ON permission_groups(organization_id);

    CREATE TRIGGER update_permission_groups_updated_at
      BEFORE UPDATE ON permission_groups
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();

    -- Fremdschlüssel für organization_members.permission_group_id nachziehen
    ALTER TABLE organization_members
      ADD CONSTRAINT organization_members_permission_group_fk
      FOREIGN KEY (permission_group_id)
      REFERENCES permission_groups(id) ON DELETE SET NULL;
  ''',
  down: '''
    ALTER TABLE organization_members
      DROP CONSTRAINT IF EXISTS organization_members_permission_group_fk;
    DROP TRIGGER IF EXISTS update_permission_groups_updated_at ON permission_groups;
    DROP TABLE IF EXISTS permission_groups;
  ''',
);

/// Migration 006: Organisations-Einladungen
const _migration006CreateOrganizationInvitations = Migration(
  version: 6,
  name: 'create_organization_invitations_table',
  up: '''
    CREATE TYPE organization_invitation_status AS ENUM (
      'pending', 'accepted', 'rejected', 'expired', 'revoked'
    );

    CREATE TABLE organization_invitations (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
      email VARCHAR(255) NOT NULL,
      role organization_member_role NOT NULL DEFAULT 'member',
      position VARCHAR(100),
      permission_group_id UUID REFERENCES permission_groups(id) ON DELETE SET NULL,
      invitation_code UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
      invited_by UUID REFERENCES users(id) ON DELETE SET NULL,
      status organization_invitation_status NOT NULL DEFAULT 'pending',
      expires_at TIMESTAMP NOT NULL DEFAULT (NOW() + INTERVAL '14 days'),
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW()
    );

    CREATE INDEX idx_org_invitations_org ON organization_invitations(organization_id);
    CREATE INDEX idx_org_invitations_email ON organization_invitations(email);
    CREATE INDEX idx_org_invitations_status ON organization_invitations(status);

    CREATE TRIGGER update_organization_invitations_updated_at
      BEFORE UPDATE ON organization_invitations
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  ''',
  down: '''
    DROP TRIGGER IF EXISTS update_organization_invitations_updated_at ON organization_invitations;
    DROP TABLE IF EXISTS organization_invitations;
    DROP TYPE IF EXISTS organization_invitation_status;
  ''',
);

/// Migration 007: Familien
const _migration007CreateFamilies = Migration(
  version: 7,
  name: 'create_families_tables',
  up: '''
    CREATE TYPE family_member_role AS ENUM ('owner', 'member');

    CREATE TABLE families (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name VARCHAR(255) NOT NULL,
      created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW()
    );

    CREATE INDEX idx_families_created_by ON families(created_by);

    CREATE TRIGGER update_families_updated_at
      BEFORE UPDATE ON families
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();

    CREATE TABLE family_members (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
      user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      role family_member_role NOT NULL DEFAULT 'member',
      joined_at TIMESTAMP NOT NULL DEFAULT NOW(),
      UNIQUE (family_id, user_id)
    );

    CREATE INDEX idx_family_members_family ON family_members(family_id);
    CREATE INDEX idx_family_members_user ON family_members(user_id);
  ''',
  down: '''
    DROP TABLE IF EXISTS family_members;
    DROP TRIGGER IF EXISTS update_families_updated_at ON families;
    DROP TABLE IF EXISTS families;
    DROP TYPE IF EXISTS family_member_role;
  ''',
);

/// Migration 008: Zugriffsberechtigungen (Freigaben an andere User)
const _migration008CreateAccessPermissions = Migration(
  version: 8,
  name: 'create_access_permissions_table',
  up: '''
    CREATE TYPE access_permission_type AS ENUM ('read', 'write', 'manage');
    CREATE TYPE access_subject_type AS ENUM ('user', 'organization');

    CREATE TABLE access_permissions (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
      granted_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      subject_type access_subject_type NOT NULL,
      subject_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
      subject_organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
      permission access_permission_type NOT NULL DEFAULT 'read',
      starts_at TIMESTAMP,
      ends_at TIMESTAMP,
      note TEXT,
      is_active BOOLEAN NOT NULL DEFAULT true,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
      CONSTRAINT access_permission_subject_check CHECK (
        (subject_type = 'user' AND subject_user_id IS NOT NULL AND subject_organization_id IS NULL) OR
        (subject_type = 'organization' AND subject_organization_id IS NOT NULL AND subject_user_id IS NULL)
      )
    );

    CREATE INDEX idx_access_permissions_pet ON access_permissions(pet_id);
    CREATE INDEX idx_access_permissions_user ON access_permissions(subject_user_id) WHERE subject_user_id IS NOT NULL;
    CREATE INDEX idx_access_permissions_org ON access_permissions(subject_organization_id) WHERE subject_organization_id IS NOT NULL;

    CREATE TRIGGER update_access_permissions_updated_at
      BEFORE UPDATE ON access_permissions
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  ''',
  down: '''
    DROP TRIGGER IF EXISTS update_access_permissions_updated_at ON access_permissions;
    DROP TABLE IF EXISTS access_permissions;
    DROP TYPE IF EXISTS access_subject_type;
    DROP TYPE IF EXISTS access_permission_type;
  ''',
);
