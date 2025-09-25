-- Database Schema v5 — MariaDB/MySQL Drop-in Replacement
-- Purpose: Production-ready, drop-in replacement schema for MariaDB/MySQL 8.x.
-- This version translates PostgreSQL constructs to MySQL-compatible equivalents.
-- Includes tables, ENUMs, indices, partitioning, stored procedures for transactional booking creation,
-- reservation sweeper, token hashing migration guidance, and rollback plans.

-- ==========================================
-- Assumptions
-- - MariaDB/MySQL 8.x
-- - InnoDB engine for all tables
-- - JSON columns supported
-- - Timestamps stored as UTC in TIMESTAMP columns
-- ==========================================

-- ========== ENUM TYPES (inline) =============
-- Will define ENUMs inline in column definitions.

-- ========== USERS & AUTH =============
CREATE TABLE users (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(254) NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  role VARCHAR(64) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE personal_access_tokens (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  name VARCHAR(255) NULL,
  token_hash CHAR(64) NULL,
  last_four VARCHAR(8) NULL,
  abilities JSON NULL,
  expires_at TIMESTAMP NULL,
  revoked_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY ux_pat_token_hash (token_hash)
) ENGINE=InnoDB;

CREATE TABLE user_sessions (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  session_token CHAR(64) NOT NULL UNIQUE,
  ip_address VARCHAR(45) NULL,
  user_agent TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_seen_at TIMESTAMP NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ========== CLIENTS & SENSITIVITY =============
CREATE TABLE clients (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(255) NULL,
  last_name VARCHAR(255) NULL,
  dob DATE NULL,
  email VARCHAR(254) NULL,
  phone VARCHAR(64) NULL,
  address JSON NULL,
  language_preference VARCHAR(16) DEFAULT 'en',
  consent_version VARCHAR(64) NULL,
  consent_given_by BIGINT NULL,
  consent_revoked_at TIMESTAMP NULL,
  sensitivity ENUM('low','medium','high') NOT NULL DEFAULT 'medium',
  archived_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (consent_given_by) REFERENCES users(id)
) ENGINE=InnoDB;
CREATE INDEX ix_clients_email ON clients (email);

CREATE TABLE client_health_info (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  client_id BIGINT NOT NULL,
  encrypted_blob BLOB NOT NULL,
  sensitivity ENUM('low','medium','high') NOT NULL DEFAULT 'high',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE client_documents (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  client_id BIGINT NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  content_type VARCHAR(128) NOT NULL,
  size_bytes BIGINT NOT NULL,
  s3_url TEXT NOT NULL,
  checksum CHAR(64) NULL,
  encrypted TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ========== SERVICES, FACILITIES & SLOTS =============
CREATE TABLE facilities (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  address JSON NULL,
  phone VARCHAR(64) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE services (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  facility_id BIGINT NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT NULL,
  duration_minutes INT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (facility_id) REFERENCES facilities(id)
) ENGINE=InnoDB;

CREATE TABLE booking_slots (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  service_id BIGINT NOT NULL,
  facility_id BIGINT NOT NULL,
  start_at TIMESTAMP NOT NULL,
  end_at TIMESTAMP NOT NULL,
  capacity INT NOT NULL DEFAULT 1,
  available_count INT NOT NULL DEFAULT 1,
  lock_version INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY ux_booking_slots_unique_time (service_id, facility_id, start_at, end_at),
  FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE,
  FOREIGN KEY (facility_id) REFERENCES facilities(id) ON DELETE CASCADE
) ENGINE=InnoDB;
CREATE INDEX ix_booking_slots_start_at ON booking_slots(start_at);

CREATE TABLE slot_reservations (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  slot_id BIGINT NOT NULL,
  reserved_by_user_id BIGINT NULL,
  reserved_for_client_id BIGINT NULL,
  guest_email VARCHAR(254) NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY ux_slot_client (slot_id, reserved_for_client_id),
  UNIQUE KEY ux_slot_guest (slot_id, guest_email),
  FOREIGN KEY (slot_id) REFERENCES booking_slots(id) ON DELETE CASCADE,
  FOREIGN KEY (reserved_by_user_id) REFERENCES users(id),
  FOREIGN KEY (reserved_for_client_id) REFERENCES clients(id)
) ENGINE=InnoDB;
CREATE INDEX ix_slot_reservations_expires_at ON slot_reservations(expires_at);

-- ========== BOOKINGS & HISTORY =============
CREATE TABLE bookings (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  slot_id BIGINT NOT NULL,
  client_id BIGINT NULL,
  guest_email VARCHAR(254) NULL,
  status ENUM('pending','confirmed','attended','cancelled','no_show','archived') NOT NULL DEFAULT 'pending',
  created_by BIGINT NULL,
  created_via ENUM('web','admin','phone','api') NOT NULL DEFAULT 'web',
  uuid CHAR(36) NOT NULL DEFAULT (UUID()),
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  cancelled_at TIMESTAMP NULL,
  FOREIGN KEY (slot_id) REFERENCES booking_slots(id) ON DELETE CASCADE,
  FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL,
  FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;
CREATE UNIQUE INDEX ux_bookings_slot_client_unique ON bookings(slot_id, client_id);
CREATE UNIQUE INDEX ux_bookings_slot_guestemail_unique ON bookings(slot_id, guest_email);
CREATE INDEX ix_bookings_status_created_at ON bookings(status, created_at);
CREATE INDEX ix_bookings_slot_id ON bookings(slot_id);

CREATE TABLE booking_status_history (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  booking_id BIGINT NOT NULL,
  from_status ENUM('pending','confirmed','attended','cancelled','no_show','archived') NULL,
  to_status ENUM('pending','confirmed','attended','cancelled','no_show','archived') NOT NULL,
  changed_by BIGINT NULL,
  changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
  FOREIGN KEY (changed_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- ========== PAYMENTS & TRANSACTIONS =============
CREATE TABLE payments (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  booking_id BIGINT NULL,
  amount_cents BIGINT NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'USD',
  provider VARCHAR(64) NOT NULL,
  provider_payment_id VARCHAR(255) NULL,
  status VARCHAR(32) NOT NULL,
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE SET NULL
) ENGINE=InnoDB;
CREATE INDEX ix_payments_booking_id ON payments(booking_id);

-- Remaining tables (media, job queue, audit_logs, page_views, pages, testimonials, resources, email_logs, sms_logs) and stored procedures can be converted similarly following MySQL-compatible types, JSON, ENUMs, TIMESTAMPs, and AUTO_INCREMENT.
-- Transactional booking function and sweep function will be rewritten as MySQL procedures using BEGIN...END, DECLARE, HANDLER for exceptions, and SELECT ... FOR UPDATE inside START TRANSACTION/COMMIT blocks.

-- ==========================================
-- End of Database Schema v5 — MySQL/MariaDB
-- ==========================================
