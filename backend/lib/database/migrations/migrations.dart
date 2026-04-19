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
  _migration009AddSuperadminRole,
  _migration010CreateMedicalRecords,
  _migration011CreateVaccinations,
  _migration012CreateMedications,
  _migration013CreateMedicationAdministrations,
  _migration014CreateAppointments,
  _migration015CreateFeedingPlans,
  _migration016CreateFeedingMeals,
  _migration017CreateFeedingLog,
  _migration018CreateMedia,
  _migration019CreatePetNotes,
  _migration020CreateOwnershipTransfers,
  _migration021CreateAuditLog,
  _migration022CreateWeightHistory,
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

/// Migration 009: superadmin zur user_role enum hinzufügen
const _migration009AddSuperadminRole = Migration(
  version: 9,
  name: 'add_superadmin_role',
  up: '''
    ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'superadmin';
  ''',
  down: '''
    -- PostgreSQL erlaubt kein direktes Entfernen von Enum-Werten.
    -- Beim Rollback sicherstellen, dass kein Benutzer mehr die Rolle 'superadmin' hat.
    UPDATE users SET role = 'owner' WHERE role = 'superadmin';
  ''',
);

/// Migration 010: Medizinische Akten-Tabelle
const _migration010CreateMedicalRecords = Migration(
  version: 10,
  name: 'create_medical_records_table',
  up: '''
    CREATE TYPE medical_record_type AS ENUM (
      'checkup', 'diagnosis', 'treatment', 'surgery',
      'lab_result', 'prescription', 'observation', 'other'
    );

    CREATE TABLE medical_records (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
      vet_id UUID REFERENCES users(id) ON DELETE SET NULL,
      organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
      record_type medical_record_type NOT NULL DEFAULT 'observation',
      title VARCHAR(255) NOT NULL,
      description TEXT,
      diagnosis TEXT,
      treatment TEXT,
      follow_up_date DATE,
      is_private BOOLEAN NOT NULL DEFAULT false,
      recorded_at TIMESTAMP NOT NULL DEFAULT NOW(),
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW()
    );

    CREATE INDEX idx_medical_records_pet ON medical_records(pet_id);
    CREATE INDEX idx_medical_records_vet ON medical_records(vet_id);
    CREATE INDEX idx_medical_records_date ON medical_records(recorded_at DESC);

    CREATE TRIGGER update_medical_records_updated_at
      BEFORE UPDATE ON medical_records
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  ''',
  down: '''
    DROP TRIGGER IF EXISTS update_medical_records_updated_at ON medical_records;
    DROP TABLE IF EXISTS medical_records;
    DROP TYPE IF EXISTS medical_record_type;
  ''',
);

/// Migration 011: Impfungen
const _migration011CreateVaccinations = Migration(
  version: 11,
  name: 'create_vaccinations_table',
  up: '''
    CREATE TABLE vaccinations (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
      vet_id UUID REFERENCES users(id) ON DELETE SET NULL,
      organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
      vaccine_name VARCHAR(255) NOT NULL,
      batch_number VARCHAR(100),
      manufacturer VARCHAR(255),
      administered_at DATE NOT NULL DEFAULT CURRENT_DATE,
      valid_until DATE,
      notes TEXT,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW()
    );

    CREATE INDEX idx_vaccinations_pet ON vaccinations(pet_id);
    CREATE INDEX idx_vaccinations_valid_until ON vaccinations(valid_until);

    CREATE TRIGGER update_vaccinations_updated_at
      BEFORE UPDATE ON vaccinations
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  ''',
  down: '''
    DROP TRIGGER IF EXISTS update_vaccinations_updated_at ON vaccinations;
    DROP TABLE IF EXISTS vaccinations;
  ''',
);

/// Migration 012: Medikamente
const _migration012CreateMedications = Migration(
  version: 12,
  name: 'create_medications_table',
  up: '''
    CREATE TYPE medication_frequency AS ENUM (
      'once', 'daily', 'twice_daily', 'three_times_daily',
      'weekly', 'biweekly', 'monthly', 'as_needed', 'custom'
    );

    CREATE TABLE medications (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
      vet_id UUID REFERENCES users(id) ON DELETE SET NULL,
      organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
      name VARCHAR(255) NOT NULL,
      dosage VARCHAR(100),
      frequency medication_frequency NOT NULL DEFAULT 'daily',
      custom_frequency VARCHAR(100),
      instructions TEXT,
      start_date DATE NOT NULL DEFAULT CURRENT_DATE,
      end_date DATE,
      is_active BOOLEAN NOT NULL DEFAULT true,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW()
    );

    CREATE INDEX idx_medications_pet ON medications(pet_id);
    CREATE INDEX idx_medications_active ON medications(is_active) WHERE is_active = true;

    CREATE TRIGGER update_medications_updated_at
      BEFORE UPDATE ON medications
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  ''',
  down: '''
    DROP TRIGGER IF EXISTS update_medications_updated_at ON medications;
    DROP TABLE IF EXISTS medications;
    DROP TYPE IF EXISTS medication_frequency;
  ''',
);

/// Migration 013: Medikations-Verabreichungsprotokoll
const _migration013CreateMedicationAdministrations = Migration(
  version: 13,
  name: 'create_medication_administrations_table',
  up: '''
    CREATE TYPE administration_status AS ENUM ('given', 'skipped', 'delayed');

    CREATE TABLE medication_administrations (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      medication_id UUID NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
      administered_by UUID REFERENCES users(id) ON DELETE SET NULL,
      status administration_status NOT NULL DEFAULT 'given',
      scheduled_at TIMESTAMP NOT NULL,
      administered_at TIMESTAMP,
      notes TEXT,
      created_at TIMESTAMP NOT NULL DEFAULT NOW()
    );

    CREATE INDEX idx_med_admin_medication ON medication_administrations(medication_id);
    CREATE INDEX idx_med_admin_scheduled ON medication_administrations(scheduled_at);
  ''',
  down: '''
    DROP TABLE IF EXISTS medication_administrations;
    DROP TYPE IF EXISTS administration_status;
  ''',
);

/// Migration 014: Termine
const _migration014CreateAppointments = Migration(
  version: 14,
  name: 'create_appointments_table',
  up: '''
    CREATE TYPE appointment_status AS ENUM (
      'requested', 'confirmed', 'completed', 'cancelled', 'no_show'
    );

    CREATE TABLE appointments (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
      owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      provider_id UUID REFERENCES users(id) ON DELETE SET NULL,
      organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
      title VARCHAR(255) NOT NULL,
      description TEXT,
      status appointment_status NOT NULL DEFAULT 'requested',
      scheduled_at TIMESTAMP NOT NULL,
      duration_minutes INTEGER NOT NULL DEFAULT 30,
      location TEXT,
      notes TEXT,
      cancelled_reason TEXT,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW()
    );

    CREATE INDEX idx_appointments_pet ON appointments(pet_id);
    CREATE INDEX idx_appointments_owner ON appointments(owner_id);
    CREATE INDEX idx_appointments_provider ON appointments(provider_id);
    CREATE INDEX idx_appointments_status ON appointments(status);
    CREATE INDEX idx_appointments_scheduled ON appointments(scheduled_at);

    CREATE TRIGGER update_appointments_updated_at
      BEFORE UPDATE ON appointments
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  ''',
  down: '''
    DROP TRIGGER IF EXISTS update_appointments_updated_at ON appointments;
    DROP TABLE IF EXISTS appointments;
    DROP TYPE IF EXISTS appointment_status;
  ''',
);

/// Migration 015: Futterpläne
const _migration015CreateFeedingPlans = Migration(
  version: 15,
  name: 'create_feeding_plans_table',
  up: '''
    CREATE TABLE feeding_plans (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
      created_by UUID NOT NULL REFERENCES users(id),
      name VARCHAR(255) NOT NULL,
      description TEXT,
      is_active BOOLEAN NOT NULL DEFAULT true,
      valid_from DATE,
      valid_until DATE,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW()
    );

    CREATE INDEX idx_feeding_plans_pet ON feeding_plans(pet_id);
    CREATE INDEX idx_feeding_plans_active ON feeding_plans(is_active);

    CREATE TRIGGER update_feeding_plans_updated_at
      BEFORE UPDATE ON feeding_plans
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  ''',
  down: '''
    DROP TRIGGER IF EXISTS update_feeding_plans_updated_at ON feeding_plans;
    DROP TABLE IF EXISTS feeding_plans;
  ''',
);

/// Migration 016: Mahlzeiten & Komponenten
const _migration016CreateFeedingMeals = Migration(
  version: 16,
  name: 'create_feeding_meals_table',
  up: '''
    CREATE TABLE feeding_meals (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      plan_id UUID NOT NULL REFERENCES feeding_plans(id) ON DELETE CASCADE,
      name VARCHAR(255) NOT NULL,
      time_of_day TIME,
      notes TEXT,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at TIMESTAMP NOT NULL DEFAULT NOW()
    );

    CREATE INDEX idx_feeding_meals_plan ON feeding_meals(plan_id);

    CREATE TABLE feeding_components (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      meal_id UUID NOT NULL REFERENCES feeding_meals(id) ON DELETE CASCADE,
      food_name VARCHAR(255) NOT NULL,
      amount_grams NUMERIC(8,2),
      unit VARCHAR(50) NOT NULL DEFAULT 'g',
      notes TEXT,
      sort_order INTEGER NOT NULL DEFAULT 0
    );

    CREATE INDEX idx_feeding_components_meal ON feeding_components(meal_id);
  ''',
  down: '''
    DROP TABLE IF EXISTS feeding_components;
    DROP TABLE IF EXISTS feeding_meals;
  ''',
);

/// Migration 017: Fütterungs-Protokoll
const _migration017CreateFeedingLog = Migration(
  version: 17,
  name: 'create_feeding_log_table',
  up: '''
    CREATE TABLE feeding_log (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
      meal_id UUID REFERENCES feeding_meals(id) ON DELETE SET NULL,
      fed_by UUID NOT NULL REFERENCES users(id),
      fed_at TIMESTAMP NOT NULL DEFAULT NOW(),
      notes TEXT,
      amount_fed_grams NUMERIC(8,2),
      skipped BOOLEAN NOT NULL DEFAULT false,
      skip_reason TEXT,
      created_at TIMESTAMP NOT NULL DEFAULT NOW()
    );

    CREATE INDEX idx_feeding_log_pet ON feeding_log(pet_id);
    CREATE INDEX idx_feeding_log_fed_at ON feeding_log(fed_at);
    CREATE INDEX idx_feeding_log_meal ON feeding_log(meal_id);
  ''',
  down: '''
    DROP TABLE IF EXISTS feeding_log;
  ''',
);

/// Migration 018: Medien-Tabelle
const _migration022CreateWeightHistory = Migration(
  version: 22,
  name: 'create_weight_history_table',
  up: '''
    CREATE TABLE weight_history (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
      recorded_by UUID NOT NULL REFERENCES users(id),
      weight_kg DECIMAL(6,2) NOT NULL,
      notes TEXT,
      recorded_at TIMESTAMP NOT NULL DEFAULT NOW()
    );

    CREATE INDEX idx_weight_history_pet ON weight_history(pet_id);
    CREATE INDEX idx_weight_history_date ON weight_history(pet_id, recorded_at DESC);
  ''',
  down: 'DROP TABLE IF EXISTS weight_history;',
);

const _migration021CreateAuditLog = Migration(
  version: 21,
  name: 'create_audit_log_table',
  up: '''
    CREATE TABLE audit_log (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id UUID REFERENCES users(id) ON DELETE SET NULL,
      action VARCHAR(100) NOT NULL,
      resource_type VARCHAR(50),
      resource_id UUID,
      details JSONB,
      ip_address VARCHAR(45),
      created_at TIMESTAMP NOT NULL DEFAULT NOW()
    );

    CREATE INDEX idx_audit_log_user ON audit_log(user_id);
    CREATE INDEX idx_audit_log_action ON audit_log(action);
    CREATE INDEX idx_audit_log_resource ON audit_log(resource_type, resource_id);
    CREATE INDEX idx_audit_log_created ON audit_log(created_at DESC);
  ''',
  down: 'DROP TABLE IF EXISTS audit_log;',
);

const _migration020CreateOwnershipTransfers = Migration(
  version: 20,
  name: 'create_ownership_transfers_table',
  up: '''
    CREATE TYPE transfer_status AS ENUM (
      'pending', 'accepted', 'rejected', 'cancelled'
    );

    CREATE TABLE ownership_transfers (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
      from_owner_id UUID NOT NULL REFERENCES users(id),
      to_email VARCHAR(255) NOT NULL,
      to_user_id UUID REFERENCES users(id),
      status transfer_status NOT NULL DEFAULT 'pending',
      message TEXT,
      token VARCHAR(100) NOT NULL UNIQUE,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      responded_at TIMESTAMP
    );

    CREATE INDEX idx_transfers_pet ON ownership_transfers(pet_id);
    CREATE INDEX idx_transfers_from ON ownership_transfers(from_owner_id);
    CREATE INDEX idx_transfers_token ON ownership_transfers(token);
  ''',
  down: '''
    DROP TABLE IF EXISTS ownership_transfers;
    DROP TYPE IF EXISTS transfer_status;
  ''',
);

const _migration019CreatePetNotes = Migration(
  version: 19,
  name: 'create_pet_notes_table',
  up: '''
    CREATE TYPE note_visibility AS ENUM (
      'private', 'colleagues', 'all_professionals'
    );

    CREATE TABLE pet_notes (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
      author_id UUID NOT NULL REFERENCES users(id),
      organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
      title VARCHAR(255),
      content TEXT NOT NULL,
      visibility note_visibility NOT NULL DEFAULT 'private',
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW()
    );

    CREATE INDEX idx_pet_notes_pet ON pet_notes(pet_id);
    CREATE INDEX idx_pet_notes_author ON pet_notes(author_id);
    CREATE INDEX idx_pet_notes_org ON pet_notes(organization_id);
  ''',
  down: '''
    DROP TABLE IF EXISTS pet_notes;
    DROP TYPE IF EXISTS note_visibility;
  ''',
);

const _migration018CreateMedia = Migration(
  version: 18,
  name: 'create_media_table',
  up: '''
    CREATE TYPE media_type AS ENUM (
      'image', 'document', 'xray', 'video', 'other'
    );

    CREATE TABLE pet_media (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
      uploaded_by UUID NOT NULL REFERENCES users(id),
      medical_record_id UUID REFERENCES medical_records(id) ON DELETE SET NULL,
      media_type media_type NOT NULL DEFAULT 'image',
      filename VARCHAR(255) NOT NULL,
      original_name VARCHAR(255),
      mime_type VARCHAR(100) NOT NULL,
      file_size INTEGER NOT NULL,
      storage_path VARCHAR(500) NOT NULL,
      title VARCHAR(255),
      description TEXT,
      is_private BOOLEAN NOT NULL DEFAULT false,
      created_at TIMESTAMP NOT NULL DEFAULT NOW()
    );

    CREATE INDEX idx_pet_media_pet ON pet_media(pet_id);
    CREATE INDEX idx_pet_media_type ON pet_media(media_type);
    CREATE INDEX idx_pet_media_record ON pet_media(medical_record_id);
  ''',
  down: '''
    DROP TABLE IF EXISTS pet_media;
    DROP TYPE IF EXISTS media_type;
  ''',
);
