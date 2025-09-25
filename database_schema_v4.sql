-- MariaDB 11.8 — Elderly Daycare Platform Database Schema
-- Engine: InnoDB, Charset: utf8mb4, Collation: utf8mb4_0900_ai_ci
-- IDs: BIGINT AUTO_INCREMENT (internal) + CHAR(36) UUID (external)
-- Soft deletes: deleted_at TIMESTAMP NULL
-- Temporal (system-versioned) tables: critical PII & bookings
-- JSON columns: flexible metadata and attributes

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- Authentication & Authorization Module
-- =========================================================

CREATE TABLE users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid CHAR(36) NOT NULL,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  password VARCHAR(255) NOT NULL,
  phone VARCHAR(32) NULL,
  avatar_url VARCHAR(512) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  last_login_at DATETIME NULL,
  preferences JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY users_uuid_unique (uuid),
  UNIQUE KEY users_email_unique (email),
  KEY users_active_idx (is_active),
  KEY users_deleted_at_idx (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE roles (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) NOT NULL,
  description VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY roles_slug_unique (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE permissions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) NOT NULL,
  description VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY permissions_slug_unique (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE role_user (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  role_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY role_user_unique (user_id, role_id),
  CONSTRAINT fk_role_user_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_role_user_role FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE permission_role (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  role_id BIGINT UNSIGNED NOT NULL,
  permission_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY permission_role_unique (role_id, permission_id),
  CONSTRAINT fk_permission_role_role FOREIGN KEY (role_id) REFERENCES roles(id),
  CONSTRAINT fk_permission_role_permission FOREIGN KEY (permission_id) REFERENCES permissions(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE password_resets (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  email VARCHAR(255) NOT NULL,
  token VARCHAR(255) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY password_resets_email_idx (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE personal_access_tokens (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tokenable_type VARCHAR(255) NOT NULL,
  tokenable_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(255) NOT NULL,
  token CHAR(64) NOT NULL,
  abilities JSON NULL,
  last_used_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY pat_token_unique (token),
  KEY pat_tokenable_idx (tokenable_type, tokenable_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE user_sessions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  session_id VARCHAR(128) NOT NULL,
  ip_address VARCHAR(64) NULL,
  user_agent VARCHAR(512) NULL,
  last_activity_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY user_sessions_session_unique (session_id),
  KEY user_sessions_user_idx (user_id),
  CONSTRAINT fk_user_sessions_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE login_attempts (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  email VARCHAR(255) NOT NULL,
  ip_address VARCHAR(64) NOT NULL,
  success TINYINT(1) NOT NULL,
  attempted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY login_attempts_email_idx (email),
  KEY login_attempts_ip_idx (ip_address)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Client Management Module
-- =========================================================

CREATE TABLE clients (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid CHAR(36) NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  date_of_birth DATE NULL,
  email VARCHAR(255) NULL,
  phone VARCHAR(32) NULL,
  address_line1 VARCHAR(255) NULL,
  address_line2 VARCHAR(255) NULL,
  city VARCHAR(100) NULL,
  state VARCHAR(100) NULL,
  postal_code VARCHAR(20) NULL,
  country VARCHAR(100) NULL,
  primary_language VARCHAR(50) NULL,
  consent_at DATETIME NULL,
  preferences JSON NULL,
  attributes JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  -- System versioning for PII changes over time
  row_start TIMESTAMP(6) GENERATED ALWAYS AS ROW START,
  row_end   TIMESTAMP(6) GENERATED ALWAYS AS ROW END,
  PERIOD FOR SYSTEM_TIME (row_start, row_end),
  PRIMARY KEY (id),
  UNIQUE KEY clients_uuid_unique (uuid),
  KEY clients_name_idx (last_name, first_name),
  KEY clients_deleted_at_idx (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 WITH SYSTEM VERSIONING;

CREATE TABLE client_contacts (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  client_id BIGINT UNSIGNED NOT NULL,
  contact_type ENUM('family','guardian','emergency','caregiver') NOT NULL,
  name VARCHAR(255) NOT NULL,
  relationship VARCHAR(100) NULL,
  email VARCHAR(255) NULL,
  phone VARCHAR(32) NULL,
  preferred_contact_method ENUM('phone','email','sms') NULL,
  is_primary TINYINT(1) NOT NULL DEFAULT 0,
  notes VARCHAR(512) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  KEY client_contacts_client_idx (client_id),
  CONSTRAINT fk_client_contacts_client FOREIGN KEY (client_id) REFERENCES clients(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE client_health_info (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  client_id BIGINT UNSIGNED NOT NULL,
  info_type ENUM('condition','allergy','mobility','diet','other') NOT NULL,
  label VARCHAR(255) NOT NULL,
  details JSON NULL,
  effective_from DATE NULL,
  effective_to DATE NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  KEY client_health_info_client_idx (client_id),
  KEY client_health_info_type_idx (info_type),
  CONSTRAINT fk_client_health_info_client FOREIGN KEY (client_id) REFERENCES clients(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE client_preferences (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  client_id BIGINT UNSIGNED NOT NULL,
  category VARCHAR(100) NOT NULL,
  preferences JSON NOT NULL,
  updated_by BIGINT UNSIGNED NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY client_preferences_unique (client_id, category),
  CONSTRAINT fk_client_preferences_client FOREIGN KEY (client_id) REFERENCES clients(id),
  CONSTRAINT fk_client_preferences_user FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE client_documents (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  client_id BIGINT UNSIGNED NOT NULL,
  uuid CHAR(36) NOT NULL,
  title VARCHAR(255) NOT NULL,
  file_url VARCHAR(1024) NOT NULL,
  mime_type VARCHAR(100) NOT NULL,
  size_bytes BIGINT UNSIGNED NOT NULL,
  attributes JSON NULL,
  uploaded_by BIGINT UNSIGNED NULL,
  uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY client_documents_uuid_unique (uuid),
  KEY client_documents_client_idx (client_id),
  CONSTRAINT fk_client_documents_client FOREIGN KEY (client_id) REFERENCES clients(id),
  CONSTRAINT fk_client_documents_user FOREIGN KEY (uploaded_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Facilities, Services & Program Module
-- =========================================================

CREATE TABLE facilities (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid CHAR(36) NOT NULL,
  name VARCHAR(255) NOT NULL,
  address_line1 VARCHAR(255) NULL,
  address_line2 VARCHAR(255) NULL,
  city VARCHAR(100) NULL,
  state VARCHAR(100) NULL,
  postal_code VARCHAR(20) NULL,
  country VARCHAR(100) NULL,
  phone VARCHAR(32) NULL,
  email VARCHAR(255) NULL,
  accessible TINYINT(1) NOT NULL DEFAULT 1,
  attributes JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY facilities_uuid_unique (uuid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE rooms (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  facility_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(100) NOT NULL,
  capacity INT UNSIGNED NOT NULL DEFAULT 20,
  accessible TINYINT(1) NOT NULL DEFAULT 1,
  attributes JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY rooms_unique (facility_id, name),
  CONSTRAINT fk_rooms_facility FOREIGN KEY (facility_id) REFERENCES facilities(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE service_categories (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) NOT NULL,
  description VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY service_categories_slug_unique (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE services (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid CHAR(36) NOT NULL,
  category_id BIGINT UNSIGNED NULL,
  title VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL,
  description TEXT NULL,
  duration_minutes INT UNSIGNED NOT NULL DEFAULT 60,
  required_staff_ratio DECIMAL(5,2) NOT NULL DEFAULT 0.10, -- staff per client
  active TINYINT(1) NOT NULL DEFAULT 1,
  attributes JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY services_uuid_unique (uuid),
  UNIQUE KEY services_slug_unique (slug),
  KEY services_category_idx (category_id),
  CONSTRAINT fk_services_category FOREIGN KEY (category_id) REFERENCES service_categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE service_requirements (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  service_id BIGINT UNSIGNED NOT NULL,
  requirement VARCHAR(255) NOT NULL,
  details JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY service_requirements_service_idx (service_id),
  CONSTRAINT fk_service_requirements_service FOREIGN KEY (service_id) REFERENCES services(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE activity_programs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  facility_id BIGINT UNSIGNED NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NULL,
  schedule JSON NULL, -- e.g., recurrence rules
  attributes JSON NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  KEY activity_programs_facility_idx (facility_id),
  CONSTRAINT fk_activity_programs_facility FOREIGN KEY (facility_id) REFERENCES facilities(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Staff Management Module
-- =========================================================

CREATE TABLE staff_members (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid CHAR(36) NOT NULL,
  user_id BIGINT UNSIGNED NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NULL,
  phone VARCHAR(32) NULL,
  role_title VARCHAR(100) NULL, -- e.g., Nurse, Therapist
  bio TEXT NULL,
  hired_at DATE NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  attributes JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY staff_members_uuid_unique (uuid),
  KEY staff_members_user_idx (user_id),
  CONSTRAINT fk_staff_members_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE staff_qualifications (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  staff_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(255) NOT NULL,
  issuer VARCHAR(255) NULL,
  issued_at DATE NULL,
  expires_at DATE NULL,
  attributes JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY staff_qualifications_staff_idx (staff_id),
  CONSTRAINT fk_staff_qualifications_staff FOREIGN KEY (staff_id) REFERENCES staff_members(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE staff_schedules (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  staff_id BIGINT UNSIGNED NOT NULL,
  facility_id BIGINT UNSIGNED NULL,
  room_id BIGINT UNSIGNED NULL,
  start_at DATETIME NOT NULL,
  end_at DATETIME NOT NULL,
  recurrence JSON NULL,
  attributes JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY staff_schedules_staff_idx (staff_id),
  KEY staff_schedules_time_idx (start_at, end_at),
  CONSTRAINT fk_staff_schedules_staff FOREIGN KEY (staff_id) REFERENCES staff_members(id),
  CONSTRAINT fk_staff_schedules_facility FOREIGN KEY (facility_id) REFERENCES facilities(id),
  CONSTRAINT fk_staff_schedules_room FOREIGN KEY (room_id) REFERENCES rooms(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE staff_services (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  staff_id BIGINT UNSIGNED NOT NULL,
  service_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY staff_services_unique (staff_id, service_id),
  CONSTRAINT fk_staff_services_staff FOREIGN KEY (staff_id) REFERENCES staff_members(id),
  CONSTRAINT fk_staff_services_service FOREIGN KEY (service_id) REFERENCES services(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE staff_availability (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  staff_id BIGINT UNSIGNED NOT NULL,
  available_date DATE NOT NULL,
  available JSON NULL, -- e.g., time segments
  notes VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY staff_availability_unique (staff_id, available_date),
  CONSTRAINT fk_staff_availability_staff FOREIGN KEY (staff_id) REFERENCES staff_members(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Booking & Scheduling Module
-- =========================================================

CREATE TABLE blackout_dates (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  facility_id BIGINT UNSIGNED NULL,
  room_id BIGINT UNSIGNED NULL,
  service_id BIGINT UNSIGNED NULL,
  start_at DATETIME NOT NULL,
  end_at DATETIME NOT NULL,
  reason VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY blackout_dates_scope_idx (facility_id, room_id, service_id),
  KEY blackout_dates_time_idx (start_at, end_at),
  CONSTRAINT fk_blackout_facility FOREIGN KEY (facility_id) REFERENCES facilities(id),
  CONSTRAINT fk_blackout_room FOREIGN KEY (room_id) REFERENCES rooms(id),
  CONSTRAINT fk_blackout_service FOREIGN KEY (service_id) REFERENCES services(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE booking_slots (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid CHAR(36) NOT NULL,
  facility_id BIGINT UNSIGNED NOT NULL,
  room_id BIGINT UNSIGNED NOT NULL,
  service_id BIGINT UNSIGNED NOT NULL,
  start_at DATETIME NOT NULL,
  end_at DATETIME NOT NULL,
  capacity INT UNSIGNED NOT NULL DEFAULT 10,
  available_count INT UNSIGNED NOT NULL DEFAULT 10,
  status ENUM('open','closed','cancelled') NOT NULL DEFAULT 'open',
  attributes JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY booking_slots_uuid_unique (uuid),
  UNIQUE KEY booking_slots_room_time_unique (room_id, start_at, end_at),
  KEY booking_slots_service_time_idx (service_id, start_at, end_at),
  CONSTRAINT fk_booking_slots_facility FOREIGN KEY (facility_id) REFERENCES facilities(id),
  CONSTRAINT fk_booking_slots_room FOREIGN KEY (room_id) REFERENCES rooms(id),
  CONSTRAINT fk_booking_slots_service FOREIGN KEY (service_id) REFERENCES services(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE bookings (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid CHAR(36) NOT NULL,
  slot_id BIGINT UNSIGNED NOT NULL,
  client_id BIGINT UNSIGNED NULL, -- optional for guest bookings
  guest_name VARCHAR(255) NULL,
  guest_email VARCHAR(255) NULL,
  guest_phone VARCHAR(32) NULL,
  emergency_contact JSON NULL,
  special_needs_notes TEXT NULL,
  consent_at DATETIME NULL,
  status ENUM('pending','confirmed','cancelled','attended','no_show') NOT NULL DEFAULT 'pending',
  notes VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  -- System versioning to track status changes and PII edits
  row_start TIMESTAMP(6) GENERATED ALWAYS AS ROW START,
  row_end   TIMESTAMP(6) GENERATED ALWAYS AS ROW END,
  PERIOD FOR SYSTEM_TIME (row_start, row_end),
  PRIMARY KEY (id),
  UNIQUE KEY bookings_uuid_unique (uuid),
  KEY bookings_slot_idx (slot_id),
  KEY bookings_client_idx (client_id),
  KEY bookings_status_idx (status),
  CONSTRAINT fk_bookings_slot FOREIGN KEY (slot_id) REFERENCES booking_slots(id),
  CONSTRAINT fk_bookings_client FOREIGN KEY (client_id) REFERENCES clients(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 WITH SYSTEM VERSIONING;

CREATE TABLE booking_services (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  booking_id BIGINT UNSIGNED NOT NULL,
  service_id BIGINT UNSIGNED NOT NULL,
  quantity INT UNSIGNED NOT NULL DEFAULT 1,
  attributes JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY booking_services_unique (booking_id, service_id),
  CONSTRAINT fk_booking_services_booking FOREIGN KEY (booking_id) REFERENCES bookings(id),
  CONSTRAINT fk_booking_services_service FOREIGN KEY (service_id) REFERENCES services(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE booking_status_history (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  booking_id BIGINT UNSIGNED NOT NULL,
  from_status ENUM('pending','confirmed','cancelled','attended','no_show') NOT NULL,
  to_status   ENUM('pending','confirmed','cancelled','attended','no_show') NOT NULL,
  changed_by BIGINT UNSIGNED NULL,
  changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  notes VARCHAR(255) NULL,
  PRIMARY KEY (id),
  KEY booking_status_history_booking_idx (booking_id),
  CONSTRAINT fk_booking_status_history_booking FOREIGN KEY (booking_id) REFERENCES bookings(id),
  CONSTRAINT fk_booking_status_history_user FOREIGN KEY (changed_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE waitlist_entries (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  slot_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NULL,
  phone VARCHAR(32) NULL,
  priority TINYINT UNSIGNED NOT NULL DEFAULT 5,
  notes VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY waitlist_slot_idx (slot_id),
  CONSTRAINT fk_waitlist_slot FOREIGN KEY (slot_id) REFERENCES booking_slots(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE recurring_bookings (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  client_id BIGINT UNSIGNED NOT NULL,
  service_id BIGINT UNSIGNED NOT NULL,
  facility_id BIGINT UNSIGNED NULL,
  room_id BIGINT UNSIGNED NULL,
  start_date DATE NOT NULL,
  end_date DATE NULL,
  recurrence_rule JSON NOT NULL, -- e.g., RRULE
  next_run_at DATETIME NULL,
  status ENUM('active','paused','ended') NOT NULL DEFAULT 'active',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY recurring_bookings_client_idx (client_id),
  CONSTRAINT fk_recurring_bookings_client FOREIGN KEY (client_id) REFERENCES clients(id),
  CONSTRAINT fk_recurring_bookings_service FOREIGN KEY (service_id) REFERENCES services(id),
  CONSTRAINT fk_recurring_bookings_facility FOREIGN KEY (facility_id) REFERENCES facilities(id),
  CONSTRAINT fk_recurring_bookings_room FOREIGN KEY (room_id) REFERENCES rooms(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Content Management Module
-- =========================================================

CREATE TABLE pages (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid CHAR(36) NOT NULL,
  title VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL,
  excerpt VARCHAR(512) NULL,
  content LONGTEXT NULL,
  state ENUM('draft','review','scheduled','published','archived') NOT NULL DEFAULT 'draft',
  scheduled_at DATETIME NULL,
  published_at DATETIME NULL,
  attributes JSON NULL,
  created_by BIGINT UNSIGNED NULL,
  updated_by BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY pages_uuid_unique (uuid),
  UNIQUE KEY pages_slug_unique (slug),
  KEY pages_state_idx (state),
  CONSTRAINT fk_pages_created_by FOREIGN KEY (created_by) REFERENCES users(id),
  CONSTRAINT fk_pages_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE page_sections (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  page_id BIGINT UNSIGNED NOT NULL,
  section_key VARCHAR(100) NOT NULL,
  title VARCHAR(255) NULL,
  content LONGTEXT NULL,
  position INT UNSIGNED NOT NULL DEFAULT 0,
  attributes JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY page_sections_unique (page_id, section_key),
  CONSTRAINT fk_page_sections_page FOREIGN KEY (page_id) REFERENCES pages(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE media_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid CHAR(36) NOT NULL,
  owner_type VARCHAR(255) NULL,
  owner_id BIGINT UNSIGNED NULL,
  title VARCHAR(255) NULL,
  file_url VARCHAR(1024) NOT NULL,
  mime_type VARCHAR(100) NOT NULL,
  size_bytes BIGINT UNSIGNED NOT NULL,
  conversions JSON NULL, -- thumbnails, responsive images
  captions_url VARCHAR(1024) NULL,
  attributes JSON NULL,
  uploaded_by BIGINT UNSIGNED NULL,
  uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY media_items_uuid_unique (uuid),
  KEY media_items_owner_idx (owner_type, owner_id),
  CONSTRAINT fk_media_items_user FOREIGN KEY (uploaded_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE media_associations (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  media_id BIGINT UNSIGNED NOT NULL,
  associable_type VARCHAR(255) NOT NULL,
  associable_id BIGINT UNSIGNED NOT NULL,
  role VARCHAR(50) NULL, -- e.g., 'gallery','cover','inline'
  position INT UNSIGNED NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY media_associations_unique (media_id, associable_type, associable_id, role),
  KEY media_associations_assoc_idx (associable_type, associable_id),
  CONSTRAINT fk_media_associations_media FOREIGN KEY (media_id) REFERENCES media_items(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE testimonials (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid CHAR(36) NOT NULL,
  author_name VARCHAR(255) NOT NULL,
  author_relation VARCHAR(100) NULL,
  content TEXT NOT NULL,
  rating TINYINT UNSIGNED NULL,
  state ENUM('draft','review','published','archived') NOT NULL DEFAULT 'draft',
  published_at DATETIME NULL,
  attributes JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY testimonials_uuid_unique (uuid),
  KEY testimonials_state_idx (state)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE faq_categories (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY faq_categories_slug_unique (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE faqs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  category_id BIGINT UNSIGNED NULL,
  question VARCHAR(255) NOT NULL,
  answer TEXT NOT NULL,
  state ENUM('draft','published','archived') NOT NULL DEFAULT 'published',
  position INT UNSIGNED NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  KEY faqs_category_idx (category_id),
  KEY faqs_state_idx (state),
  CONSTRAINT fk_faqs_category FOREIGN KEY (category_id) REFERENCES faq_categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE resources (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid CHAR(36) NOT NULL,
  title VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL,
  excerpt VARCHAR(512) NULL,
  content LONGTEXT NULL,
  url VARCHAR(1024) NULL,
  category VARCHAR(100) NULL,
  attributes JSON NULL,
  state ENUM('draft','published','archived') NOT NULL DEFAULT 'published',
  published_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY resources_uuid_unique (uuid),
  UNIQUE KEY resources_slug_unique (slug),
  KEY resources_state_idx (state)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Communication Module
-- =========================================================

CREATE TABLE inquiries (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid CHAR(36) NOT NULL,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NULL,
  phone VARCHAR(32) NULL,
  subject VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  source VARCHAR(100) NULL, -- e.g., 'contact_form','phone'
  status ENUM('new','in_progress','resolved','closed') NOT NULL DEFAULT 'new',
  attributes JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY inquiries_uuid_unique (uuid),
  KEY inquiries_status_idx (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE messages (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  thread_id BIGINT UNSIGNED NULL, -- future threading
  sender_type VARCHAR(255) NOT NULL,
  sender_id BIGINT UNSIGNED NOT NULL,
  recipient_type VARCHAR(255) NOT NULL,
  recipient_id BIGINT UNSIGNED NOT NULL,
  subject VARCHAR(255) NULL,
  body TEXT NOT NULL,
  channel ENUM('email','sms','internal') NOT NULL,
  status ENUM('queued','sent','delivered','failed') NOT NULL DEFAULT 'queued',
  metadata JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY messages_sender_idx (sender_type, sender_id),
  KEY messages_recipient_idx (recipient_type, recipient_id),
  KEY messages_status_idx (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE notifications (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  notifiable_type VARCHAR(255) NOT NULL,
  notifiable_id BIGINT UNSIGNED NOT NULL,
  type VARCHAR(255) NOT NULL,
  data JSON NOT NULL,
  read_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY notifications_notifiable_idx (notifiable_type, notifiable_id),
  KEY notifications_read_idx (read_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE email_logs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  message_id BIGINT UNSIGNED NULL,
  to_email VARCHAR(255) NOT NULL,
  subject VARCHAR(255) NOT NULL,
  status ENUM('queued','sent','bounced','failed') NOT NULL,
  provider_message_id VARCHAR(255) NULL,
  error TEXT NULL,
  sent_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY email_logs_message_idx (message_id),
  KEY email_logs_status_idx (status),
  CONSTRAINT fk_email_logs_message FOREIGN KEY (message_id) REFERENCES messages(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE sms_logs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  message_id BIGINT UNSIGNED NULL,
  to_phone VARCHAR(32) NOT NULL,
  body TEXT NOT NULL,
  status ENUM('queued','sent','delivered','failed') NOT NULL,
  provider_message_id VARCHAR(255) NULL,
  error TEXT NULL,
  sent_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY sms_logs_message_idx (message_id),
  KEY sms_logs_status_idx (status),
  CONSTRAINT fk_sms_logs_message FOREIGN KEY (message_id) REFERENCES messages(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Analytics & Reporting Module
-- =========================================================

CREATE TABLE analytics_events (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid CHAR(36) NOT NULL,
  user_id BIGINT UNSIGNED NULL,
  session_id VARCHAR(128) NULL,
  event_type VARCHAR(100) NOT NULL,
  event_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  route VARCHAR(255) NULL,
  referrer VARCHAR(1024) NULL,
  payload JSON NULL,
  PRIMARY KEY (id),
  UNIQUE KEY analytics_events_uuid_unique (uuid),
  KEY analytics_events_type_time_idx (event_type, event_time),
  CONSTRAINT fk_analytics_events_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE page_views (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  path VARCHAR(255) NOT NULL,
  view_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  session_id VARCHAR(128) NULL,
  user_id BIGINT UNSIGNED NULL,
  client_ip VARCHAR(64) NULL,
  user_agent VARCHAR(512) NULL,
  attributes JSON NULL,
  PRIMARY KEY (id),
  KEY page_views_path_time_idx (path, view_time),
  CONSTRAINT fk_page_views_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE booking_analytics (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  booking_id BIGINT UNSIGNED NOT NULL,
  step VARCHAR(50) NOT NULL, -- e.g., 'step1_view','step2_submit'
  occurred_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  attributes JSON NULL,
  PRIMARY KEY (id),
  KEY booking_analytics_booking_idx (booking_id),
  KEY booking_analytics_step_time_idx (step, occurred_at),
  CONSTRAINT fk_booking_analytics_booking FOREIGN KEY (booking_id) REFERENCES bookings(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE service_metrics (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  service_id BIGINT UNSIGNED NOT NULL,
  metric_date DATE NOT NULL,
  bookings_count INT UNSIGNED NOT NULL DEFAULT 0,
  attendance_count INT UNSIGNED NOT NULL DEFAULT 0,
  satisfaction_avg DECIMAL(4,2) NULL,
  attributes JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY service_metrics_unique (service_id, metric_date),
  CONSTRAINT fk_service_metrics_service FOREIGN KEY (service_id) REFERENCES services(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- System & Audit Module
-- =========================================================

CREATE TABLE audit_logs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  actor_type VARCHAR(255) NULL,
  actor_id BIGINT UNSIGNED NULL,
  entity_type VARCHAR(255) NOT NULL,
  entity_id BIGINT UNSIGNED NOT NULL,
  action VARCHAR(100) NOT NULL, -- e.g., 'create','update','delete','publish'
  before JSON NULL,
  after JSON NULL,
  occurred_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  request_id VARCHAR(64) NULL,
  ip_address VARCHAR(64) NULL,
  PRIMARY KEY (id),
  KEY audit_logs_entity_idx (entity_type, entity_id),
  KEY audit_logs_actor_idx (actor_type, actor_id),
  KEY audit_logs_action_time_idx (action, occurred_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE system_settings (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  key_name VARCHAR(100) NOT NULL,
  value JSON NULL,
  updated_by BIGINT UNSIGNED NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY system_settings_key_unique (key_name),
  CONSTRAINT fk_system_settings_user FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE cache_entries (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cache_key VARCHAR(255) NOT NULL,
  value LONGTEXT NOT NULL,
  expires_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY cache_entries_key_unique (cache_key),
  KEY cache_entries_expires_idx (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE job_queue (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid CHAR(36) NOT NULL,
  queue VARCHAR(100) NOT NULL,
  job_type VARCHAR(255) NOT NULL,
  payload JSON NOT NULL,
  attempts INT UNSIGNED NOT NULL DEFAULT 0,
  available_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reserved_at DATETIME NULL,
  completed_at DATETIME NULL,
  failed_at DATETIME NULL,
  error TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY job_queue_uuid_unique (uuid),
  KEY job_queue_queue_time_idx (queue, available_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE failed_jobs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid CHAR(36) NOT NULL,
  job_type VARCHAR(255) NOT NULL,
  payload JSON NOT NULL,
  exception TEXT NOT NULL,
  failed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY failed_jobs_uuid_unique (uuid),
  KEY failed_jobs_type_time_idx (job_type, failed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Indices & Constraints Enhancements
-- =========================================================

-- Booking capacity safeguard: ensure available_count never exceeds capacity
-- (Application-level guard; optional generated column + check if needed)
-- MariaDB CHECK constraints are parsed but not enforced before 10.2; prefer triggers/app logic.

-- Referential integrity and cascading rules can be added selectively:
-- Example: cascade delete booking_services when booking deleted (soft delete preferred)
-- ALTER TABLE booking_services
--   ADD CONSTRAINT fk_booking_services_booking
--   FOREIGN KEY (booking_id) REFERENCES bookings(id)
--   ON DELETE CASCADE;

SET FOREIGN_KEY_CHECKS = 1;
