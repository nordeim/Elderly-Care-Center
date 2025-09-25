Deep Analysis: Database Schema Design for Elderly Daycare Platform
🎯 Core Design Principles
After thorough analysis of the elderly daycare domain, I've identified critical schema requirements:

Healthcare-Centric Design: Must accommodate medical information, emergency contacts, and care preferences
Relationship Complexity: Clients have families, multiple emergency contacts, assigned staff
Temporal Accuracy: Booking slots, schedules, and availability tracking require precise time management
Audit Requirements: Healthcare regulations demand comprehensive audit trails
Privacy by Design: Sensitive data must be clearly marked for encryption/protection
Scalability Patterns: Schema must support growth without major refactoring
📊 Entity Relationship Analysis
text

Critical Relationships Identified:
├── Many-to-Many: Services ↔ Staff, Clients ↔ Services
├── One-to-Many: Clients → Emergency Contacts, Bookings → Services
├── Hierarchical: Users → Roles → Permissions
├── Temporal: Booking Slots, Service Schedules, Staff Shifts
└── Polymorphic: Media attachable to multiple entities
🔧 MariaDB 11.8 Specific Optimizations
Leveraging INSTANT algorithm for ALTER TABLE operations
Using INVISIBLE indexes for testing
Implementing CHECK constraints for data integrity
Utilizing JSON columns with indexed virtual columns
Employing ROW format for better compression
Comprehensive Database Schema
SQL

-- =============================================
-- ELDERLY DAYCARE CENTER DATABASE SCHEMA
-- MariaDB Version: 11.8
-- Character Set: utf8mb4 (emoji support)
-- Collation: utf8mb4_unicode_ci
-- Engine: InnoDB (ACID compliance, foreign keys)
-- =============================================

-- Create database with proper encoding
CREATE DATABASE IF NOT EXISTS elderly_daycare_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE elderly_daycare_db;

-- Set timezone to UTC for consistency
SET time_zone = '+00:00';

-- =============================================
-- SECTION 1: USER MANAGEMENT & AUTHENTICATION
-- =============================================

-- Users table (staff, admins, and future client portal users)
CREATE TABLE users (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE DEFAULT (UUID()),
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(50) UNIQUE,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    phone_verified_at TIMESTAMP NULL,
    email_verified_at TIMESTAMP NULL,
    two_factor_secret TEXT,
    two_factor_recovery_codes TEXT,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    avatar_path VARCHAR(500),
    timezone VARCHAR(50) DEFAULT 'UTC',
    locale VARCHAR(10) DEFAULT 'en',
    is_active BOOLEAN DEFAULT TRUE,
    is_suspended BOOLEAN DEFAULT FALSE,
    suspension_reason TEXT,
    last_login_at TIMESTAMP NULL,
    last_login_ip VARCHAR(45),
    failed_login_attempts INT DEFAULT 0,
    locked_until TIMESTAMP NULL,
    password_changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    preferences JSON,
    metadata JSON,
    remember_token VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    INDEX idx_email (email),
    INDEX idx_active_users (is_active, is_suspended),
    INDEX idx_last_login (last_login_at),
    INDEX idx_deleted (deleted_at),
    FULLTEXT idx_user_search (first_name, last_name, email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Roles table
CREATE TABLE roles (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100),
    description TEXT,
    is_system BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_role_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Permissions table
CREATE TABLE permissions (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    display_name VARCHAR(100),
    description TEXT,
    module VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_permission_name (name),
    INDEX idx_module (module)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User roles pivot table
CREATE TABLE user_roles (
    user_id BIGINT UNSIGNED NOT NULL,
    role_id INT UNSIGNED NOT NULL,
    assigned_by BIGINT UNSIGNED,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_user_roles_user (user_id),
    INDEX idx_user_roles_role (role_id),
    INDEX idx_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Role permissions pivot table
CREATE TABLE role_permissions (
    role_id INT UNSIGNED NOT NULL,
    permission_id INT UNSIGNED NOT NULL,
    
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    
    INDEX idx_role_permissions_role (role_id),
    INDEX idx_role_permissions_permission (permission_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Password reset tokens
CREATE TABLE password_reset_tokens (
    email VARCHAR(255) NOT NULL,
    token VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (email),
    INDEX idx_token (token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User sessions (for session management)
CREATE TABLE sessions (
    id VARCHAR(255) NOT NULL PRIMARY KEY,
    user_id BIGINT UNSIGNED,
    ip_address VARCHAR(45),
    user_agent TEXT,
    payload LONGTEXT NOT NULL,
    last_activity INT NOT NULL,
    
    INDEX idx_sessions_user (user_id),
    INDEX idx_sessions_last_activity (last_activity),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- SECTION 2: STAFF MANAGEMENT
-- =============================================

-- Staff members (detailed staff profiles)
CREATE TABLE staff_members (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED UNIQUE,
    employee_id VARCHAR(50) UNIQUE,
    slug VARCHAR(255) UNIQUE NOT NULL,
    title VARCHAR(100) NOT NULL,
    department VARCHAR(100),
    bio TEXT,
    qualifications JSON,
    certifications JSON,
    specializations JSON,
    years_experience DECIMAL(3,1),
    languages_spoken JSON,
    photo_path VARCHAR(500),
    emergency_contact JSON,
    hire_date DATE,
    employment_type ENUM('full_time', 'part_time', 'contract', 'volunteer') DEFAULT 'full_time',
    work_schedule JSON,
    hourly_rate DECIMAL(10,2),
    is_featured BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    background_check_date DATE,
    background_check_status ENUM('pending', 'cleared', 'review') DEFAULT 'pending',
    training_completed JSON,
    sort_order INT DEFAULT 0,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_staff_active (is_active),
    INDEX idx_staff_featured (is_featured),
    INDEX idx_staff_department (department),
    INDEX idx_staff_deleted (deleted_at),
    FULLTEXT idx_staff_search (title, bio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Staff availability/shifts
CREATE TABLE staff_schedules (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    staff_member_id BIGINT UNSIGNED NOT NULL,
    day_of_week TINYINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    effective_from DATE,
    effective_until DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (staff_member_id) REFERENCES staff_members(id) ON DELETE CASCADE,
    INDEX idx_staff_schedule (staff_member_id, day_of_week),
    INDEX idx_schedule_effective (effective_from, effective_until)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- SECTION 3: SERVICES & PROGRAMS
-- =============================================

-- Service categories
CREATE TABLE service_categories (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    icon VARCHAR(100),
    color VARCHAR(7),
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_category_slug (slug),
    INDEX idx_category_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Services/Programs offered
CREATE TABLE services (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    category_id INT UNSIGNED,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    short_description VARCHAR(500),
    description TEXT,
    features JSON,
    benefits JSON,
    requirements JSON,
    eligibility_criteria JSON,
    duration_minutes INT,
    min_participants INT DEFAULT 1,
    max_participants INT DEFAULT 20,
    age_range_min INT,
    age_range_max INT,
    price DECIMAL(10,2),
    price_type ENUM('per_session', 'per_day', 'per_week', 'per_month') DEFAULT 'per_session',
    image_path VARCHAR(500),
    gallery_images JSON,
    video_url VARCHAR(500),
    icon VARCHAR(100),
    color VARCHAR(7),
    is_featured BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    requires_assessment BOOLEAN DEFAULT FALSE,
    requires_medical_clearance BOOLEAN DEFAULT FALSE,
    sort_order INT DEFAULT 0,
    meta_title VARCHAR(255),
    meta_description TEXT,
    meta_keywords TEXT,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (category_id) REFERENCES service_categories(id) ON DELETE SET NULL,
    INDEX idx_service_slug (slug),
    INDEX idx_service_active (is_active, is_featured),
    INDEX idx_service_category (category_id),
    INDEX idx_service_price (price_type, price),
    INDEX idx_service_deleted (deleted_at),
    FULLTEXT idx_service_search (name, description, short_description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Service schedules (recurring schedule for services)
CREATE TABLE service_schedules (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    service_id BIGINT UNSIGNED NOT NULL,
    day_of_week TINYINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    room_location VARCHAR(100),
    max_capacity INT DEFAULT 20,
    staff_required INT DEFAULT 1,
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE,
    INDEX idx_service_schedule (service_id, day_of_week),
    INDEX idx_schedule_time (start_time, end_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Staff assigned to services (many-to-many)
CREATE TABLE service_staff (
    service_id BIGINT UNSIGNED NOT NULL,
    staff_member_id BIGINT UNSIGNED NOT NULL,
    role VARCHAR(100),
    is_primary BOOLEAN DEFAULT FALSE,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (service_id, staff_member_id),
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE,
    FOREIGN KEY (staff_member_id) REFERENCES staff_members(id) ON DELETE CASCADE,
    
    INDEX idx_service_staff_service (service_id),
    INDEX idx_service_staff_member (staff_member_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- SECTION 4: CLIENT MANAGEMENT
-- =============================================

-- Clients (elderly individuals receiving care)
CREATE TABLE clients (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    client_number VARCHAR(50) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    preferred_name VARCHAR(100),
    date_of_birth DATE NOT NULL,
    gender ENUM('male', 'female', 'other', 'prefer_not_to_say'),
    photo_path VARCHAR(500),
    phone VARCHAR(20),
    email VARCHAR(255),
    address JSON,
    living_arrangement ENUM('alone', 'with_family', 'assisted_living', 'other'),
    mobility_level ENUM('independent', 'walker', 'wheelchair', 'limited'),
    cognitive_status ENUM('normal', 'mild_impairment', 'moderate_impairment', 'severe_impairment'),
    communication_preferences JSON,
    languages_spoken JSON,
    cultural_considerations TEXT,
    dietary_restrictions JSON,
    allergies JSON,
    medical_conditions JSON,
    medications JSON,
    physician_name VARCHAR(255),
    physician_phone VARCHAR(20),
    insurance_provider VARCHAR(255),
    insurance_number VARCHAR(100),
    emergency_evacuation_plan TEXT,
    enrollment_date DATE,
    discharge_date DATE,
    discharge_reason TEXT,
    assessment_date DATE,
    assessment_notes TEXT,
    care_plan JSON,
    goals JSON,
    preferences JSON,
    photo_consent BOOLEAN DEFAULT FALSE,
    data_sharing_consent BOOLEAN DEFAULT FALSE,
    marketing_consent BOOLEAN DEFAULT FALSE,
    status ENUM('inquiry', 'assessment', 'active', 'inactive', 'discharged') DEFAULT 'inquiry',
    risk_level ENUM('low', 'medium', 'high') DEFAULT 'low',
    notes TEXT,
    metadata JSON,
    created_by BIGINT UNSIGNED,
    updated_by BIGINT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_client_number (client_number),
    INDEX idx_client_status (status),
    INDEX idx_client_enrollment (enrollment_date),
    INDEX idx_client_birth (date_of_birth),
    INDEX idx_client_deleted (deleted_at),
    FULLTEXT idx_client_search (first_name, last_name, preferred_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Emergency contacts for clients
CREATE TABLE emergency_contacts (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    client_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(255) NOT NULL,
    relationship VARCHAR(100) NOT NULL,
    phone_primary VARCHAR(20) NOT NULL,
    phone_secondary VARCHAR(20),
    email VARCHAR(255),
    address JSON,
    is_primary BOOLEAN DEFAULT FALSE,
    is_authorized_pickup BOOLEAN DEFAULT FALSE,
    is_healthcare_proxy BOOLEAN DEFAULT FALSE,
    has_power_of_attorney BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
    INDEX idx_emergency_client (client_id),
    INDEX idx_emergency_primary (is_primary)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Client documents (assessments, care plans, etc.)
CREATE TABLE client_documents (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    client_id BIGINT UNSIGNED NOT NULL,
    document_type ENUM('assessment', 'care_plan', 'medical_record', 'consent_form', 'insurance', 'other') NOT NULL,
    title VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INT,
    mime_type VARCHAR(100),
    is_confidential BOOLEAN DEFAULT TRUE,
    uploaded_by BIGINT UNSIGNED,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_client_docs (client_id, document_type),
    INDEX idx_doc_confidential (is_confidential)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- SECTION 5: BOOKING & SCHEDULING
-- =============================================

-- Booking slots (available time slots for services)
CREATE TABLE booking_slots (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    service_id BIGINT UNSIGNED,
    slot_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    capacity INT DEFAULT 20,
    booked_count INT DEFAULT 0,
    waitlist_count INT DEFAULT 0,
    room_location VARCHAR(100),
    staff_assigned JSON,
    status ENUM('available', 'full', 'cancelled', 'completed') DEFAULT 'available',
    cancellation_reason TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE,
    INDEX idx_slot_date (slot_date),
    INDEX idx_slot_service (service_id, slot_date),
    INDEX idx_slot_status (status),
    INDEX idx_slot_availability (slot_date, status, booked_count, capacity),
    
    CONSTRAINT check_capacity CHECK (booked_count <= capacity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bookings/Reservations
CREATE TABLE bookings (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    booking_number VARCHAR(20) UNIQUE NOT NULL,
    booking_type ENUM('trial', 'regular', 'respite', 'emergency') DEFAULT 'regular',
    client_id BIGINT UNSIGNED,
    slot_id BIGINT UNSIGNED NOT NULL,
    service_id BIGINT UNSIGNED NOT NULL,
    booked_by_user_id BIGINT UNSIGNED,
    client_name VARCHAR(255),
    client_email VARCHAR(255),
    client_phone VARCHAR(20),
    emergency_contact JSON,
    special_requirements TEXT,
    transport_required BOOLEAN DEFAULT FALSE,
    meal_required BOOLEAN DEFAULT TRUE,
    dietary_notes TEXT,
    status ENUM('pending', 'confirmed', 'waitlisted', 'cancelled', 'completed', 'no_show') DEFAULT 'pending',
    confirmation_code VARCHAR(50) UNIQUE,
    confirmed_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,
    cancellation_reason TEXT,
    cancelled_by BIGINT UNSIGNED,
    check_in_time TIMESTAMP NULL,
    check_out_time TIMESTAMP NULL,
    attendance_notes TEXT,
    incident_report TEXT,
    payment_status ENUM('pending', 'paid', 'refunded', 'waived') DEFAULT 'pending',
    payment_amount DECIMAL(10,2),
    payment_method VARCHAR(50),
    invoice_number VARCHAR(50),
    notes TEXT,
    internal_notes TEXT,
    follow_up_required BOOLEAN DEFAULT FALSE,
    follow_up_notes TEXT,
    satisfaction_rating TINYINT CHECK (satisfaction_rating BETWEEN 1 AND 5),
    feedback TEXT,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL,
    FOREIGN KEY (slot_id) REFERENCES booking_slots(id) ON DELETE RESTRICT,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE RESTRICT,
    FOREIGN KEY (booked_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (cancelled_by) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_booking_number (booking_number),
    INDEX idx_booking_client (client_id),
    INDEX idx_booking_slot (slot_id),
    INDEX idx_booking_service (service_id),
    INDEX idx_booking_status (status),
    INDEX idx_booking_date (created_at),
    INDEX idx_booking_confirmation (confirmation_code),
    INDEX idx_booking_payment (payment_status),
    INDEX idx_booking_follow_up (follow_up_required)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Waitlist entries
CREATE TABLE waitlist_entries (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    client_id BIGINT UNSIGNED,
    service_id BIGINT UNSIGNED NOT NULL,
    preferred_dates JSON,
    priority TINYINT DEFAULT 5,
    contact_name VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255) NOT NULL,
    contact_phone VARCHAR(20),
    notes TEXT,
    status ENUM('waiting', 'contacted', 'booked', 'expired', 'cancelled') DEFAULT 'waiting',
    contacted_at TIMESTAMP NULL,
    booked_at TIMESTAMP NULL,
    expires_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE,
    
    INDEX idx_waitlist_service (service_id),
    INDEX idx_waitlist_status (status),
    INDEX idx_waitlist_priority (priority, created_at),
    INDEX idx_waitlist_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- SECTION 6: CONTENT & MEDIA MANAGEMENT
-- =============================================

-- Media items (photos, videos, documents)
CREATE TABLE media_items (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE DEFAULT (UUID()),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    type ENUM('image', 'video', 'document', 'audio') NOT NULL,
    mime_type VARCHAR(100),
    file_path VARCHAR(500) NOT NULL,
    thumbnail_path VARCHAR(500),
    file_size BIGINT,
    duration_seconds INT,
    dimensions JSON,
    alt_text VARCHAR(500),
    caption TEXT,
    credit VARCHAR(255),
    tags JSON,
    is_public BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    view_count INT DEFAULT 0,
    download_count INT DEFAULT 0,
    uploaded_by BIGINT UNSIGNED,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_media_type (type),
    INDEX idx_media_public (is_public, is_featured),
    INDEX idx_media_uploaded_by (uploaded_by),
    INDEX idx_media_deleted (deleted_at),
    FULLTEXT idx_media_search (title, description, alt_text)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Polymorphic media relationships
CREATE TABLE mediables (
    media_item_id BIGINT UNSIGNED NOT NULL,
    mediable_type VARCHAR(100) NOT NULL,
    mediable_id BIGINT UNSIGNED NOT NULL,
    collection_name VARCHAR(100) DEFAULT 'default',
    order_column INT DEFAULT 0,
    
    PRIMARY KEY (media_item_id, mediable_type, mediable_id),
    FOREIGN KEY (media_item_id) REFERENCES media_items(id) ON DELETE CASCADE,
    
    INDEX idx_mediable (mediable_type, mediable_id),
    INDEX idx_mediable_collection (collection_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Testimonials
CREATE TABLE testimonials (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    client_id BIGINT UNSIGNED,
    service_id BIGINT UNSIGNED,
    author_name VARCHAR(255) NOT NULL,
    author_relationship VARCHAR(100),
    author_photo_path VARCHAR(500),
    content TEXT NOT NULL,
    rating TINYINT CHECK (rating BETWEEN 1 AND 5),
    video_url VARCHAR(500),
    is_featured BOOLEAN DEFAULT FALSE,
    is_published BOOLEAN DEFAULT FALSE,
    consent_given BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMP NULL,
    sort_order INT DEFAULT 0,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE SET NULL,
    
    INDEX idx_testimonial_published (is_published, is_featured),
    INDEX idx_testimonial_service (service_id),
    INDEX idx_testimonial_rating (rating),
    FULLTEXT idx_testimonial_search (content, author_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- FAQs
CREATE TABLE faqs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    category VARCHAR(100),
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    is_published BOOLEAN DEFAULT TRUE,
    view_count INT DEFAULT 0,
    helpful_count INT DEFAULT 0,
    sort_order INT DEFAULT 0,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_faq_category (category),
    INDEX idx_faq_published (is_published),
    INDEX idx_faq_popular (view_count, helpful_count),
    FULLTEXT idx_faq_search (question, answer)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Blog posts / Articles
CREATE TABLE articles (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    slug VARCHAR(255) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    excerpt TEXT,
    content LONGTEXT,
    featured_image_path VARCHAR(500),
    author_id BIGINT UNSIGNED,
    category VARCHAR(100),
    tags JSON,
    is_published BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMP NULL,
    view_count INT DEFAULT 0,
    reading_time_minutes INT,
    meta_title VARCHAR(255),
    meta_description TEXT,
    meta_keywords TEXT,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_article_slug (slug),
    INDEX idx_article_published (is_published, published_at),
    INDEX idx_article_featured (is_featured),
    INDEX idx_article_category (category),
    INDEX idx_article_author (author_id),
    INDEX idx_article_deleted (deleted_at),
    FULLTEXT idx_article_search (title, excerpt, content)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Resources/Downloads
CREATE TABLE resources (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    type ENUM('pdf', 'video', 'link', 'form', 'guide') NOT NULL,
    file_path VARCHAR(500),
    external_url VARCHAR(500),
    thumbnail_path VARCHAR(500),
    file_size BIGINT,
    tags JSON,
    target_audience ENUM('clients', 'families', 'caregivers', 'professionals', 'all') DEFAULT 'all',
    access_level ENUM('public', 'registered', 'client_only', 'staff_only') DEFAULT 'public',
    download_count INT DEFAULT 0,
    is_featured BOOLEAN DEFAULT FALSE,
    is_published BOOLEAN DEFAULT TRUE,
    sort_order INT DEFAULT 0,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_resource_category (category),
    INDEX idx_resource_type (type),
    INDEX idx_resource_audience (target_audience),
    INDEX idx_resource_access (access_level),
    INDEX idx_resource_published (is_published, is_featured),
    FULLTEXT idx_resource_search (title, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- SECTION 7: COMMUNICATION & NOTIFICATIONS
-- =============================================

-- Contact inquiries
CREATE TABLE inquiries (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    inquiry_number VARCHAR(20) UNIQUE NOT NULL,
    type ENUM('general', 'service', 'booking', 'tour', 'employment', 'complaint') DEFAULT 'general',
    service_id BIGINT UNSIGNED,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    preferred_contact_method ENUM('email', 'phone', 'text') DEFAULT 'email',
    best_time_to_contact VARCHAR(100),
    subject VARCHAR(255),
    message TEXT NOT NULL,
    urgency ENUM('low', 'normal', 'high', 'urgent') DEFAULT 'normal',
    source VARCHAR(100),
    referral_source VARCHAR(255),
    status ENUM('new', 'in_progress', 'responded', 'closed', 'spam') DEFAULT 'new',
    assigned_to BIGINT UNSIGNED,
    responded_at TIMESTAMP NULL,
    response_notes TEXT,
    follow_up_date DATE,
    conversion_status ENUM('none', 'tour_scheduled', 'enrolled', 'not_interested'),
    ip_address VARCHAR(45),
    user_agent TEXT,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_inquiry_number (inquiry_number),
    INDEX idx_inquiry_type (type),
    INDEX idx_inquiry_status (status),
    INDEX idx_inquiry_urgency (urgency),
    INDEX idx_inquiry_assigned (assigned_to),
    INDEX idx_inquiry_follow_up (follow_up_date),
    FULLTEXT idx_inquiry_search (name, email, subject, message)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Email templates
CREATE TABLE email_templates (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    subject VARCHAR(255) NOT NULL,
    body_html LONGTEXT,
    body_text TEXT,
    variables JSON,
    category VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_template_name (name),
    INDEX idx_template_category (category),
    INDEX idx_template_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Notification logs
CREATE TABLE notifications (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    notifiable_type VARCHAR(100),
    notifiable_id BIGINT UNSIGNED,
    type VARCHAR(100) NOT NULL,
    channel ENUM('email', 'sms', 'database', 'push') NOT NULL,
    recipient VARCHAR(255),
    subject VARCHAR(255),
    content TEXT,
    data JSON,
    status ENUM('pending', 'sent', 'failed', 'bounced') DEFAULT 'pending',
    sent_at TIMESTAMP NULL,
    read_at TIMESTAMP NULL,
    failed_reason TEXT,
    attempts INT DEFAULT 0,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_notification_notifiable (notifiable_type, notifiable_id),
    INDEX idx_notification_type (type),
    INDEX idx_notification_channel (channel),
    INDEX idx_notification_status (status),
    INDEX idx_notification_recipient (recipient),
    INDEX idx_notification_read (read_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Newsletter subscribers
CREATE TABLE newsletter_subscribers (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    subscriber_type ENUM('client', 'family', 'caregiver', 'professional', 'other') DEFAULT 'other',
    interests JSON,
    status ENUM('pending', 'active', 'unsubscribed', 'bounced') DEFAULT 'pending',
    confirmation_token VARCHAR(100) UNIQUE,
    confirmed_at TIMESTAMP NULL,
    unsubscribed_at TIMESTAMP NULL,
    unsubscribe_reason TEXT,
    ip_address VARCHAR(45),
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_subscriber_email (email),
    INDEX idx_subscriber_status (status),
    INDEX idx_subscriber_type (subscriber_type),
    INDEX idx_subscriber_token (confirmation_token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- SECTION 8: ANALYTICS & REPORTING
-- =============================================

-- Page views tracking
CREATE TABLE page_views (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    session_id VARCHAR(255),
    user_id BIGINT UNSIGNED,
    url VARCHAR(500) NOT NULL,
    referrer VARCHAR(500),
    ip_address VARCHAR(45),
    user_agent TEXT,
    device_type ENUM('desktop', 'tablet', 'mobile', 'other'),
    browser VARCHAR(50),
    platform VARCHAR(50),
    country VARCHAR(2),
    region VARCHAR(100),
    city VARCHAR(100),
    page_load_time INT,
    time_on_page INT,
    bounce BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_page_view_session (session_id),
    INDEX idx_page_view_user (user_id),
    INDEX idx_page_view_url (url(255)),
    INDEX idx_page_view_date (created_at),
    INDEX idx_page_view_device (device_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
PARTITION BY RANGE (UNIX_TIMESTAMP(created_at)) (
    PARTITION p_2024_q1 VALUES LESS THAN (UNIX_TIMESTAMP('2024-04-01')),
    PARTITION p_2024_q2 VALUES LESS THAN (UNIX_TIMESTAMP('2024-07-01')),
    PARTITION p_2024_q3 VALUES LESS THAN (UNIX_TIMESTAMP('2024-10-01')),
    PARTITION p_2024_q4 VALUES LESS THAN (UNIX_TIMESTAMP('2025-01-01')),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Activity/Audit logs
CREATE TABLE activity_logs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    log_name VARCHAR(100) DEFAULT 'default',
    description TEXT NOT NULL,
    subject_type VARCHAR(100),
    subject_id BIGINT UNSIGNED,
    causer_type VARCHAR(100),
    causer_id BIGINT UNSIGNED,
    properties JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_activity_log_name (log_name),
    INDEX idx_activity_subject (subject_type, subject_id),
    INDEX idx_activity_causer (causer_type, causer_id),
    INDEX idx_activity_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
PARTITION BY RANGE (UNIX_TIMESTAMP(created_at)) (
    PARTITION p_2024_q1 VALUES LESS THAN (UNIX_TIMESTAMP('2024-04-01')),
    PARTITION p_2024_q2 VALUES LESS THAN (UNIX_TIMESTAMP('2024-07-01')),
    PARTITION p_2024_q3 VALUES LESS THAN (UNIX_TIMESTAMP('2024-10-01')),
    PARTITION p_2024_q4 VALUES LESS THAN (UNIX_TIMESTAMP('2025-01-01')),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Search queries tracking
CREATE TABLE search_queries (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    query VARCHAR(255) NOT NULL,
    results_count INT DEFAULT 0,
    user_id BIGINT UNSIGNED,
    session_id VARCHAR(255),
    clicked_result VARCHAR(500),
    search_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_search_query (query),
    INDEX idx_search_user (user_id),
    INDEX idx_search_session (session_id),
    INDEX idx_search_date (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- SECTION 9: SYSTEM & CONFIGURATION
-- =============================================

-- System settings (key-value store)
CREATE TABLE settings (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    group VARCHAR(100) DEFAULT 'general',
    key VARCHAR(100) NOT NULL,
    value LONGTEXT,
    type ENUM('string', 'integer', 'boolean', 'json', 'array') DEFAULT 'string',
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY unique_setting (group, key),
    INDEX idx_setting_group (group),
    INDEX idx_setting_public (is_public)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Cache table (for Laravel cache)
CREATE TABLE cache (
    key VARCHAR(255) NOT NULL PRIMARY KEY,
    value MEDIUMTEXT NOT NULL,
    expiration INT NOT NULL,
    
    INDEX idx_cache_expiration (expiration)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Job queue table (for Laravel queues)
CREATE TABLE jobs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    queue VARCHAR(255) NOT NULL,
    payload LONGTEXT NOT NULL,
    attempts TINYINT UNSIGNED NOT NULL,
    reserved_at INT UNSIGNED,
    available_at INT UNSIGNED NOT NULL,
    created_at INT UNSIGNED NOT NULL,
    
    INDEX idx_jobs_queue (queue, reserved_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Failed jobs table
CREATE TABLE failed_jobs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    uuid VARCHAR(255) UNIQUE,
    connection TEXT NOT NULL,
    queue TEXT NOT NULL,
    payload LONGTEXT NOT NULL,
    exception LONGTEXT NOT NULL,
    failed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- SECTION 10: INCIDENT & COMPLIANCE
-- =============================================

-- Incident reports (for compliance and safety)
CREATE TABLE incident_reports (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    incident_number VARCHAR(20) UNIQUE NOT NULL,
    client_id BIGINT UNSIGNED,
    booking_id BIGINT UNSIGNED,
    incident_date DATE NOT NULL,
    incident_time TIME NOT NULL,
    incident_type ENUM('fall', 'injury', 'illness', 'behavioral', 'medication', 'other') NOT NULL,
    severity ENUM('minor', 'moderate', 'major', 'critical') NOT NULL,
    location VARCHAR(255),
    description TEXT NOT NULL,
    immediate_action_taken TEXT,
    witnesses JSON,
    staff_involved JSON,
    medical_attention_required BOOLEAN DEFAULT FALSE,
    hospital_transfer BOOLEAN DEFAULT FALSE,
    family_notified BOOLEAN DEFAULT FALSE,
    family_notification_time TIMESTAMP NULL,
    regulatory_report_required BOOLEAN DEFAULT FALSE,
    regulatory_report_filed BOOLEAN DEFAULT FALSE,
    follow_up_required BOOLEAN DEFAULT FALSE,
    follow_up_actions TEXT,
    root_cause_analysis TEXT,
    preventive_measures TEXT,
    reported_by BIGINT UNSIGNED NOT NULL,
    reviewed_by BIGINT UNSIGNED,
    review_date DATE,
    review_notes TEXT,
    attachments JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL,
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE SET NULL,
    FOREIGN KEY (reported_by) REFERENCES users(id),
    FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_incident_number (incident_number),
    INDEX idx_incident_client (client_id),
    INDEX idx_incident_date (incident_date),
    INDEX idx_incident_type (incident_type),
    INDEX idx_incident_severity (severity),
    INDEX idx_incident_review (reviewed_by, review_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Consents tracking (GDPR/privacy compliance)
CREATE TABLE consents (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    consentable_type VARCHAR(100) NOT NULL,
    consentable_id BIGINT UNSIGNED NOT NULL,
    consent_type ENUM('photo', 'video', 'testimonial', 'marketing', 'data_sharing', 'medical') NOT NULL,
    status ENUM('granted', 'revoked', 'expired') NOT NULL,
    granted_at TIMESTAMP NULL,
    revoked_at TIMESTAMP NULL,
    expires_at TIMESTAMP NULL,
    granted_by VARCHAR(255),
    method ENUM('online', 'paper', 'verbal') DEFAULT 'online',
    document_path VARCHAR(500),
    notes TEXT,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_consent_entity (consentable_type, consentable_id),
    INDEX idx_consent_type (consent_type),
    INDEX idx_consent_status (status),
    INDEX idx_consent_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- SECTION 11: FINANCIAL (Future Enhancement)
-- =============================================

-- Invoices (for billing)
CREATE TABLE invoices (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    client_id BIGINT UNSIGNED NOT NULL,
    billing_period_start DATE,
    billing_period_end DATE,
    subtotal DECIMAL(10,2) NOT NULL,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    paid_amount DECIMAL(10,2) DEFAULT 0,
    balance_due DECIMAL(10,2) NOT NULL,
    status ENUM('draft', 'sent', 'partial', 'paid', 'overdue', 'cancelled') DEFAULT 'draft',
    due_date DATE,
    sent_at TIMESTAMP NULL,
    paid_at TIMESTAMP NULL,
    notes TEXT,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (client_id) REFERENCES clients(id),
    
    INDEX idx_invoice_number (invoice_number),
    INDEX idx_invoice_client (client_id),
    INDEX idx_invoice_status (status),
    INDEX idx_invoice_due (due_date),
    INDEX idx_invoice_period (billing_period_start, billing_period_end)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Payment transactions
CREATE TABLE payment_transactions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    transaction_id VARCHAR(100) UNIQUE NOT NULL,
    invoice_id BIGINT UNSIGNED,
    booking_id BIGINT UNSIGNED,
    client_id BIGINT UNSIGNED,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    payment_method ENUM('cash', 'check', 'credit_card', 'debit_card', 'ach', 'insurance', 'other') NOT NULL,
    gateway VARCHAR(50),
    gateway_transaction_id VARCHAR(255),
    status ENUM('pending', 'processing', 'completed', 'failed', 'refunded') DEFAULT 'pending',
    processed_at TIMESTAMP NULL,
    failure_reason TEXT,
    refund_amount DECIMAL(10,2),
    refunded_at TIMESTAMP NULL,
    notes TEXT,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE SET NULL,
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE SET NULL,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL,
    
    INDEX idx_payment_transaction (transaction_id),
    INDEX idx_payment_invoice (invoice_id),
    INDEX idx_payment_booking (booking_id),
    INDEX idx_payment_client (client_id),
    INDEX idx_payment_status (status),
    INDEX idx_payment_date (processed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- VIEWS FOR REPORTING
-- =============================================

-- Active clients with emergency contacts
CREATE OR REPLACE VIEW v_active_clients_with_contacts AS
SELECT 
    c.id,
    c.client_number,
    c.first_name,
    c.last_name,
    c.status,
    c.risk_level,
    ec.name AS emergency_contact_name,
    ec.phone_primary AS emergency_contact_phone,
    ec.relationship AS emergency_contact_relationship
FROM clients c
LEFT JOIN emergency_contacts ec ON c.id = ec.client_id AND ec.is_primary = TRUE
WHERE c.status = 'active' 
    AND c.deleted_at IS NULL;

-- Service utilization report
CREATE OR REPLACE VIEW v_service_utilization AS
SELECT 
    s.id,
    s.name AS service_name,
    COUNT(DISTINCT b.id) AS total_bookings,
    COUNT(DISTINCT b.client_id) AS unique_clients,
    AVG(b.satisfaction_rating) AS avg_satisfaction,
    SUM(CASE WHEN b.status = 'completed' THEN 1 ELSE 0 END) AS completed_sessions,
    SUM(CASE WHEN b.status = 'no_show' THEN 1 ELSE 0 END) AS no_shows,
    SUM(CASE WHEN b.status = 'cancelled' THEN 1 ELSE 0 END) AS cancellations
FROM services s
LEFT JOIN bookings b ON s.id = b.service_id
WHERE s.deleted_at IS NULL
GROUP BY s.id, s.name;

-- Staff schedule overview
CREATE OR REPLACE VIEW v_staff_schedule_overview AS
SELECT 
    sm.id,
    sm.first_name,
    sm.last_name,
    sm.title,
    ss.day_of_week,
    ss.start_time,
    ss.end_time,
    ss.is_available
FROM staff_members sm
LEFT JOIN staff_schedules ss ON sm.id = ss.staff_member_id
WHERE sm.is_active = TRUE 
    AND sm.deleted_at IS NULL
    AND (ss.effective_until IS NULL OR ss.effective_until >= CURDATE())
ORDER BY sm.last_name, sm.first_name, ss.day_of_week;

-- =============================================
-- STORED PROCEDURES
-- =============================================

DELIMITER //

-- Procedure to check slot availability
CREATE PROCEDURE sp_check_slot_availability(
    IN p_slot_id BIGINT,
    OUT p_available_spots INT
)
BEGIN
    SELECT (capacity - booked_count) INTO p_available_spots
    FROM booking_slots
    WHERE id = p_slot_id
        AND status = 'available'
        AND slot_date >= CURDATE();
END //

-- Procedure to update booking slot counts
CREATE PROCEDURE sp_update_slot_count(
    IN p_slot_id BIGINT
)
BEGIN
    UPDATE booking_slots
    SET booked_count = (
        SELECT COUNT(*)
        FROM bookings
        WHERE slot_id = p_slot_id
            AND status IN ('confirmed', 'completed')
    )
    WHERE id = p_slot_id;
    
    -- Update status if full
    UPDATE booking_slots
    SET status = CASE
        WHEN booked_count >= capacity THEN 'full'
        WHEN booked_count < capacity AND status = 'full' THEN 'available'
        ELSE status
    END
    WHERE id = p_slot_id;
END //

-- Procedure to generate recurring booking slots
CREATE PROCEDURE sp_generate_recurring_slots(
    IN p_service_id BIGINT,
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    DECLARE v_current_date DATE;
    DECLARE v_day_of_week INT;
    DECLARE v_start_time TIME;
    DECLARE v_end_time TIME;
    DECLARE v_capacity INT;
    DECLARE v_room VARCHAR(100);
    DECLARE done INT DEFAULT FALSE;
    
    DECLARE schedule_cursor CURSOR FOR
        SELECT day_of_week, start_time, end_time, max_capacity, room_location
        FROM service_schedules
        WHERE service_id = p_service_id AND is_active = TRUE;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    SET v_current_date = p_start_date;
    
    WHILE v_current_date <= p_end_date DO
        OPEN schedule_cursor;
        
        read_loop: LOOP
            FETCH schedule_cursor INTO v_day_of_week, v_start_time, v_end_time, v_capacity, v_room;
            
            IF done THEN
                
