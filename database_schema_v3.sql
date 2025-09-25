-- ============================================================================
-- ELDERLY DAYCARE CENTER DATABASE SCHEMA v3
-- MariaDB 11.8 Optimized
-- Version: 1.0.0
-- ============================================================================

-- Set proper defaults for MariaDB 11.8
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET collation_connection = utf8mb4_unicode_ci;
SET sql_mode = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';
SET default_storage_engine = InnoDB;
SET innodb_file_per_table = 1;
SET innodb_strict_mode = 1;

-- Create database
CREATE DATABASE IF NOT EXISTS elderly_daycare_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE elderly_daycare_db;

-- ============================================================================
-- SECTION 1: AUTHENTICATION & AUTHORIZATION
-- ============================================================================

-- Users table (for authentication - staff, admins, family members)
CREATE TABLE users (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL,
    email_verified_at TIMESTAMP NULL DEFAULT NULL,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NULL,
    phone_verified_at TIMESTAMP NULL DEFAULT NULL,
    user_type ENUM('admin', 'staff', 'family', 'client') NOT NULL DEFAULT 'family',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMP NULL DEFAULT NULL,
    last_login_ip VARCHAR(45) NULL,
    failed_login_attempts TINYINT UNSIGNED DEFAULT 0,
    locked_until TIMESTAMP NULL DEFAULT NULL,
    two_factor_secret TEXT NULL,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    remember_token VARCHAR(100) NULL,
    profile_photo_path VARCHAR(500) NULL,
    preferences JSON NULL COMMENT 'User preferences like font size, contrast mode',
    metadata JSON NULL COMMENT 'Additional flexible data',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    
    PRIMARY KEY (id),
    UNIQUE KEY idx_email (email),
    KEY idx_user_type (user_type),
    KEY idx_active_type (is_active, user_type),
    KEY idx_phone (phone),
    KEY idx_deleted (deleted_at),
    FULLTEXT KEY ft_name (first_name, last_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Roles table
CREATE TABLE roles (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    description TEXT NULL,
    is_system BOOLEAN DEFAULT FALSE COMMENT 'System roles cannot be deleted',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    UNIQUE KEY idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Permissions table
CREATE TABLE permissions (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    description TEXT NULL,
    module VARCHAR(50) NOT NULL COMMENT 'Module this permission belongs to',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    UNIQUE KEY idx_name (name),
    KEY idx_module (module)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User roles pivot table
CREATE TABLE user_roles (
    user_id BIGINT UNSIGNED NOT NULL,
    role_id INT UNSIGNED NOT NULL,
    assigned_by BIGINT UNSIGNED NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL DEFAULT NULL,
    
    PRIMARY KEY (user_id, role_id),
    KEY idx_role_id (role_id),
    KEY idx_expires (expires_at),
    
    CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) 
        REFERENCES roles(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_roles_assigned_by FOREIGN KEY (assigned_by) 
        REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Role permissions pivot table
CREATE TABLE role_permissions (
    role_id INT UNSIGNED NOT NULL,
    permission_id INT UNSIGNED NOT NULL,
    
    PRIMARY KEY (role_id, permission_id),
    KEY idx_permission_id (permission_id),
    
    CONSTRAINT fk_role_permissions_role FOREIGN KEY (role_id) 
        REFERENCES roles(id) ON DELETE CASCADE,
    CONSTRAINT fk_role_permissions_permission FOREIGN KEY (permission_id) 
        REFERENCES permissions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Password reset tokens
CREATE TABLE password_reset_tokens (
    email VARCHAR(255) NOT NULL,
    token VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (email),
    KEY idx_token (token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sessions table (for database session driver)
CREATE TABLE sessions (
    id VARCHAR(255) NOT NULL,
    user_id BIGINT UNSIGNED NULL,
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    payload LONGTEXT NOT NULL,
    last_activity INT NOT NULL,
    
    PRIMARY KEY (id),
    KEY idx_user_id (user_id),
    KEY idx_last_activity (last_activity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 2: CLIENT MANAGEMENT (ELDERLY PARTICIPANTS)
-- ============================================================================

-- Clients table (elderly participants)
CREATE TABLE clients (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    client_number VARCHAR(20) NOT NULL COMMENT 'Unique client identifier',
    user_id BIGINT UNSIGNED NULL COMMENT 'Optional link to user account',
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100) NULL,
    last_name VARCHAR(100) NOT NULL,
    preferred_name VARCHAR(100) NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('male', 'female', 'other', 'prefer_not_to_say') NULL,
    
    -- Contact Information
    phone VARCHAR(20) NULL,
    email VARCHAR(255) NULL,
    address_line1 VARCHAR(255) NULL,
    address_line2 VARCHAR(255) NULL,
    city VARCHAR(100) NULL,
    state_province VARCHAR(100) NULL,
    postal_code VARCHAR(20) NULL,
    country VARCHAR(2) DEFAULT 'US',
    
    -- Medical Summary
    blood_type VARCHAR(10) NULL,
    primary_physician VARCHAR(255) NULL,
    physician_phone VARCHAR(20) NULL,
    insurance_provider VARCHAR(255) NULL,
    insurance_number VARCHAR(100) NULL,
    
    -- Mobility & Cognitive Status
    mobility_status ENUM('independent', 'walker', 'wheelchair', 'assisted') DEFAULT 'independent',
    cognitive_status ENUM('normal', 'mild_impairment', 'moderate_impairment', 'severe_impairment') DEFAULT 'normal',
    communication_notes TEXT NULL,
    
    -- Administrative
    enrollment_date DATE NOT NULL,
    discharge_date DATE NULL,
    status ENUM('active', 'inactive', 'discharged', 'deceased', 'waitlist') DEFAULT 'active',
    status_reason TEXT NULL,
    intake_notes TEXT NULL,
    
    -- Preferences
    language_preference VARCHAR(10) DEFAULT 'en',
    dietary_preferences JSON NULL,
    activity_preferences JSON NULL,
    
    -- Photo & Documents
    profile_photo_path VARCHAR(500) NULL,
    photo_consent BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    tags JSON NULL COMMENT 'Flexible tagging system',
    custom_fields JSON NULL COMMENT 'Facility-specific custom fields',
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    
    PRIMARY KEY (id),
    UNIQUE KEY idx_client_number (client_number),
    KEY idx_user_id (user_id),
    KEY idx_status (status),
    KEY idx_enrollment_date (enrollment_date),
    KEY idx_dob (date_of_birth),
    KEY idx_deleted (deleted_at),
    FULLTEXT KEY ft_client_name (first_name, middle_name, last_name, preferred_name),
    
    CONSTRAINT fk_clients_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_discharge_date CHECK (discharge_date IS NULL OR discharge_date >= enrollment_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Client medical information (sensitive medical data)
CREATE TABLE client_medical_info (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    client_id BIGINT UNSIGNED NOT NULL,
    
    -- Medical Conditions
    medical_conditions JSON NULL COMMENT 'Array of conditions with dates',
    allergies JSON NULL COMMENT 'Array of allergies with severity',
    
    -- Vital Signs Baseline
    blood_pressure_systolic INT NULL,
    blood_pressure_diastolic INT NULL,
    resting_heart_rate INT NULL,
    weight_kg DECIMAL(5,2) NULL,
    height_cm DECIMAL(5,2) NULL,
    
    -- Special Care Requirements
    requires_assistance_with JSON NULL COMMENT 'ADL assistance needs',
    fall_risk_level ENUM('low', 'medium', 'high') DEFAULT 'low',
    wandering_risk BOOLEAN DEFAULT FALSE,
    behavioral_triggers TEXT NULL,
    calming_techniques TEXT NULL,
    
    -- Medical Equipment
    uses_oxygen BOOLEAN DEFAULT FALSE,
    uses_cpap BOOLEAN DEFAULT FALSE,
    uses_hearing_aid BOOLEAN DEFAULT FALSE,
    uses_glasses BOOLEAN DEFAULT FALSE,
    other_equipment JSON NULL,
    
    -- DNR/Advanced Directives
    has_dnr BOOLEAN DEFAULT FALSE,
    has_advanced_directive BOOLEAN DEFAULT FALSE,
    healthcare_proxy_name VARCHAR(255) NULL,
    healthcare_proxy_phone VARCHAR(20) NULL,
    
    last_updated_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    UNIQUE KEY idx_client_id (client_id),
    
    CONSTRAINT fk_medical_info_client FOREIGN KEY (client_id) 
        REFERENCES clients(id) ON DELETE CASCADE,
    CONSTRAINT fk_medical_info_updated_by FOREIGN KEY (last_updated_by) 
        REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    COMMENT='Sensitive medical information - requires special access';

-- Client emergency contacts
CREATE TABLE client_emergency_contacts (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    client_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(255) NOT NULL,
    relationship VARCHAR(100) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    phone_primary VARCHAR(20) NOT NULL,
    phone_secondary VARCHAR(20) NULL,
    email VARCHAR(255) NULL,
    address TEXT NULL,
    has_medical_authority BOOLEAN DEFAULT FALSE,
    has_financial_authority BOOLEAN DEFAULT FALSE,
    notes TEXT NULL,
    priority_order TINYINT DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    KEY idx_client_id (client_id),
    KEY idx_primary (client_id, is_primary),
    
    CONSTRAINT fk_emergency_contacts_client FOREIGN KEY (client_id) 
        REFERENCES clients(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Client medications
CREATE TABLE client_medications (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    client_id BIGINT UNSIGNED NOT NULL,
    medication_name VARCHAR(255) NOT NULL,
    generic_name VARCHAR(255) NULL,
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    route ENUM('oral', 'injection', 'topical', 'inhalation', 'other') DEFAULT 'oral',
    prescribing_doctor VARCHAR(255) NULL,
    purpose TEXT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    time_of_day JSON NULL COMMENT 'Array of times: ["08:00", "12:00", "18:00"]',
    special_instructions TEXT NULL,
    side_effects_to_watch TEXT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_self_administered BOOLEAN DEFAULT FALSE,
    requires_monitoring BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    KEY idx_client_active (client_id, is_active),
    KEY idx_requires_monitoring (requires_monitoring, is_active),
    
    CONSTRAINT fk_medications_client FOREIGN KEY (client_id) 
        REFERENCES clients(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Client care plans
CREATE TABLE client_care_plans (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    client_id BIGINT UNSIGNED NOT NULL,
    plan_type ENUM('general', 'medical', 'behavioral', 'dietary', 'activity') NOT NULL,
    title VARCHAR(255) NOT NULL,
    goals JSON NULL COMMENT 'Array of care goals',
    interventions JSON NULL COMMENT 'Array of interventions',
    evaluation_criteria TEXT NULL,
    start_date DATE NOT NULL,
    review_date DATE NOT NULL,
    end_date DATE NULL,
    status ENUM('draft', 'active', 'completed', 'discontinued') DEFAULT 'draft',
    created_by BIGINT UNSIGNED NOT NULL,
    approved_by BIGINT UNSIGNED NULL,
    approved_at TIMESTAMP NULL,
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    KEY idx_client_status (client_id, status),
    KEY idx_review_date (review_date),
    
    CONSTRAINT fk_care_plans_client FOREIGN KEY (client_id) 
        REFERENCES clients(id) ON DELETE CASCADE,
    CONSTRAINT fk_care_plans_created_by FOREIGN KEY (created_by) 
        REFERENCES users(id),
    CONSTRAINT fk_care_plans_approved_by FOREIGN KEY (approved_by) 
        REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Family members / authorized contacts
CREATE TABLE client_family_members (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    client_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NULL COMMENT 'Link to user account if they have portal access',
    name VARCHAR(255) NOT NULL,
    relationship VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NULL,
    email VARCHAR(255) NULL,
    is_primary_contact BOOLEAN DEFAULT FALSE,
    can_receive_updates BOOLEAN DEFAULT TRUE,
    can_make_decisions BOOLEAN DEFAULT FALSE,
    portal_access_granted BOOLEAN DEFAULT FALSE,
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    KEY idx_client_id (client_id),
    KEY idx_user_id (user_id),
    KEY idx_primary (client_id, is_primary_contact),
    
    CONSTRAINT fk_family_members_client FOREIGN KEY (client_id) 
        REFERENCES clients(id) ON DELETE CASCADE,
    CONSTRAINT fk_family_members_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 3: SERVICE MANAGEMENT
-- ============================================================================

-- Service categories
CREATE TABLE service_categories (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    description TEXT NULL,
    icon VARCHAR(100) NULL,
    color VARCHAR(7) NULL COMMENT 'Hex color code',
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    UNIQUE KEY idx_slug (slug),
    KEY idx_active_order (is_active, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Services table
CREATE TABLE services (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    category_id INT UNSIGNED NULL,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL,
    description TEXT NULL,
    short_description VARCHAR(500) NULL,
    
    -- Service Details
    duration_minutes INT NULL COMMENT 'Typical duration',
    min_participants INT DEFAULT 1,
    max_participants INT NULL,
    
    -- Scheduling
    schedule_type ENUM('daily', 'weekly', 'monthly', 'on_demand') DEFAULT 'daily',
    available_days JSON NULL COMMENT 'Array of days: [1,2,3,4,5]',
    available_times JSON NULL COMMENT 'Array of time slots',
    
    -- Pricing
    price_type ENUM('free', 'fixed', 'per_hour', 'package') DEFAULT 'fixed',
    price DECIMAL(10,2) NULL,
    price_unit VARCHAR(50) NULL,
    
    -- Requirements
    age_requirement_min INT NULL,
    age_requirement_max INT NULL,
    mobility_requirements JSON NULL,
    cognitive_requirements JSON NULL,
    other_requirements TEXT NULL,
    contraindications TEXT NULL,
    
    -- Features & Benefits
    features JSON NULL COMMENT 'Array of feature strings',
    benefits JSON NULL COMMENT 'Array of benefit strings',
    equipment_provided JSON NULL,
    what_to_bring JSON NULL,
    
    -- Media
    image_path VARCHAR(500) NULL,
    thumbnail_path VARCHAR(500) NULL,
    icon VARCHAR(100) NULL,
    gallery_images JSON NULL,
    video_url VARCHAR(500) NULL,
    
    -- SEO & Display
    meta_title VARCHAR(255) NULL,
    meta_description TEXT NULL,
    keywords JSON NULL,
    
    -- Administrative
    is_featured BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    requires_enrollment BOOLEAN DEFAULT FALSE,
    requires_assessment BOOLEAN DEFAULT FALSE,
    sort_order INT DEFAULT 0,
    
    -- Statistics
    total_sessions_held INT DEFAULT 0,
    total_participants INT DEFAULT 0,
    average_rating DECIMAL(3,2) NULL,
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    
    PRIMARY KEY (id),
    UNIQUE KEY idx_slug (slug),
    KEY idx_category (category_id),
    KEY idx_active_featured (is_active, is_featured),
    KEY idx_schedule_type (schedule_type),
    KEY idx_deleted (deleted_at),
    FULLTEXT KEY ft_search (name, description, short_description),
    
    CONSTRAINT fk_services_category FOREIGN KEY (category_id) 
        REFERENCES service_categories(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Service schedules (recurring schedule templates)
CREATE TABLE service_schedules (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    service_id BIGINT UNSIGNED NOT NULL,
    day_of_week TINYINT NOT NULL COMMENT '1=Monday, 7=Sunday',
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    capacity INT NULL,
    location VARCHAR(255) NULL,
    instructor_id BIGINT UNSIGNED NULL,
    is_active BOOLEAN DEFAULT TRUE,
    effective_from DATE NOT NULL,
    effective_until DATE NULL,
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    KEY idx_service_day (service_id, day_of_week),
    KEY idx_active_dates (is_active, effective_from, effective_until),
    KEY idx_instructor (instructor_id),
    
    CONSTRAINT fk_schedules_service FOREIGN KEY (service_id) 
        REFERENCES services(id) ON DELETE CASCADE,
    CONSTRAINT fk_schedules_instructor FOREIGN KEY (instructor_id) 
        REFERENCES staff_members(id) ON DELETE SET NULL,
    CONSTRAINT chk_schedule_times CHECK (end_time > start_time),
    CONSTRAINT chk_day_of_week CHECK (day_of_week BETWEEN 1 AND 7)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 4: STAFF MANAGEMENT
-- ============================================================================

-- Staff members table
CREATE TABLE staff_members (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NULL,
    employee_id VARCHAR(50) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    department VARCHAR(100) NULL,
    
    -- Professional Information
    bio TEXT NULL,
    qualifications JSON NULL COMMENT 'Array of qualifications',
    certifications JSON NULL COMMENT 'Array of certifications with expiry dates',
    specializations JSON NULL COMMENT 'Array of specialization areas',
    years_experience INT NULL,
    languages_spoken JSON NULL,
    
    -- Contact
    work_phone VARCHAR(20) NULL,
    work_email VARCHAR(255) NULL,
    emergency_contact_name VARCHAR(255) NULL,
    emergency_contact_phone VARCHAR(20) NULL,
    
    -- Employment
    hire_date DATE NOT NULL,
    employment_type ENUM('full_time', 'part_time', 'contract', 'volunteer') DEFAULT 'full_time',
    work_schedule JSON NULL COMMENT 'Typical work schedule',
    hourly_rate DECIMAL(10,2) NULL,
    
    -- Media
    photo_path VARCHAR(500) NULL,
    introduction_video_url VARCHAR(500) NULL,
    
    -- Administrative
    is_active BOOLEAN DEFAULT TRUE,
    can_be_instructor BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    display_order INT DEFAULT 0,
    termination_date DATE NULL,
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    
    PRIMARY KEY (id),
    UNIQUE KEY idx_employee_id (employee_id),
    UNIQUE KEY idx_user_id (user_id),
    KEY idx_active (is_active),
    KEY idx_department (department),
    KEY idx_deleted (deleted_at),
    FULLTEXT KEY ft_staff_name (first_name, last_name),
    
    CONSTRAINT fk_staff_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Staff services (which services can each staff member provide)
CREATE TABLE staff_services (
    staff_id BIGINT UNSIGNED NOT NULL,
    service_id BIGINT UNSIGNED NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    is_backup BOOLEAN DEFAULT FALSE,
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (staff_id, service_id),
    KEY idx_service_id (service_id),
    
    CONSTRAINT fk_staff_services_staff FOREIGN KEY (staff_id) 
        REFERENCES staff_members(id) ON DELETE CASCADE,
    CONSTRAINT fk_staff_services_service FOREIGN KEY (service_id) 
        REFERENCES services(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Staff schedules (availability)
CREATE TABLE staff_schedules (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    staff_id BIGINT UNSIGNED NOT NULL,
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    break_start TIME NULL,
    break_end TIME NULL,
    schedule_type ENUM('regular', 'overtime', 'on_call', 'training') DEFAULT 'regular',
    status ENUM('scheduled', 'confirmed', 'completed', 'absent', 'cancelled') DEFAULT 'scheduled',
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    UNIQUE KEY idx_staff_date_time (staff_id, date, start_time),
    KEY idx_date (date),
    KEY idx_status (status),
    
    CONSTRAINT fk_staff_schedules_staff FOREIGN KEY (staff_id) 
        REFERENCES staff_members(id) ON DELETE CASCADE,
    CONSTRAINT chk_staff_schedule_times CHECK (end_time > start_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 5: BOOKING & ENROLLMENT MANAGEMENT
-- ============================================================================

-- Booking slots (available time slots for services)
CREATE TABLE booking_slots (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    service_id BIGINT UNSIGNED NOT NULL,
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    capacity INT NOT NULL,
    booked_count INT DEFAULT 0,
    waitlist_count INT DEFAULT 0,
    location VARCHAR(255) NULL,
    instructor_id BIGINT UNSIGNED NULL,
    status ENUM('available', 'full', 'cancelled', 'completed') DEFAULT 'available',
    cancellation_reason TEXT NULL,
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    UNIQUE KEY idx_service_datetime (service_id, date, start_time),
    KEY idx_date_status (date, status),
    KEY idx_availability (status, date, booked_count, capacity),
    KEY idx_instructor (instructor_id),
    
    CONSTRAINT fk_slots_service FOREIGN KEY (service_id) 
        REFERENCES services(id) ON DELETE CASCADE,
    CONSTRAINT fk_slots_instructor FOREIGN KEY (instructor_id) 
        REFERENCES staff_members(id) ON DELETE SET NULL,
    CONSTRAINT chk_slot_times CHECK (end_time > start_time),
    CONSTRAINT chk_capacity CHECK (capacity > 0),
    CONSTRAINT chk_booked_count CHECK (booked_count >= 0 AND booked_count <= capacity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bookings table
CREATE TABLE bookings (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    booking_number VARCHAR(20) NOT NULL,
    slot_id BIGINT UNSIGNED NOT NULL,
    client_id BIGINT UNSIGNED NULL COMMENT 'Null for guest bookings',
    user_id BIGINT UNSIGNED NULL COMMENT 'User who made the booking',
    
    -- Guest Information (if not a registered client)
    guest_name VARCHAR(255) NULL,
    guest_email VARCHAR(255) NULL,
    guest_phone VARCHAR(20) NULL,
    
    -- Booking Details
    booking_type ENUM('trial', 'single', 'recurring', 'package') DEFAULT 'single',
    status ENUM('pending', 'confirmed', 'waitlisted', 'cancelled', 'completed', 'no_show') DEFAULT 'pending',
    confirmation_code VARCHAR(50) NULL,
    confirmed_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,
    cancellation_reason TEXT NULL,
    
    -- Requirements & Preferences
    special_requirements TEXT NULL,
    dietary_restrictions TEXT NULL,
    mobility_aids_needed JSON NULL,
    
    -- Payment (if applicable)
    payment_status ENUM('not_required', 'pending', 'paid', 'refunded') DEFAULT 'not_required',
    payment_amount DECIMAL(10,2) NULL,
    payment_method VARCHAR(50) NULL,
    payment_reference VARCHAR(100) NULL,
    paid_at TIMESTAMP NULL,
    
    -- Administrative
    notes TEXT NULL,
    internal_notes TEXT NULL COMMENT 'Staff-only notes',
    source VARCHAR(50) NULL COMMENT 'How they found us',
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    UNIQUE KEY idx_booking_number (booking_number),
    KEY idx_slot_id (slot_id),
    KEY idx_client_id (client_id),
    KEY idx_user_id (user_id),
    KEY idx_status_date (status, created_at),
    KEY idx_confirmation_code (confirmation_code),
    
    CONSTRAINT fk_bookings_slot FOREIGN KEY (slot_id) 
        REFERENCES booking_slots(id),
    CONSTRAINT fk_bookings_client FOREIGN KEY (client_id) 
        REFERENCES clients(id) ON DELETE SET NULL,
    CONSTRAINT fk_bookings_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Recurring booking templates
CREATE TABLE recurring_bookings (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    client_id BIGINT UNSIGNED NOT NULL,
    service_id BIGINT UNSIGNED NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    recurrence_pattern ENUM('daily', 'weekly', 'biweekly', 'monthly') NOT NULL,
    recurrence_days JSON NULL COMMENT 'Days of week for weekly pattern',
    preferred_time TIME NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_by BIGINT UNSIGNED NOT NULL,
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    KEY idx_client_active (client_id, is_active),
    KEY idx_service (service_id),
    KEY idx_dates (start_date, end_date),
    
    CONSTRAINT fk_recurring_client FOREIGN KEY (client_id) 
        REFERENCES clients(id) ON DELETE CASCADE,
    CONSTRAINT fk_recurring_service FOREIGN KEY (service_id) 
        REFERENCES services(id) ON DELETE CASCADE,
    CONSTRAINT fk_recurring_created_by FOREIGN KEY (created_by) 
        REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Waitlist entries
CREATE TABLE waitlist_entries (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    slot_id BIGINT UNSIGNED NOT NULL,
    client_id BIGINT UNSIGNED NULL,
    user_id BIGINT UNSIGNED NULL,
    guest_name VARCHAR(255) NULL,
    guest_email VARCHAR(255) NULL,
    guest_phone VARCHAR(20) NULL,
    priority INT DEFAULT 0,
    status ENUM('waiting', 'offered', 'accepted', 'declined', 'expired') DEFAULT 'waiting',
    offered_at TIMESTAMP NULL,
    offer_expires_at TIMESTAMP NULL,
    responded_at TIMESTAMP NULL,
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    KEY idx_slot_status (slot_id, status),
    KEY idx_priority (slot_id, priority, created_at),
    KEY idx_client (client_id),
    
    CONSTRAINT fk_waitlist_slot FOREIGN KEY (slot_id) 
        REFERENCES booking_slots(id) ON DELETE CASCADE,
    CONSTRAINT fk_waitlist_client FOREIGN KEY (client_id) 
        REFERENCES clients(id) ON DELETE CASCADE,
    CONSTRAINT fk_waitlist_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Attendance records
CREATE TABLE attendance_records (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    booking_id BIGINT UNSIGNED NOT NULL,
    client_id BIGINT UNSIGNED NOT NULL,
    slot_id BIGINT UNSIGNED NOT NULL,
    check_in_time TIMESTAMP NULL,
    check_out_time TIMESTAMP NULL,
    checked_in_by BIGINT UNSIGNED NULL,
    checked_out_by BIGINT UNSIGNED NULL,
    attendance_status ENUM('present', 'absent', 'late', 'left_early', 'partial') DEFAULT 'present',
    participation_level ENUM('full', 'partial', 'minimal', 'none') NULL,
    mood_on_arrival VARCHAR(50) NULL,
    mood_on_departure VARCHAR(50) NULL,
    activities_participated JSON NULL,
    meals_consumed JSON NULL,
    incidents TEXT NULL,
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    UNIQUE KEY idx_booking_id (booking_id),
    KEY idx_client_date (client_id, created_at),
    KEY idx_slot_id (slot_id),
    KEY idx_status (attendance_status),
    
    CONSTRAINT fk_attendance_booking FOREIGN KEY (booking_id) 
        REFERENCES bookings(id) ON DELETE CASCADE,
    CONSTRAINT fk_attendance_client FOREIGN KEY (client_id) 
        REFERENCES clients(id) ON DELETE CASCADE,
    CONSTRAINT fk_attendance_slot FOREIGN KEY (slot_id) 
        REFERENCES booking_slots(id),
    CONSTRAINT fk_attendance_checked_in_by FOREIGN KEY (checked_in_by) 
        REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_attendance_checked_out_by FOREIGN KEY (checked_out_by) 
        REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 6: CONTENT MANAGEMENT
-- ============================================================================

-- Media categories
CREATE TABLE media_categories (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    description TEXT NULL,
    parent_id INT UNSIGNED NULL,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    UNIQUE KEY idx_slug (slug),
    KEY idx_parent (parent_id),
    KEY idx_active_order (is_active, sort_order),
    
    CONSTRAINT fk_media_categories_parent FOREIGN KEY (parent_id) 
        REFERENCES media_categories(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Media items (photos, videos)
CREATE TABLE media_items (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    category_id INT UNSIGNED NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NULL,
    type ENUM('image', 'video', 'document', 'audio') NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    
    -- File Information
    file_path VARCHAR(500) NOT NULL,
    thumbnail_path VARCHAR(500) NULL,
    file_size_bytes BIGINT NOT NULL,
    dimensions_width INT NULL,
    dimensions_height INT NULL,
    duration_seconds INT NULL COMMENT 'For video/audio',
    
    -- Metadata
    tags JSON NULL,
    alt_text VARCHAR(500) NULL COMMENT 'For accessibility',
    caption VARCHAR(500) NULL,
    credit VARCHAR(255) NULL,
    taken_date DATE NULL,
    
    -- Privacy & Consent
    contains_clients BOOLEAN DEFAULT FALSE,
    consent_obtained BOOLEAN DEFAULT FALSE,
    consent_form_id BIGINT UNSIGNED NULL,
    is_public BOOLEAN DEFAULT TRUE,
    
    -- Usage & Display
    is_featured BOOLEAN DEFAULT FALSE,
    view_count INT DEFAULT 0,
    download_count INT DEFAULT 0,
    used_in_services JSON NULL COMMENT 'Service IDs where this media is used',
    sort_order INT DEFAULT 0,
    
    -- Upload Information
    uploaded_by BIGINT UNSIGNED NOT NULL,
    original_filename VARCHAR(255) NULL,
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    PRIMARY KEY (id),
    KEY idx_category (category_id),
    KEY idx_type (type),
    KEY idx_featured (is_featured, is_public),
    KEY idx_uploaded_by (uploaded_by),
    KEY idx_deleted (deleted_at),
    FULLTEXT KEY ft_search (title, description, alt_text),
    
    CONSTRAINT fk_media_category FOREIGN KEY (category_id) 
        REFERENCES media_categories(id) ON DELETE SET NULL,
    CONSTRAINT fk_media_uploaded_by FOREIGN KEY (uploaded_by) 
        REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Testimonials
CREATE TABLE testimonials (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    client_id BIGINT UNSIGNED NULL,
    service_id BIGINT UNSIGNED NULL,
    
    -- Author Information
    author_name VARCHAR(255) NOT NULL,
    author_relationship VARCHAR(100) NULL COMMENT 'e.g., Daughter, Son, Spouse',
    author_email VARCHAR(255) NULL,
    author_phone VARCHAR(20) NULL,
    
    -- Testimonial Content
    title VARCHAR(255) NULL,
    content TEXT NOT NULL,
    rating TINYINT NULL COMMENT 'Rating out of 5',
    
    -- Media
    photo_path VARCHAR(500) NULL,
    video_url VARCHAR(500) NULL,
    
    -- Display & Permissions
    is_featured BOOLEAN DEFAULT FALSE,
    is_approved BOOLEAN DEFAULT FALSE,
    display_on_website BOOLEAN DEFAULT FALSE,
    display_on_service BOOLEAN DEFAULT FALSE,
    can_contact_author BOOLEAN DEFAULT FALSE,
    
    -- Administrative
    approved_by BIGINT UNSIGNED NULL,
    approved_at TIMESTAMP NULL,
    source VARCHAR(50) NULL COMMENT 'website, email, survey, etc.',
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    published_at TIMESTAMP NULL,
    
    PRIMARY KEY (id),
    KEY idx_client (client_id),
    KEY idx_service (service_id),
    KEY idx_featured_approved (is_featured, is_approved),
    KEY idx_rating (rating),
    FULLTEXT KEY ft_content (title, content),
    
    CONSTRAINT fk_testimonials_client FOREIGN KEY (client_id) 
        REFERENCES clients(id) ON DELETE SET NULL,
    CONSTRAINT fk_testimonials_service FOREIGN KEY (service_id) 
        REFERENCES services(id) ON DELETE SET NULL,
    CONSTRAINT fk_testimonials_approved_by FOREIGN KEY (approved_by) 
        REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_rating CHECK (rating >= 1 AND rating <= 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Articles / Blog posts / Resources
CREATE TABLE articles (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    category_id INT UNSIGNED NULL,
    author_id BIGINT UNSIGNED NOT NULL,
    
    -- Content
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL,
    excerpt VARCHAR(500) NULL,
    content LONGTEXT NOT NULL,
    
    -- Media
    featured_image_path VARCHAR(500) NULL,
    thumbnail_path VARCHAR(500) NULL,
    attachments JSON NULL,
    
    -- SEO
    meta_title VARCHAR(255) NULL,
    meta_description TEXT NULL,
    keywords JSON NULL,
    
    -- Publishing
    status ENUM('draft', 'review', 'published', 'archived') DEFAULT 'draft',
    published_at TIMESTAMP NULL,
    featured_until DATE NULL,
    
    -- Engagement
    view_count INT DEFAULT 0,
    share_count INT DEFAULT 0,
    reading_time_minutes INT NULL,
    
    -- Settings
    allow_comments BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    is_sticky BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    PRIMARY KEY (id),
    UNIQUE KEY idx_slug (slug),
    KEY idx_author (author_id),
    KEY idx_category (category_id),
    KEY idx_status_published (status, published_at),
    KEY idx_featured (is_featured, featured_until),
    KEY idx_deleted (deleted_at),
    FULLTEXT KEY ft_search (title, excerpt, content),
    
    CONSTRAINT fk_articles_author FOREIGN KEY (author_id) 
        REFERENCES users(id),
    CONSTRAINT fk_articles_category FOREIGN KEY (category_id) 
        REFERENCES article_categories(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Article categories
CREATE TABLE article_categories (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    description TEXT NULL,
    parent_id INT UNSIGNED NULL,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    UNIQUE KEY idx_slug (slug),
    KEY idx_parent (parent_id),
    KEY idx_active_order (is_active, sort_order),
    
    CONSTRAINT fk_article_categories_parent FOREIGN KEY (parent_id) 
        REFERENCES article_categories(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- FAQs
CREATE TABLE faqs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    category_id INT UNSIGNED NULL,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    
    -- Related entities
    service_id BIGINT UNSIGNED NULL,
    
    -- Display
    is_featured BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INT DEFAULT 0,
    view_count INT DEFAULT 0,
    helpful_count INT DEFAULT 0,
    not_helpful_count INT DEFAULT 0,
    
    -- SEO
    meta_description TEXT NULL,
    keywords JSON NULL,
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    KEY idx_category (category_id),
    KEY idx_service (service_id),
    KEY idx_active_featured (is_active, is_featured),
    KEY idx_sort_order (sort_order),
    FULLTEXT KEY ft_search (question, answer),
    
    CONSTRAINT fk_faqs_category FOREIGN KEY (category_id) 
        REFERENCES faq_categories(id) ON DELETE SET NULL,
    CONSTRAINT fk_faqs_service FOREIGN KEY (service_id) 
        REFERENCES services(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- FAQ categories
CREATE TABLE faq_categories (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    description TEXT NULL,
    icon VARCHAR(100) NULL,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    UNIQUE KEY idx_slug (slug),
    KEY idx_active_order (is_active, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 7: COMMUNICATION & NOTIFICATIONS
-- ============================================================================

-- Contact inquiries
CREATE TABLE contact_inquiries (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    inquiry_type ENUM('general', 'services', 'booking', 'employment', 'complaint', 'other') DEFAULT 'general',
    
    -- Contact Information
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NULL,
    preferred_contact_method ENUM('email', 'phone', 'either') DEFAULT 'either',
    best_time_to_call VARCHAR(100) NULL,
    
    -- Inquiry Details
    subject VARCHAR(255) NULL,
    message TEXT NOT NULL,
    service_id BIGINT UNSIGNED NULL,
    urgency ENUM('low', 'normal', 'high', 'urgent') DEFAULT 'normal',
    
    -- Response Tracking
    status ENUM('new', 'in_progress', 'responded', 'closed', 'spam') DEFAULT 'new',
    assigned_to BIGINT UNSIGNED NULL,
    responded_by BIGINT UNSIGNED NULL,
    responded_at TIMESTAMP NULL,
    response_notes TEXT NULL,
    
    -- Source & Analytics
    source VARCHAR(50) NULL,
    referrer_url TEXT NULL,
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    KEY idx_status (status),
    KEY idx_type (inquiry_type),
    KEY idx_urgency (urgency, status),
    KEY idx_assigned (assigned_to),
    KEY idx_service (service_id),
    KEY idx_created (created_at),
    
    CONSTRAINT fk_inquiries_service FOREIGN KEY (service_id) 
        REFERENCES services(id) ON DELETE SET NULL,
    CONSTRAINT fk_inquiries_assigned FOREIGN KEY (assigned_to) 
        REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_inquiries_responded_by FOREIGN KEY (responded_by) 
        REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Notifications
CREATE TABLE notifications (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    notifiable_type VARCHAR(255) NOT NULL COMMENT 'Model type (User, Client)',
    notifiable_id BIGINT UNSIGNED NOT NULL COMMENT 'Model ID',
    type VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    data JSON NULL,
    
    -- Delivery
    channels JSON NOT NULL DEFAULT '["database"]' COMMENT 'Array: database, email, sms, push',
    email_sent_at TIMESTAMP NULL,
    sms_sent_at TIMESTAMP NULL,
    push_sent_at TIMESTAMP NULL,
    
    -- Status
    read_at TIMESTAMP NULL,
    action_url VARCHAR(500) NULL,
    action_taken_at TIMESTAMP NULL,
    
    -- Priority & Scheduling
    priority ENUM('low', 'normal', 'high', 'urgent') DEFAULT 'normal',
    scheduled_for TIMESTAMP NULL,
    expires_at TIMESTAMP NULL,
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    KEY idx_notifiable (notifiable_type, notifiable_id),
    KEY idx_read (notifiable_type, notifiable_id, read_at),
    KEY idx_scheduled (scheduled_for, created_at),
    KEY idx_type (type),
    KEY idx_priority (priority, read_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Newsletter subscriptions
CREATE TABLE newsletter_subscriptions (
    
