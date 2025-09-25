-- ============================================================================
-- ELDERLY DAYCARE CENTER DATABASE SCHEMA v2
-- Version: 2.0.0
-- Database: MariaDB 11.8
-- Character Set: utf8mb4 (full Unicode support including emojis)
-- Collation: utf8mb4_unicode_ci
-- ============================================================================

-- Create database with proper character set
CREATE DATABASE IF NOT EXISTS elderly_daycare_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE elderly_daycare_db;

-- Enable strict mode for data integrity
SET sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- ============================================================================
-- SECTION 1: AUTHENTICATION & AUTHORIZATION
-- ============================================================================

-- Users table (staff, admins, family members)
CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE DEFAULT (UUID()),
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(50) UNIQUE,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    display_name VARCHAR(200) GENERATED ALWAYS AS (CONCAT(first_name, ' ', last_name)) STORED,
    phone VARCHAR(20),
    phone_verified_at TIMESTAMP NULL,
    email_verified_at TIMESTAMP NULL,
    date_of_birth DATE,
    gender ENUM('male', 'female', 'other', 'prefer_not_to_say'),
    avatar_path VARCHAR(500),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country_code CHAR(2) DEFAULT 'US',
    timezone VARCHAR(50) DEFAULT 'America/New_York',
    locale VARCHAR(10) DEFAULT 'en_US',
    preferences JSON,
    is_active BOOLEAN DEFAULT TRUE,
    last_login_at TIMESTAMP NULL,
    last_login_ip VARCHAR(45),
    failed_login_attempts INT DEFAULT 0,
    locked_until TIMESTAMP NULL,
    two_factor_secret VARCHAR(255),
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    remember_token VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    INDEX idx_email (email),
    INDEX idx_username (username),
    INDEX idx_active (is_active, deleted_at),
    INDEX idx_login (email, password, is_active),
    FULLTEXT idx_fullname (first_name, last_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Roles table
CREATE TABLE roles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100),
    description TEXT,
    is_system BOOLEAN DEFAULT FALSE COMMENT 'System roles cannot be deleted',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Permissions table
CREATE TABLE permissions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    display_name VARCHAR(100),
    description TEXT,
    module VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_name (name),
    INDEX idx_module (module)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User-Role pivot table
CREATE TABLE role_user (
    user_id BIGINT UNSIGNED NOT NULL,
    role_id BIGINT UNSIGNED NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_by BIGINT UNSIGNED,
    
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_user (user_id),
    INDEX idx_role (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Permission-Role pivot table
CREATE TABLE permission_role (
    permission_id BIGINT UNSIGNED NOT NULL,
    role_id BIGINT UNSIGNED NOT NULL,
    
    PRIMARY KEY (permission_id, role_id),
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    
    INDEX idx_role (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Password reset tokens
CREATE TABLE password_resets (
    email VARCHAR(255) NOT NULL,
    token VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (email, token),
    INDEX idx_email (email),
    INDEX idx_token (token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Personal access tokens (for API access)
CREATE TABLE personal_access_tokens (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tokenable_type VARCHAR(255) NOT NULL,
    tokenable_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(255) NOT NULL,
    token VARCHAR(64) NOT NULL UNIQUE,
    abilities JSON,
    last_used_at TIMESTAMP NULL,
    expires_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_tokenable (tokenable_type, tokenable_id),
    INDEX idx_token (token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User sessions tracking
CREATE TABLE user_sessions (
    id VARCHAR(255) PRIMARY KEY,
    user_id BIGINT UNSIGNED,
    ip_address VARCHAR(45),
    user_agent TEXT,
    payload TEXT NOT NULL,
    last_activity INT NOT NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_last_activity (last_activity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 2: CLIENT MANAGEMENT
-- ============================================================================

-- Clients table (elderly individuals receiving care)
CREATE TABLE clients (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE DEFAULT (UUID()),
    client_number VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    preferred_name VARCHAR(100),
    display_name VARCHAR(200) GENERATED ALWAYS AS (COALESCE(preferred_name, CONCAT(first_name, ' ', last_name))) STORED,
    date_of_birth DATE NOT NULL,
    age INT GENERATED ALWAYS AS (TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE())) STORED,
    gender ENUM('male', 'female', 'other', 'prefer_not_to_say'),
    photo_path VARCHAR(500),
    phone VARCHAR(20),
    email VARCHAR(255),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country_code CHAR(2) DEFAULT 'US',
    
    -- Medical & care information
    blood_type ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'),
    medicare_number VARCHAR(50),
    insurance_provider VARCHAR(200),
    insurance_policy_number VARCHAR(100),
    physician_name VARCHAR(200),
    physician_phone VARCHAR(20),
    pharmacy_name VARCHAR(200),
    pharmacy_phone VARCHAR(20),
    
    -- Care requirements
    mobility_level ENUM('independent', 'walker', 'wheelchair', 'bedridden'),
    cognitive_level ENUM('normal', 'mild_impairment', 'moderate_impairment', 'severe_impairment'),
    communication_notes TEXT,
    behavioral_notes TEXT,
    
    -- Preferences
    dietary_restrictions JSON,
    food_preferences JSON,
    activity_preferences JSON,
    language_primary VARCHAR(20) DEFAULT 'en',
    language_secondary VARCHAR(20),
    religion VARCHAR(100),
    cultural_considerations TEXT,
    
    -- Administrative
    enrollment_date DATE,
    discharge_date DATE,
    discharge_reason TEXT,
    status ENUM('active', 'inactive', 'waitlist', 'discharged', 'deceased') DEFAULT 'active',
    intake_completed BOOLEAN DEFAULT FALSE,
    consent_photos BOOLEAN DEFAULT FALSE,
    consent_outings BOOLEAN DEFAULT FALSE,
    consent_medical BOOLEAN DEFAULT FALSE,
    
    -- Relationships
    created_by BIGINT UNSIGNED,
    updated_by BIGINT UNSIGNED,
    
    -- Metadata
    notes TEXT,
    tags JSON,
    custom_fields JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_client_number (client_number),
    INDEX idx_status (status, deleted_at),
    INDEX idx_enrollment (enrollment_date, discharge_date),
    INDEX idx_age (date_of_birth),
    FULLTEXT idx_name_search (first_name, last_name, preferred_name),
    
    CHECK (discharge_date IS NULL OR discharge_date >= enrollment_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Client contacts (family members, emergency contacts)
CREATE TABLE client_contacts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    client_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED COMMENT 'Link to user account if they have one',
    relationship ENUM('spouse', 'child', 'sibling', 'parent', 'guardian', 'friend', 'other') NOT NULL,
    relationship_other VARCHAR(100),
    is_primary BOOLEAN DEFAULT FALSE,
    is_emergency BOOLEAN DEFAULT TRUE,
    has_poa_medical BOOLEAN DEFAULT FALSE COMMENT 'Power of Attorney for medical',
    has_poa_financial BOOLEAN DEFAULT FALSE COMMENT 'Power of Attorney for financial',
    
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_primary VARCHAR(20) NOT NULL,
    phone_secondary VARCHAR(20),
    phone_work VARCHAR(20),
    email VARCHAR(255),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    
    preferred_contact_method ENUM('phone', 'email', 'text', 'mail') DEFAULT 'phone',
    preferred_contact_time VARCHAR(100),
    
    can_pickup BOOLEAN DEFAULT TRUE COMMENT 'Authorized to pick up client',
    receive_updates BOOLEAN DEFAULT TRUE,
    receive_invoices BOOLEAN DEFAULT FALSE,
    
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_client (client_id),
    INDEX idx_emergency (client_id, is_emergency),
    INDEX idx_primary (client_id, is_primary),
    INDEX idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Client health information (medical history, conditions)
CREATE TABLE client_health_info (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    client_id BIGINT UNSIGNED NOT NULL,
    
    -- Medical conditions
    medical_conditions JSON,
    allergies JSON,
    medications JSON,
    
    -- Assessments
    fall_risk ENUM('low', 'medium', 'high') DEFAULT 'low',
    wandering_risk ENUM('low', 'medium', 'high') DEFAULT 'low',
    swallowing_difficulty BOOLEAN DEFAULT FALSE,
    vision_impairment ENUM('none', 'mild', 'moderate', 'severe', 'blind'),
    hearing_impairment ENUM('none', 'mild', 'moderate', 'severe', 'deaf'),
    
    -- Care needs
    assistance_bathing BOOLEAN DEFAULT FALSE,
    assistance_dressing BOOLEAN DEFAULT FALSE,
    assistance_grooming BOOLEAN DEFAULT FALSE,
    assistance_eating BOOLEAN DEFAULT FALSE,
    assistance_medication BOOLEAN DEFAULT FALSE,
    assistance_toileting BOOLEAN DEFAULT FALSE,
    assistance_transfer BOOLEAN DEFAULT FALSE,
    assistance_walking BOOLEAN DEFAULT FALSE,
    
    -- Medical devices
    uses_wheelchair BOOLEAN DEFAULT FALSE,
    uses_walker BOOLEAN DEFAULT FALSE,
    uses_cane BOOLEAN DEFAULT FALSE,
    uses_hearing_aid BOOLEAN DEFAULT FALSE,
    uses_glasses BOOLEAN DEFAULT FALSE,
    uses_dentures BOOLEAN DEFAULT FALSE,
    uses_oxygen BOOLEAN DEFAULT FALSE,
    uses_cpap BOOLEAN DEFAULT FALSE,
    
    -- Behavioral
    behavioral_triggers TEXT,
    calming_techniques TEXT,
    sundowning_notes TEXT,
    
    -- Last assessments
    last_physical_exam DATE,
    last_dental_exam DATE,
    last_eye_exam DATE,
    last_hearing_test DATE,
    
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
    UNIQUE KEY unique_client (client_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 3: SERVICES & PROGRAMS
-- ============================================================================

-- Service categories
CREATE TABLE service_categories (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    icon VARCHAR(100),
    color VARCHAR(7) COMMENT 'Hex color code',
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_slug (slug),
    INDEX idx_active (is_active),
    INDEX idx_sort (sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Services table (programs offered by the daycare)
CREATE TABLE services (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id BIGINT UNSIGNED,
    name VARCHAR(200) NOT NULL,
    slug VARCHAR(200) NOT NULL UNIQUE,
    short_description VARCHAR(500),
    description TEXT,
    
    -- Service details
    duration_minutes INT COMMENT 'Typical duration in minutes',
    min_participants INT DEFAULT 1,
    max_participants INT DEFAULT 20,
    requires_registration BOOLEAN DEFAULT FALSE,
    requires_assessment BOOLEAN DEFAULT FALSE,
    
    -- Scheduling
    frequency ENUM('daily', 'weekly', 'biweekly', 'monthly', 'as_needed') DEFAULT 'daily',
    days_offered JSON COMMENT 'Array of weekdays',
    time_slots JSON COMMENT 'Array of time slots',
    
    -- Pricing
    price_type ENUM('free', 'fixed', 'per_hour', 'per_session', 'package') DEFAULT 'free',
    price DECIMAL(10, 2),
    price_unit VARCHAR(50),
    
    -- Requirements & features
    cognitive_level_required ENUM('any', 'normal', 'mild_impairment', 'moderate_impairment'),
    mobility_level_required ENUM('any', 'independent', 'walker_ok', 'wheelchair_ok'),
    staff_ratio VARCHAR(10) COMMENT 'e.g., 1:4',
    equipment_needed TEXT,
    prerequisites JSON,
    benefits JSON,
    features JSON,
    
    -- Media
    featured_image VARCHAR(500),
    gallery_images JSON,
    video_url VARCHAR(500),
    brochure_url VARCHAR(500),
    
    -- Metadata
    is_featured BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INT DEFAULT 0,
    
    -- SEO
    meta_title VARCHAR(255),
    meta_description TEXT,
    meta_keywords TEXT,
    
    -- Tracking
    view_count INT DEFAULT 0,
    inquiry_count INT DEFAULT 0,
    booking_count INT DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (category_id) REFERENCES service_categories(id) ON DELETE SET NULL,
    
    INDEX idx_slug (slug),
    INDEX idx_category (category_id),
    INDEX idx_active_featured (is_active, is_featured),
    INDEX idx_sort (sort_order),
    FULLTEXT idx_search (name, description, short_description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Activity programs (specific instances of services)
CREATE TABLE activity_programs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    service_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    
    -- Schedule
    start_date DATE NOT NULL,
    end_date DATE,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    recurrence_rule VARCHAR(500) COMMENT 'RFC 5545 RRULE format',
    
    -- Location
    location VARCHAR(200),
    room_id BIGINT UNSIGNED,
    is_offsite BOOLEAN DEFAULT FALSE,
    
    -- Capacity
    min_participants INT DEFAULT 1,
    max_participants INT DEFAULT 20,
    enrolled_count INT DEFAULT 0,
    waitlist_count INT DEFAULT 0,
    
    -- Staff
    lead_staff_id BIGINT UNSIGNED,
    assistant_staff_ids JSON,
    
    -- Status
    status ENUM('planned', 'active', 'completed', 'cancelled') DEFAULT 'planned',
    cancellation_reason TEXT,
    
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE,
    FOREIGN KEY (lead_staff_id) REFERENCES staff_members(id) ON DELETE SET NULL,
    
    INDEX idx_service (service_id),
    INDEX idx_dates (start_date, end_date),
    INDEX idx_status (status),
    INDEX idx_staff (lead_staff_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 4: STAFF MANAGEMENT
-- ============================================================================

-- Staff members table
CREATE TABLE staff_members (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED UNIQUE COMMENT 'Link to user account',
    employee_id VARCHAR(50) UNIQUE NOT NULL,
    
    -- Personal information
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    display_name VARCHAR(200) GENERATED ALWAYS AS (CONCAT(first_name, ' ', last_name)) STORED,
    title VARCHAR(100),
    department VARCHAR(100),
    
    -- Contact
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    phone_emergency VARCHAR(20),
    
    -- Professional information
    bio TEXT,
    qualifications JSON,
    certifications JSON,
    licenses JSON,
    specializations JSON,
    languages_spoken JSON,
    years_experience INT,
    
    -- Employment
    hire_date DATE NOT NULL,
    employment_type ENUM('full_time', 'part_time', 'contract', 'volunteer') DEFAULT 'full_time',
    hourly_rate DECIMAL(10, 2),
    
    -- Availability
    available_days JSON COMMENT 'Array of weekdays',
    available_shifts JSON COMMENT 'Array of shift preferences',
    max_hours_per_week INT,
    
    -- Media
    photo_path VARCHAR(500),
    introduction_video VARCHAR(500),
    
    -- Administrative
    background_check_date DATE,
    background_check_status ENUM('pending', 'cleared', 'review') DEFAULT 'pending',
    drug_test_date DATE,
    tb_test_date DATE,
    cpr_certification_date DATE,
    first_aid_certification_date DATE,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    termination_date DATE,
    termination_reason TEXT,
    
    -- Display
    show_on_website BOOLEAN DEFAULT TRUE,
    sort_order INT DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_user (user_id),
    INDEX idx_employee_id (employee_id),
    INDEX idx_active (is_active),
    INDEX idx_department (department),
    FULLTEXT idx_name (first_name, last_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Staff-Service assignments
CREATE TABLE service_staff (
    service_id BIGINT UNSIGNED NOT NULL,
    staff_member_id BIGINT UNSIGNED NOT NULL,
    role ENUM('lead', 'assistant', 'substitute') DEFAULT 'assistant',
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (service_id, staff_member_id),
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE,
    FOREIGN KEY (staff_member_id) REFERENCES staff_members(id) ON DELETE CASCADE,
    
    INDEX idx_staff (staff_member_id),
    INDEX idx_service (service_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Staff schedules
CREATE TABLE staff_schedules (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    staff_member_id BIGINT UNSIGNED NOT NULL,
    
    -- Schedule details
    schedule_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    break_start TIME,
    break_end TIME,
    
    -- Assignment
    activity_program_id BIGINT UNSIGNED,
    role VARCHAR(100),
    
    -- Status
    status ENUM('scheduled', 'confirmed', 'working', 'completed', 'absent', 'cancelled') DEFAULT 'scheduled',
    check_in_time TIMESTAMP NULL,
    check_out_time TIMESTAMP NULL,
    
    -- Overtime & adjustments
    is_overtime BOOLEAN DEFAULT FALSE,
    hours_worked DECIMAL(4, 2) GENERATED ALWAYS AS (
        CASE 
            WHEN check_out_time IS NOT NULL AND check_in_time IS NOT NULL 
            THEN TIMESTAMPDIFF(MINUTE, check_in_time, check_out_time) / 60.0
            ELSE NULL
        END
    ) STORED,
    
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (staff_member_id) REFERENCES staff_members(id) ON DELETE CASCADE,
    FOREIGN KEY (activity_program_id) REFERENCES activity_programs(id) ON DELETE SET NULL,
    
    UNIQUE KEY unique_staff_schedule (staff_member_id, schedule_date, start_time),
    INDEX idx_staff (staff_member_id),
    INDEX idx_date (schedule_date),
    INDEX idx_program (activity_program_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 5: BOOKING & SCHEDULING
-- ============================================================================

-- Booking slots (available time slots for services)
CREATE TABLE booking_slots (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    service_id BIGINT UNSIGNED NOT NULL,
    activity_program_id BIGINT UNSIGNED,
    
    -- Timing
    slot_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    duration_minutes INT GENERATED ALWAYS AS (TIMESTAMPDIFF(MINUTE, start_time, end_time)) STORED,
    
    -- Capacity
    total_capacity INT NOT NULL DEFAULT 20,
    booked_count INT DEFAULT 0,
    waitlist_count INT DEFAULT 0,
    available_capacity INT GENERATED ALWAYS AS (total_capacity - booked_count) STORED,
    
    -- Status
    status ENUM('available', 'full', 'waitlist', 'closed', 'cancelled') DEFAULT 'available',
    
    -- Pricing (can override service pricing)
    price DECIMAL(10, 2),
    
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE,
    FOREIGN KEY (activity_program_id) REFERENCES activity_programs(id) ON DELETE SET NULL,
    
    UNIQUE KEY unique_slot (service_id, slot_date, start_time),
    INDEX idx_service (service_id),
    INDEX idx_date (slot_date),
    INDEX idx_availability (status, slot_date),
    INDEX idx_program (activity_program_id),
    
    CHECK (end_time > start_time),
    CHECK (booked_count >= 0),
    CHECK (booked_count <= total_capacity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bookings table
CREATE TABLE bookings (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE DEFAULT (UUID()),
    booking_number VARCHAR(20) NOT NULL UNIQUE,
    
    -- Client information
    client_id BIGINT UNSIGNED,
    client_name VARCHAR(200) NOT NULL,
    client_email VARCHAR(255),
    client_phone VARCHAR(20),
    
    -- Booking details
    booking_type ENUM('trial', 'single', 'package', 'recurring') DEFAULT 'single',
    booking_source ENUM('website', 'phone', 'walk_in', 'referral', 'other') DEFAULT 'website',
    referral_source VARCHAR(200),
    
    -- Status
    status ENUM('pending', 'confirmed', 'checked_in', 'completed', 'cancelled', 'no_show') DEFAULT 'pending',
    confirmation_code VARCHAR(20),
    confirmed_at TIMESTAMP NULL,
    confirmed_by BIGINT UNSIGNED,
    checked_in_at TIMESTAMP NULL,
    checked_out_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,
    cancelled_by BIGINT UNSIGNED,
    cancellation_reason TEXT,
    
    -- Requirements
    special_requirements TEXT,
    dietary_needs TEXT,
    mobility_needs TEXT,
    medical_notes TEXT,
    emergency_contact_name VARCHAR(200),
    emergency_contact_phone VARCHAR(20),
    
    -- Transportation
    needs_transportation BOOLEAN DEFAULT FALSE,
    pickup_address TEXT,
    pickup_time TIME,
    dropoff_time TIME,
    
    -- Payment
    total_amount DECIMAL(10, 2),
    paid_amount DECIMAL(10, 2) DEFAULT 0.00,
    payment_status ENUM('pending', 'partial', 'paid', 'refunded') DEFAULT 'pending',
    payment_method ENUM('cash', 'check', 'credit_card', 'insurance', 'other'),
    
    -- Administrative
    internal_notes TEXT,
    created_by BIGINT UNSIGNED,
    updated_by BIGINT UNSIGNED,
    
    -- Metadata
    tags JSON,
    custom_fields JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL,
    FOREIGN KEY (confirmed_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (cancelled_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_booking_number (booking_number),
    INDEX idx_client (client_id),
    INDEX idx_status (status),
    INDEX idx_dates (created_at, confirmed_at),
    INDEX idx_source (booking_source),
    FULLTEXT idx_client_search (client_name, client_email, client_phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Booking-Service pivot table (which services are included in a booking)
CREATE TABLE booking_services (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED NOT NULL,
    service_id BIGINT UNSIGNED NOT NULL,
    booking_slot_id BIGINT UNSIGNED NOT NULL,
    
    -- Attendance
    attended BOOLEAN DEFAULT FALSE,
    check_in_time TIMESTAMP NULL,
    check_out_time TIMESTAMP NULL,
    
    -- Pricing
    unit_price DECIMAL(10, 2),
    quantity INT DEFAULT 1,
    subtotal DECIMAL(10, 2) GENERATED ALWAYS AS (unit_price * quantity) STORED,
    
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE,
    FOREIGN KEY (booking_slot_id) REFERENCES booking_slots(id) ON DELETE CASCADE,
    
    UNIQUE KEY unique_booking_service_slot (booking_id, service_id, booking_slot_id),
    INDEX idx_booking (booking_id),
    INDEX idx_service (service_id),
    INDEX idx_slot (booking_slot_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Waitlist entries
CREATE TABLE waitlist_entries (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    client_id BIGINT UNSIGNED,
    service_id BIGINT UNSIGNED NOT NULL,
    booking_slot_id BIGINT UNSIGNED,
    
    -- Contact info
    client_name VARCHAR(200) NOT NULL,
    client_email VARCHAR(255),
    client_phone VARCHAR(20),
    
    -- Preferences
    preferred_dates JSON,
    preferred_times JSON,
    flexibility ENUM('specific', 'flexible', 'very_flexible') DEFAULT 'flexible',
    
    -- Status
    status ENUM('waiting', 'offered', 'accepted', 'declined', 'expired') DEFAULT 'waiting',
    priority INT DEFAULT 0,
    offered_at TIMESTAMP NULL,
    offer_expires_at TIMESTAMP NULL,
    responded_at TIMESTAMP NULL,
    
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE,
    FOREIGN KEY (booking_slot_id) REFERENCES booking_slots(id) ON DELETE SET NULL,
    
    INDEX idx_service_status (service_id, status),
    INDEX idx_client (client_id),
    INDEX idx_priority (priority, created_at),
    INDEX idx_slot (booking_slot_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 6: CONTENT MANAGEMENT
-- ============================================================================

-- Media items (photos, videos, documents)
CREATE TABLE media_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE DEFAULT (UUID()),
    
    -- File information
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INT UNSIGNED,
    mime_type VARCHAR(100),
    file_extension VARCHAR(10),
    
    -- Media details
    media_type ENUM('image', 'video', 'document', 'audio') NOT NULL,
    title VARCHAR(255),
    description TEXT,
    alt_text VARCHAR(255),
    caption VARCHAR(500),
    
    -- Image specific
    width INT UNSIGNED,
    height INT UNSIGNED,
    thumbnail_path VARCHAR(500),
    
    -- Video specific
    duration_seconds INT UNSIGNED,
    video_thumbnail_path VARCHAR(500),
    
    -- Organization
    folder VARCHAR(255),
    tags JSON,
    is_public BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    
    -- Usage tracking
    view_count INT DEFAULT 0,
    download_count INT DEFAULT 0,
    
    -- Metadata
    uploaded_by BIGINT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_type (media_type),
    INDEX idx_public_featured (is_public, is_featured),
    INDEX idx_folder (folder),
    FULLTEXT idx_search (title, description, alt_text)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Polymorphic media associations
CREATE TABLE media_associations (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    media_item_id BIGINT UNSIGNED NOT NULL,
    associable_type VARCHAR(100) NOT NULL,
    associable_id BIGINT UNSIGNED NOT NULL,
    collection_name VARCHAR(100) DEFAULT 'default',
    sort_order INT DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (media_item_id) REFERENCES media_items(id) ON DELETE CASCADE,
    
    INDEX idx_media (media_item_id),
    INDEX idx_associable (associable_type, associable_id),
    INDEX idx_collection (collection_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Testimonials
CREATE TABLE testimonials (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Author information
    author_name VARCHAR(200) NOT NULL,
    author_relationship ENUM('client', 'family_member', 'caregiver', 'professional', 'other'),
    author_title VARCHAR(200),
    author_photo VARCHAR(500),
    
    -- Testimonial content
    content TEXT NOT NULL,
    excerpt VARCHAR(500),
    rating INT CHECK (rating >= 1 AND rating <= 5),
    
    -- Association
    service_id BIGINT UNSIGNED,
    client_id BIGINT UNSIGNED,
    
    -- Display
    is_featured BOOLEAN DEFAULT FALSE,
    is_approved BOOLEAN DEFAULT FALSE,
    approved_by BIGINT UNSIGNED,
    approved_at TIMESTAMP NULL,
    display_on_homepage BOOLEAN DEFAULT FALSE,
    
    -- Source
    source ENUM('website', 'google', 'facebook', 'email', 'survey', 'other') DEFAULT 'website',
    source_url VARCHAR(500),
    
    -- Metadata
    published_date DATE,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE SET NULL,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL,
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_featured_approved (is_featured, is_approved),
    INDEX idx_service (service_id),
    INDEX idx_rating (rating),
    INDEX idx_published (published_date),
    FULLTEXT idx_content (content, author_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- FAQ categories
CREATE TABLE faq_categories (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    icon VARCHAR(100),
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_slug (slug),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- FAQs
CREATE TABLE faqs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id BIGINT UNSIGNED,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    
    -- Metadata
    is_featured BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    view_count INT DEFAULT 0,
    helpful_count INT DEFAULT 0,
    not_helpful_count INT DEFAULT 0,
    sort_order INT DEFAULT 0,
    
    -- SEO
    slug VARCHAR(255) UNIQUE,
    meta_description TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (category_id) REFERENCES faq_categories(id) ON DELETE SET NULL,
    
    INDEX idx_category (category_id),
    INDEX idx_featured_active (is_featured, is_active),
    INDEX idx_sort (sort_order),
    FULLTEXT idx_search (question, answer)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Pages (for CMS functionality)
CREATE TABLE pages (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Page information
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    content TEXT,
    excerpt VARCHAR(500),
    
    -- Page type
    page_type ENUM('standard', 'landing', 'blog', 'resource') DEFAULT 'standard',
    template VARCHAR(100) DEFAULT 'default',
    
    -- Media
    featured_image VARCHAR(500),
    
    -- Status
    status ENUM('draft', 'published', 'scheduled', 'archived') DEFAULT 'draft',
    published_at TIMESTAMP NULL,
    
    -- SEO
    meta_title VARCHAR(255),
    meta_description TEXT,
    meta_keywords TEXT,
    canonical_url VARCHAR(500),
    
    -- Tracking
    view_count INT DEFAULT 0,
    
    -- Authorship
    author_id BIGINT UNSIGNED,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_slug (slug),
    INDEX idx_status_published (status, published_at),
    INDEX idx_type (page_type),
    FULLTEXT idx_search (title, content, excerpt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 7: COMMUNICATION
-- ============================================================================

-- Inquiries (contact form submissions)
CREATE TABLE inquiries (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE DEFAULT (UUID()),
    
    -- Contact information
    name VARCHAR(200) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    preferred_contact_method ENUM('email', 'phone', 'either') DEFAULT 'either',
    best_time_to_contact VARCHAR(100),
    
    -- Inquiry details
    inquiry_type ENUM('general', 'services', 'booking', 'tour', 'employment', 'other') DEFAULT 'general',
    subject VARCHAR(255),
    message TEXT NOT NULL,
    
    -- Interest tracking
    interested_services JSON,
    urgency ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
    timeline VARCHAR(100),
    
    -- Source tracking
    source ENUM('website', 'phone', 'email', 'referral', 'advertisement', 'other') DEFAULT 'website',
    referral_source VARCHAR(200),
    utm_source VARCHAR(100),
    utm_medium VARCHAR(100),
    utm_campaign VARCHAR(100),
    
    -- Response tracking
    status ENUM('new', 'in_progress', 'responded', 'closed', 'spam') DEFAULT 'new',
    assigned_to BIGINT UNSIGNED,
    responded_at TIMESTAMP NULL,
    response_notes TEXT,
    
    -- Client information
    client_id BIGINT UNSIGNED,
    
    -- Technical
    ip_address VARCHAR(45),
    user_agent TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL,
    
    INDEX idx_status (status),
    INDEX idx_type (inquiry_type),
    INDEX idx_assigned (assigned_to),
    INDEX idx_created (created_at),
    FULLTEXT idx_search (name, email, subject, message)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Messages (internal messaging system)
CREATE TABLE messages (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Participants
    sender_id BIGINT UNSIGNED NOT NULL,
    recipient_id BIGINT UNSIGNED,
    recipient_type ENUM('user', 'broadcast', 'group') DEFAULT 'user',
    
    -- Message content
    subject VARCHAR(255),
    body TEXT NOT NULL,
    
    -- Threading
    thread_id VARCHAR(100),
    parent_message_id BIGINT UNSIGNED,
    
    -- Status
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP NULL,
    is_starred BOOLEAN DEFAULT FALSE,
    is_archived BOOLEAN DEFAULT FALSE,
    
    -- Attachments
    attachments JSON,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_message_id) REFERENCES messages(id) ON DELETE SET NULL,
    
    INDEX idx_sender (sender_id),
    INDEX idx_recipient (recipient_id, is_read),
    INDEX idx_thread (thread_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Notifications
CREATE TABLE notifications (
    id CHAR(36) PRIMARY KEY,
    type VARCHAR(255) NOT NULL,
    notifiable_type VARCHAR(255) NOT NULL,
    notifiable_id BIGINT UNSIGNED NOT NULL,
    data JSON NOT NULL,
    read_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_notifiable (notifiable_type, notifiable_id),
    INDEX idx_read (read_at),
    INDEX idx_type (type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Email logs
CREATE TABLE email_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Recipients
    to_email VARCHAR(255) NOT NULL,
    cc_emails JSON,
    bcc_emails JSON,
    from_email VARCHAR(255),
    reply_to VARCHAR(255),
    
    -- Content
    subject VARCHAR(255),
    body TEXT,
    template VARCHAR(100),
    
    -- Tracking
    status ENUM('pending', 'sent', 'delivered', 'bounced', 'failed') DEFAULT 'pending',
    sent_at TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,
    opened_at TIMESTAMP NULL,
    clicked_at TIMESTAMP NULL,
    
    -- Error handling
    error_message TEXT,
    retry_count INT DEFAULT 0,
    
    -- Association
    related_type VARCHAR(100),
    related_id BIGINT UNSIGNED,
    
    -- Metadata
    headers JSON,
    attachments JSON,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_to (to_email),
    INDEX idx_status (status),
    INDEX idx_sent (sent_at),
    INDEX idx_related (related_type, related_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 8: ANALYTICS & REPORTING
-- ============================================================================

-- Page views tracking
CREATE TABLE page_views (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Page information
    url VARCHAR(500) NOT NULL,
    page_title VARCHAR(255),
    page_type VARCHAR(50),
    
    -- Visitor information
    visitor_id VARCHAR(100),
    user_id BIGINT UNSIGNED,
    ip_address VARCHAR(45),
    user_agent TEXT,
    
    -- Session information
    session_id VARCHAR(100),
    referrer_url VARCHAR(500),
    
    -- Device & browser
    device_type ENUM('desktop', 'tablet', 'mobile', 'other'),
    browser VARCHAR(50),
    browser_version VARCHAR(20),
    os VARCHAR(50),
    os_version VARCHAR(20),
    
    -- Location
    country_code CHAR(2),
    region VARCHAR(100),
    city VARCHAR(100),
    
    -- Metrics
    time_on_page INT COMMENT 'Seconds',
    bounce BOOLEAN DEFAULT FALSE,
    exit_page BOOLEAN DEFAULT FALSE,
    
    -- UTM parameters
    utm_source VARCHAR(100),
    utm_medium VARCHAR(100),
    utm_campaign VARCHAR(100),
    utm_term VARCHAR(100),
    utm_content VARCHAR(100),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_url (url),
    INDEX idx_visitor (visitor_id),
    INDEX idx_user (user_id),
    
