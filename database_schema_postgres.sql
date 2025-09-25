-- Database Schema v5 — Drop-in Replacement (PostgreSQL 14+)
-- Purpose: Production-ready, drop-in replacement schema addressing concurrency, security, retention,
-- media pipeline, auditability, and operational needs for the Elderly Daycare Platform.
-- This file contains: DDL for tables, enums, indices, partitioning examples, stored procedures
-- for transactional booking creation (SELECT FOR UPDATE), reservation sweeper, migration plan,
-- token hashing rollout plan, and rollback guidance. Execute in a maintenance window and
-- follow migration plan steps to avoid downtime.

-- ==========================================
-- Assumptions
-- - PostgreSQL 14+ (for generated columns, partitioning, and stable PL/pgSQL behavior).
-- - pgcrypto extension available for gen_random_uuid() and digest() functions.
-- - Times are stored as timestamptz.
-- - Application will use server-side envelope encryption for PHI-sensitive blobs.
-- ==========================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ========== ENUM TYPES =============
CREATE TYPE booking_status AS ENUM ('pending','confirmed','attended','cancelled','no_show','archived');
CREATE TYPE media_status AS ENUM ('pending','processing','ready','failed');
CREATE TYPE job_type AS ENUM ('transcode','thumbnail','caption','other');
CREATE TYPE created_via_t AS ENUM ('web','admin','phone','api');

-- ========== USERS & AUTH =============
CREATE TABLE users (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  email VARCHAR(254) NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  role VARCHAR(64) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE personal_access_tokens (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NULL,
  token_hash CHAR(64) NULL, -- SHA256 hex of token+server_secret
  last_four VARCHAR(8) NULL,
  abilities JSONB NULL,
  expires_at TIMESTAMPTZ NULL,
  revoked_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX ux_pat_token_hash ON personal_access_tokens(token_hash) WHERE token_hash IS NOT NULL;

CREATE TABLE user_sessions (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  session_token CHAR(64) NOT NULL UNIQUE,
  ip_address INET NULL,
  user_agent TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at TIMESTAMPTZ NULL
);

-- ========== CLIENTS & SENSITIVITY =============
CREATE TYPE sensitivity_t AS ENUM ('low','medium','high');

CREATE TABLE clients (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  first_name VARCHAR(255) NULL,
  last_name VARCHAR(255) NULL,
  dob DATE NULL,
  email VARCHAR(254) NULL,
  phone VARCHAR(64) NULL,
  address JSONB NULL,
  language_preference VARCHAR(16) DEFAULT 'en',
  consent_version VARCHAR(64) NULL,
  consent_given_by BIGINT NULL REFERENCES users(id),
  consent_revoked_at TIMESTAMPTZ NULL,
  sensitivity sensitivity_t NOT NULL DEFAULT 'medium',
  archived_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_clients_email ON clients (email);

CREATE TABLE client_health_info (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  client_id BIGINT NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  encrypted_blob BYTEA NOT NULL, -- application-layer envelope-encrypted PHI
  sensitivity sensitivity_t NOT NULL DEFAULT 'high',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE client_documents (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  client_id BIGINT NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  file_name VARCHAR(255) NOT NULL,
  content_type VARCHAR(128) NOT NULL,
  size_bytes BIGINT NOT NULL,
  s3_url TEXT NOT NULL,
  checksum CHAR(64) NULL,
  encrypted BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ========== SERVICES, FACILITIES & SLOTS =============
CREATE TABLE services (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  facility_id BIGINT NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT NULL,
  duration_minutes INT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE facilities (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  address JSONB NULL,
  phone VARCHAR(64) NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE booking_slots (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  service_id BIGINT NOT NULL REFERENCES services(id) ON DELETE CASCADE,
  facility_id BIGINT NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ NOT NULL,
  capacity INT NOT NULL DEFAULT 1,
  available_count INT NOT NULL DEFAULT 1,
  lock_version INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- Prevent duplicate slot definitions for same service/time/location
CREATE UNIQUE INDEX ux_booking_slots_unique_time ON booking_slots(service_id, facility_id, start_at, end_at);
CREATE INDEX ix_booking_slots_start_at ON booking_slots(start_at);

-- slot reservations (transient holds) -- used for payment holds or quick holds
CREATE TABLE slot_reservations (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  slot_id BIGINT NOT NULL REFERENCES booking_slots(id) ON DELETE CASCADE,
  reserved_by_user_id BIGINT NULL REFERENCES users(id),
  reserved_for_client_id BIGINT NULL REFERENCES clients(id),
  guest_email VARCHAR(254) NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (slot_id, reserved_for_client_id) WHERE reserved_for_client_id IS NOT NULL,
  UNIQUE (slot_id, guest_email) WHERE guest_email IS NOT NULL
);
CREATE INDEX ix_slot_reservations_expires_at ON slot_reservations(expires_at);

-- ========== BOOKINGS & HISTORY =============
CREATE TABLE bookings (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  slot_id BIGINT NOT NULL REFERENCES booking_slots(id) ON DELETE CASCADE,
  client_id BIGINT NULL REFERENCES clients(id) ON DELETE SET NULL,
  guest_email VARCHAR(254) NULL,
  status booking_status NOT NULL DEFAULT 'pending',
  created_by BIGINT NULL REFERENCES users(id),
  created_via created_via_t NOT NULL DEFAULT 'web',
  uuid UUID NOT NULL DEFAULT gen_random_uuid(),
  metadata JSONB NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  cancelled_at TIMESTAMPTZ NULL
);
-- Prevent duplicate authenticated bookings for same slot
CREATE UNIQUE INDEX ux_bookings_slot_client_unique ON bookings(slot_id, client_id) WHERE client_id IS NOT NULL;
-- Prevent duplicate guest bookings for same slot by email
CREATE UNIQUE INDEX ux_bookings_slot_guestemail_unique ON bookings(slot_id, guest_email) WHERE guest_email IS NOT NULL;
CREATE INDEX ix_bookings_status_created_at ON bookings(status, created_at);
CREATE INDEX ix_bookings_slot_id ON bookings(slot_id);

CREATE TABLE booking_status_history (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  booking_id BIGINT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  from_status booking_status NULL,
  to_status booking_status NOT NULL,
  changed_by BIGINT NULL REFERENCES users(id),
  changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ========== PAYMENTS & TRANSACTIONS =============
CREATE TABLE payments (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  booking_id BIGINT NULL REFERENCES bookings(id) ON DELETE SET NULL,
  amount_cents BIGINT NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'USD',
  provider VARCHAR(64) NOT NULL,
  provider_payment_id VARCHAR(255) NULL,
  status VARCHAR(32) NOT NULL,
  metadata JSONB NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_payments_booking_id ON payments(booking_id);

-- ========== MEDIA & TRANSCODING =============
CREATE TABLE media_items (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  owner_type VARCHAR(64) NOT NULL,
  owner_id BIGINT NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  content_type VARCHAR(128) NOT NULL,
  size_bytes BIGINT NOT NULL,
  master_s3_url TEXT NOT NULL,
  renditions JSONB NULL,
  captions_s3_url TEXT NULL,
  transcript_s3_url TEXT NULL,
  status media_status NOT NULL DEFAULT 'pending',
  checksum CHAR(64) NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_at TIMESTAMPTZ NULL
);
CREATE INDEX ix_media_owner ON media_items (owner_type, owner_id);

CREATE TABLE media_job_queue (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  media_id BIGINT NOT NULL REFERENCES media_items(id) ON DELETE CASCADE,
  job_type job_type NOT NULL,
  payload JSONB NULL,
  attempts INT NOT NULL DEFAULT 0,
  scheduled_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  locked_until TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_media_job_queue_locked ON media_job_queue (locked_until) WHERE locked_until IS NOT NULL;

-- ========== JOB & FAILED JOB TRACKING =============
CREATE TABLE job_queue (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  queue_name VARCHAR(128) NOT NULL,
  payload JSONB NOT NULL,
  attempts INT NOT NULL DEFAULT 0,
  scheduled_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  locked_until TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_job_queue_queue_name ON job_queue (queue_name);

CREATE TABLE failed_jobs (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  connection JSONB NULL,
  payload JSONB NOT NULL,
  exception TEXT NULL,
  failed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ========== AUDIT LOGS & PARTITIONING =============
-- Use declarative partitioning by month for audit_logs
CREATE TABLE audit_logs (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  actor_user_id BIGINT NULL REFERENCES users(id),
  action VARCHAR(128) NOT NULL,
  target_table VARCHAR(128) NULL,
  target_id BIGINT NULL,
  payload JSONB NULL,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
) PARTITION BY RANGE (occurred_at);

-- Create partitions for next 18 months as example (create script or cron to add partitions regularly)
CREATE TABLE audit_logs_p202501 PARTITION OF audit_logs FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE audit_logs_p202502 PARTITION OF audit_logs FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
-- (Add additional partitions as operations calendar requires)

-- ========== ANALYTICS & PAGE VIEWS (PARTITIONED) =============
CREATE TABLE page_views (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  path TEXT NOT NULL,
  visitor_id UUID NULL,
  referrer TEXT NULL,
  user_agent TEXT NULL,
  view_time TIMESTAMPTZ NOT NULL DEFAULT now()
) PARTITION BY RANGE (view_time);
-- create monthly partitions operationally

-- ========== SEARCH CONTENT =============
CREATE TABLE pages (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  slug VARCHAR(255) NOT NULL UNIQUE,
  title VARCHAR(255) NOT NULL,
  excerpt TEXT NULL,
  content TEXT NULL,
  published BOOLEAN NOT NULL DEFAULT FALSE,
  published_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX pages_content_ft_idx ON pages USING GIN (to_tsvector('english', coalesce(title,'') || ' ' || coalesce(excerpt,'') || ' ' || coalesce(content,'')));

-- ========== TESTIMONIALS / RESOURCES =============
CREATE TABLE testimonials (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  client_id BIGINT NULL REFERENCES clients(id),
  author_name VARCHAR(255) NULL,
  body TEXT NOT NULL,
  published BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE resources (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  content TEXT NULL,
  file_url TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ========== EMAIL & SMS LOGS =============
CREATE TABLE email_logs (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  to_address VARCHAR(254) NOT NULL,
  subject VARCHAR(512) NULL,
  template VARCHAR(255) NULL,
  provider_message_id VARCHAR(255) NULL,
  status VARCHAR(64) NULL,
  attempted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE sms_logs (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  to_number VARCHAR(64) NOT NULL,
  body TEXT NOT NULL,
  provider_message_id VARCHAR(255) NULL,
  status VARCHAR(64) NULL,
  attempted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ========== INDEXING / COMMON QUERIES =============
CREATE INDEX ix_services_facility ON services(facility_id);
CREATE INDEX ix_bookings_client_id ON bookings(client_id);
CREATE INDEX ix_booking_slots_facility_start ON booking_slots(facility_id, start_at);

-- ========== TRANSACTIONAL BOOKING FUNCTION =============
-- Creates a booking with DB-level locking to prevent overbooking and duplicates.
CREATE OR REPLACE FUNCTION create_booking(
  p_slot_id BIGINT,
  p_client_id BIGINT DEFAULT NULL,
  p_guest_email VARCHAR DEFAULT NULL,
  p_created_by BIGINT DEFAULT NULL,
  p_created_via created_via_t DEFAULT 'web'
) RETURNS BIGINT LANGUAGE plpgsql AS $$
DECLARE
  v_available INT;
  v_capacity INT;
  v_booking_id BIGINT;
BEGIN
  -- Lock slot row
  SELECT capacity, available_count INTO v_capacity, v_available
    FROM booking_slots WHERE id = p_slot_id FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'slot_not_found';
  END IF;

  IF v_available <= 0 THEN
    RAISE EXCEPTION 'slot_full';
  END IF;

  -- Prevent duplicate authenticated client booking
  IF p_client_id IS NOT NULL THEN
    IF EXISTS(SELECT 1 FROM bookings WHERE slot_id = p_slot_id AND client_id = p_client_id AND status IN ('pending','confirmed')) THEN
      RAISE EXCEPTION 'duplicate_booking_for_client';
    END IF;
  ELSIF p_guest_email IS NOT NULL THEN
    IF EXISTS(SELECT 1 FROM bookings WHERE slot_id = p_slot_id AND guest_email = p_guest_email AND status IN ('pending','confirmed')) THEN
      RAISE EXCEPTION 'duplicate_booking_for_guest';
    END IF;
  END IF;

  -- Decrement available_count
  UPDATE booking_slots
    SET available_count = available_count - 1,
        lock_version = lock_version + 1,
        updated_at = now()
    WHERE id = p_slot_id;

  -- Insert booking as confirmed
  INSERT INTO bookings (slot_id, client_id, guest_email, status, created_by, created_via, uuid, metadata, created_at, updated_at)
    VALUES (p_slot_id, p_client_id, p_guest_email, 'confirmed', p_created_by, p_created_via, gen_random_uuid(), '{}'::jsonb, now(), now())
    RETURNING id INTO v_booking_id;

  INSERT INTO booking_status_history (booking_id, from_status, to_status, changed_by, changed_at)
    VALUES (v_booking_id, NULL, 'confirmed', p_created_by, now());

  RETURN v_booking_id;
EXCEPTION WHEN OTHERS THEN
  -- Let the application handle and map exceptions to user-friendly errors
  RAISE;
END;
$$;

-- ========== RESERVATION SWEEPER (background maintenance) =============
-- Deletes expired reservations and restores slot.available_count accordingly.
CREATE OR REPLACE FUNCTION sweep_expired_reservations() RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN SELECT id, slot_id FROM slot_reservations WHERE expires_at <= now() FOR UPDATE SKIP LOCKED
  LOOP
    -- Restore slot counts
    UPDATE booking_slots SET available_count = available_count + 1, updated_at = now() WHERE id = rec.slot_id;
    DELETE FROM slot_reservations WHERE id = rec.id;
  END LOOP;
END;
$$;

-- It's recommended to call sweep_expired_reservations() from a scheduled job every minute.

-- ========== TOKEN HASH ROLLOUT PROCEDURE (migration guidance) =============
-- 1) Add token_hash, last_four columns (already present in schema above)
-- 2) One-time migration: for each existing token row that still has token value (if migrating from old schema), compute token_hash = sha256(token || server_secret)
-- 3) Update application to use token_hash lookup and stop writing raw token. Store only last_four for display.
-- 4) Once application is updated and old tokens considered rotated, drop raw token column and rely on token_hash.

-- Encryption and PHI storage note: store PHI fields (client_health_info.encrypted_blob, client_documents.encrypted) as envelope-encrypted by application; DB only stores ciphertext.

-- ========== MIGRATION & ROLLBACK PLAN (step-by-step)
-- A safe rollout sequence for existing deployments:
-- Step A: Prepare
--   1) Schedule maintenance window and notify stakeholders.
--   2) Ensure backups and snapshot of DB taken and verified.
-- Step B: Non-blocking changes
--   1) Add new nullable columns and new tables (e.g., slot_reservations, payments, media_job_queue, token_hash column already added in this schema).
--   2) Deploy application that is compatible with both old and new schema (feature-flagged behavior).
-- Step C: Backfill and data migration
--   1) Run backfill scripts to populate token_hash from existing tokens (using server_secret held in KMS); rotate tokens where possible.
--   2) Backfill available_count from capacity - SUM(bookings per slot) if inconsistent.
-- Step D: Switchover
--   1) Deploy application code that uses the new transactional booking function (create_booking) and slot_reservations for holds.
--   2) Monitor metrics (booking success/failures, availability) in staging then production.
-- Step E: Cleanup
--   1) After 2+ deployment cycles with no issues, drop deprecated columns and old indexes.
-- Rollback guidance:
--   - If an issue occurs, halt new deployments and revert application to previous image that supports both schemas.
--   - Use DB snapshot for major rollbacks only with caution; prefer application-level rollback.

-- ========== SAMPLE TESTS & VERIFICATION QUERIES =============
-- 1) Verify unique constraint for authenticated clients:
-- SELECT COUNT(*) FROM (SELECT slot_id, client_id, COUNT(*) FROM bookings WHERE client_id IS NOT NULL GROUP BY slot_id, client_id HAVING COUNT(*) > 1) t;

-- 2) Verify available_count never negative after simulated bookings.
-- 3) Run concurrency booking tests in a staging environment using multiple parallel clients invoking create_booking().

-- ========== CLEANUP & MAINTENANCE SCRIPTS =============
-- Example: create next month's partition for audit_logs (run monthly via automation)
-- CREATE TABLE audit_logs_p202503 PARTITION OF audit_logs FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

-- ==========================================
-- End of Database Schema v5
-- ==========================================
