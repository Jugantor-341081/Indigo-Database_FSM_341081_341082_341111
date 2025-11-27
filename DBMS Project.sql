-- ============================================================================
-- AIRLINE DATABASE SCHEMA (IndiGo-style Commercial Airline)
-- ============================================================================
-- Production-ready MySQL schema with optimization for scale
-- Author: Database Design Team
-- Date: 2025-11-27
-- ============================================================================

-- ============================================================================
-- 1. DEPARTMENTS & EMPLOYEES (CORE OPERATIONS)
-- ============================================================================
USE airline_db;

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE baggage;
TRUNCATE TABLE maintenance_records;
TRUNCATE TABLE crew_assignments;
TRUNCATE TABLE crew;
TRUNCATE TABLE crew_roles;
TRUNCATE TABLE tickets;
TRUNCATE TABLE bookings;
TRUNCATE TABLE passengers;
TRUNCATE TABLE flight_schedules;
TRUNCATE TABLE flights;
TRUNCATE TABLE routes;
TRUNCATE TABLE aircraft;
TRUNCATE TABLE aircraft_types;
TRUNCATE TABLE airports;
TRUNCATE TABLE employees;
TRUNCATE TABLE departments;

SET FOREIGN_KEY_CHECKS = 1;

CREATE DATABASE IF NOT EXISTS airline_db;
USE airline_db;

CREATE TABLE IF NOT EXISTS departments (
    department_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    department_code CHAR(3) NOT NULL UNIQUE,
    department_name VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS employees (
    employee_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    employee_code CHAR(6) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone CHAR(12),
    department_id INT UNSIGNED NOT NULL,
    designation VARCHAR(50) NOT NULL,
    hire_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_employee_department (department_id),
    INDEX idx_employee_active (is_active),
    CONSTRAINT fk_employee_department
        FOREIGN KEY (department_id) REFERENCES departments(department_id)
) ENGINE=InnoDB;

-- ============================================================================
-- 2. AIRPORTS (NETWORK NODES)
-- ============================================================================

CREATE TABLE IF NOT EXISTS airports (
    airport_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    iata_code CHAR(3) NOT NULL UNIQUE,
    icao_code CHAR(4),
    airport_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    country CHAR(2) NOT NULL,  -- ISO 3166-1 alpha-2
    timezone VARCHAR(30) NOT NULL,
    elevation_feet SMALLINT,
    is_hub BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_airport_city (city),
    INDEX idx_airport_hub (is_hub)
) ENGINE=InnoDB;

-- ============================================================================
-- 3. AIRCRAFT TYPES & FLEET
-- ============================================================================

CREATE TABLE IF NOT EXISTS aircraft_types (
    aircraft_type_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    aircraft_code CHAR(4) NOT NULL UNIQUE,
    manufacturer VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    max_capacity SMALLINT NOT NULL,
    cargo_capacity_kg INT,
    cruise_speed_kmh SMALLINT,
    range_km SMALLINT,
    fuel_capacity_liters INT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS aircraft (
    aircraft_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    registration CHAR(6) NOT NULL UNIQUE,
    aircraft_type_id INT UNSIGNED NOT NULL,
    manufacture_year SMALLINT,
    total_flight_hours INT DEFAULT 0,
    total_cycles INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    last_maintenance_date DATE,
    next_maintenance_due DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_aircraft_type (aircraft_type_id),
    INDEX idx_aircraft_active (is_active),
    INDEX idx_aircraft_maintenance (next_maintenance_due),
    CONSTRAINT fk_aircraft_type
        FOREIGN KEY (aircraft_type_id) REFERENCES aircraft_types(aircraft_type_id)
) ENGINE=InnoDB;

-- ============================================================================
-- 4. ROUTES & FLIGHTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS routes (
    route_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    origin_airport_id INT UNSIGNED NOT NULL,
    destination_airport_id INT UNSIGNED NOT NULL,
    distance_km SMALLINT NOT NULL,
    estimated_flight_time_minutes SMALLINT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(origin_airport_id, destination_airport_id),
    INDEX idx_route_origin (origin_airport_id),
    INDEX idx_route_destination (destination_airport_id),
    CONSTRAINT fk_route_origin
        FOREIGN KEY (origin_airport_id) REFERENCES airports(airport_id),
    CONSTRAINT fk_route_destination
        FOREIGN KEY (destination_airport_id) REFERENCES airports(airport_id),
    CONSTRAINT chk_route_origin_dest
        CHECK (origin_airport_id <> destination_airport_id)
) ENGINE=InnoDB;

-- Flight template (flight number definition)
CREATE TABLE IF NOT EXISTS flights (
    flight_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    flight_number CHAR(6) NOT NULL UNIQUE,
    route_id INT UNSIGNED NOT NULL,
    aircraft_type_id INT UNSIGNED NOT NULL,
    scheduled_departure_time TIME NOT NULL,
    scheduled_arrival_time TIME NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_flight_route (route_id),
    INDEX idx_flight_number (flight_number),
    CONSTRAINT fk_flight_route
        FOREIGN KEY (route_id) REFERENCES routes(route_id),
    CONSTRAINT fk_flight_aircraft_type
        FOREIGN KEY (aircraft_type_id) REFERENCES aircraft_types(aircraft_type_id)
) ENGINE=InnoDB;

-- Scheduled flight instances (actual occurrences)
CREATE TABLE IF NOT EXISTS flight_schedules (
    flight_schedule_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    flight_id INT UNSIGNED NOT NULL,
    aircraft_id INT UNSIGNED NOT NULL,
    flight_date DATE NOT NULL,
    scheduled_departure TIMESTAMP NOT NULL,
    scheduled_arrival TIMESTAMP NOT NULL,
    actual_departure TIMESTAMP NULL,
    actual_arrival TIMESTAMP NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED',  -- SCHEDULED, BOARDING, AIRBORNE, LANDED, CANCELLED, DELAYED
    total_capacity SMALLINT NOT NULL,
    available_seats SMALLINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE(flight_id, flight_date),
    INDEX idx_flight_schedule_date (flight_date),
    INDEX idx_flight_schedule_aircraft (aircraft_id),
    INDEX idx_flight_schedule_status (status),
    INDEX idx_flight_schedule_departure (scheduled_departure),
    CONSTRAINT fk_flight_schedule_flight
        FOREIGN KEY (flight_id) REFERENCES flights(flight_id),
    CONSTRAINT fk_flight_schedule_aircraft
        FOREIGN KEY (aircraft_id) REFERENCES aircraft(aircraft_id)
) ENGINE=InnoDB;

-- ============================================================================
-- 5. FARE CLASSES & PRICING
-- ============================================================================

CREATE TABLE IF NOT EXISTS fare_classes (
    fare_class_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    class_code CHAR(1) NOT NULL UNIQUE,
    class_name VARCHAR(30) NOT NULL,  -- ECONOMY, PREMIUM, BUSINESS, FIRST
    seat_pitch_inches SMALLINT,
    baggage_allowance_kg SMALLINT NOT NULL,
    meals_included BOOLEAN,
    priority_boarding BOOLEAN,
    seat_selection_allowed BOOLEAN,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================================
-- 6. PASSENGERS & BOOKINGS
-- ============================================================================

CREATE TABLE IF NOT EXISTS passengers (
    passenger_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(10),  -- MR, MRS, MS, DR, etc.
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE,
    gender CHAR(1),  -- M, F, O, U
    email VARCHAR(100),
    phone CHAR(12),
    passport_number VARCHAR(20) UNIQUE,
    nationality CHAR(2),  -- ISO 3166-1 alpha-2
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_passenger_email (email),
    INDEX idx_passenger_passport (passport_number)
) ENGINE=InnoDB;

-- PNR (Passenger Name Record)
CREATE TABLE IF NOT EXISTS bookings (
    booking_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    pnr_code CHAR(6) NOT NULL UNIQUE,
    passenger_id INT UNSIGNED NOT NULL,
    booking_date TIMESTAMP NOT NULL,
    booking_status VARCHAR(20) NOT NULL DEFAULT 'CONFIRMED',  -- CONFIRMED, CHECKED_IN, BOARDED, COMPLETED, CANCELLED
    total_fare DECIMAL(10, 2) NOT NULL,
    currency CHAR(3) DEFAULT 'INR',
    payment_method VARCHAR(20),  -- CREDIT_CARD, DEBIT_CARD, NET_BANKING, UPI, CASH
    payment_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- PENDING, COMPLETED, FAILED, REFUNDED
    special_requests TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE(passenger_id, pnr_code),
    INDEX idx_booking_pnr (pnr_code),
    INDEX idx_booking_passenger (passenger_id),
    INDEX idx_booking_status (booking_status),
    INDEX idx_booking_date (booking_date),
    CONSTRAINT fk_booking_passenger
        FOREIGN KEY (passenger_id) REFERENCES passengers(passenger_id)
) ENGINE=InnoDB;

-- ============================================================================
-- 7. TICKETS (BOOKING DETAILS)
-- ============================================================================

CREATE TABLE IF NOT EXISTS tickets (
    ticket_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id INT UNSIGNED NOT NULL,
    flight_schedule_id INT UNSIGNED NOT NULL,
    fare_class_id INT UNSIGNED NOT NULL,
    seat_number VARCHAR(5),  -- e.g., 12A, 34F
    ticket_status VARCHAR(20) NOT NULL DEFAULT 'ISSUED',  -- ISSUED, CHECKED_IN, BOARDED, USED, VOIDED
    base_fare DECIMAL(10, 2) NOT NULL,
    tax_amount DECIMAL(8, 2) DEFAULT 0,
    discount_amount DECIMAL(8, 2) DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL,
    baggage_weight_allowed_kg SMALLINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_ticket_booking (booking_id),
    INDEX idx_ticket_flight_schedule (flight_schedule_id),
    INDEX idx_ticket_status (ticket_status),
    INDEX idx_ticket_seat (flight_schedule_id, seat_number),
    CONSTRAINT fk_ticket_booking
        FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE,
    CONSTRAINT fk_ticket_flight_schedule
        FOREIGN KEY (flight_schedule_id) REFERENCES flight_schedules(flight_schedule_id),
    CONSTRAINT fk_ticket_fare_class
        FOREIGN KEY (fare_class_id) REFERENCES fare_classes(fare_class_id)
) ENGINE=InnoDB;

-- ============================================================================
-- 8. BAGGAGE
-- ============================================================================

CREATE TABLE IF NOT EXISTS baggage (
    baggage_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ticket_id INT UNSIGNED NOT NULL,
    baggage_tag_number CHAR(13) NOT NULL UNIQUE,
    weight_kg DECIMAL(5, 2) NOT NULL,
    baggage_type VARCHAR(20),  -- CHECKED, CARRY_ON, PERSONAL
    status VARCHAR(20) NOT NULL DEFAULT 'REGISTERED',  -- REGISTERED, TAGGED, LOADED, UNLOADED, DELIVERED, LOST
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_baggage_ticket (ticket_id),
    INDEX idx_baggage_tag (baggage_tag_number),
    INDEX idx_baggage_status (status),
    CONSTRAINT fk_baggage_ticket
        FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- 9. CREW & CREW ASSIGNMENTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS crew_roles (
    crew_role_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_code CHAR(3) NOT NULL UNIQUE,
    role_name VARCHAR(30) NOT NULL,  -- PILOT, COPILOT, FLIGHT_ATTENDANT, etc.
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Crew members (can be different from general employees)
CREATE TABLE IF NOT EXISTS crew (
    crew_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    employee_id INT UNSIGNED NOT NULL,
    crew_role_id INT UNSIGNED NOT NULL,
    license_number VARCHAR(30),
    license_expiry_date DATE,
    certifications TEXT,
    total_flight_hours INT DEFAULT 0,
    is_current BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(employee_id, crew_role_id),
    INDEX idx_crew_employee (employee_id),
    INDEX idx_crew_role (crew_role_id),
    INDEX idx_crew_license_expiry (license_expiry_date),
    CONSTRAINT fk_crew_employee
        FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    CONSTRAINT fk_crew_role
        FOREIGN KEY (crew_role_id) REFERENCES crew_roles(crew_role_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS crew_assignments (
    crew_assignment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    flight_schedule_id INT UNSIGNED NOT NULL,
    crew_id INT UNSIGNED NOT NULL,
    crew_role_id INT UNSIGNED NOT NULL,
    assigned_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(flight_schedule_id, crew_id),
    INDEX idx_crew_assignment_flight (flight_schedule_id),
    INDEX idx_crew_assignment_crew (crew_id),
    CONSTRAINT fk_crew_assignment_flight
        FOREIGN KEY (flight_schedule_id) REFERENCES flight_schedules(flight_schedule_id),
    CONSTRAINT fk_crew_assignment_crew
        FOREIGN KEY (crew_id) REFERENCES crew(crew_id),
    CONSTRAINT fk_crew_assignment_role
        FOREIGN KEY (crew_role_id) REFERENCES crew_roles(crew_role_id)
) ENGINE=InnoDB;

-- ============================================================================
-- 10. MAINTENANCE RECORDS
-- ============================================================================

CREATE TABLE IF NOT EXISTS maintenance_records (
    maintenance_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    aircraft_id INT UNSIGNED NOT NULL,
    maintenance_type VARCHAR(30) NOT NULL,  -- SCHEDULED, UNSCHEDULED, INSPECTION, REPAIR
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP,
    technician_id INT UNSIGNED,
    description TEXT NOT NULL,
    parts_replaced TEXT,
    cost_amount DECIMAL(12, 2),
    status VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS',  -- IN_PROGRESS, COMPLETED, FAILED
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_maintenance_aircraft (aircraft_id),
    INDEX idx_maintenance_date (start_date),
    INDEX idx_maintenance_status (status),
    INDEX idx_maintenance_type (maintenance_type),
    CONSTRAINT fk_maintenance_aircraft
        FOREIGN KEY (aircraft_id) REFERENCES aircraft(aircraft_id),
    CONSTRAINT fk_maintenance_technician
        FOREIGN KEY (technician_id) REFERENCES employees(employee_id)
) ENGINE=InnoDB;

-- ============================================================================
-- 11. AUDIT LOG
-- ============================================================================

CREATE TABLE IF NOT EXISTS audit_log (
    audit_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INT,
    operation VARCHAR(10) NOT NULL,  -- INSERT, UPDATE, DELETE
    old_values JSON,
    new_values JSON,
    user_id INT UNSIGNED,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    INDEX idx_audit_table (table_name),
    INDEX idx_audit_timestamp (changed_at),
    INDEX idx_audit_operation (operation),
    CONSTRAINT fk_audit_user
        FOREIGN KEY (user_id) REFERENCES employees(employee_id)
) ENGINE=InnoDB;

-- ============================================================================
-- 12. INDEXES FOR PERFORMANCE (ADDITIONAL) - SAFE CREATION
-- ============================================================================

-- idx_tickets_flight_fare
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'tickets'
      AND index_name = 'idx_tickets_flight_fare'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_tickets_flight_fare ON tickets(flight_schedule_id, fare_class_id)',
    'SELECT ''idx_tickets_flight_fare already exists''');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- idx_bookings_date_status
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'bookings'
      AND index_name = 'idx_bookings_date_status'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_bookings_date_status ON bookings(booking_date, booking_status)',
    'SELECT ''idx_bookings_date_status already exists''');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- idx_flight_schedules_date_status
SET @idx_exists := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'flight_schedules'
      AND index_name = 'idx_flight_schedules_date_status'
);
SET @sql := IF(
    @idx_exists = 0,
    'CREATE INDEX idx_flight_schedules_date_status ON flight_schedules(flight_date, status)',
    'SELECT ''idx_flight_schedules_date_status already exists''');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================================================
-- SAMPLE DATA (DML) - AIRLINE DATABASE
-- ============================================================================

-- 1. DEPARTMENTS
INSERT IGNORE INTO departments (department_code, department_name, description) VALUES
('OPS', 'Operations', 'Flight operations and scheduling'),
('MNT', 'Maintenance', 'Aircraft maintenance and engineering'),
('CRW', 'Crew', 'Pilot and flight attendant management'),
('CSR', 'Customer Service', 'Passenger services and reservations'),
('FIN', 'Finance', 'Finance and accounting'),
('MKT', 'Marketing', 'Marketing and customer acquisition'),
('IT',  'Information Technology', 'IT systems and support');

-- 2. EMPLOYEES
INSERT IGNORE INTO employees
(employee_code, first_name, last_name, email, phone, department_id, designation, hire_date, is_active) VALUES
('EMP001', 'Rajesh', 'Kumar', 'rajesh.kumar@indigo.co.in', '9876543210', 1, 'Operations Manager', '2020-01-15', TRUE),
('EMP002', 'Priya',  'Sharma','priya.sharma@indigo.co.in',  '9876543211', 2, 'Maintenance Manager', '2019-06-01', TRUE),
('EMP003', 'Amit',   'Singh', 'amit.singh@indigo.co.in',   '9876543212', 3, 'Crew Scheduling Manager', '2021-03-10', TRUE),
('EMP004', 'Sneha',  'Patel', 'sneha.patel@indigo.co.in',  '9876543213', 4, 'Customer Service Executive', '2022-01-20', TRUE),
('EMP005', 'Captain','Vikram Malhotra','vikram.malhotra@indigo.co.in','9876543214',3,'Senior Pilot','2015-11-01',TRUE),
('EMP006', 'Captain','Neha Gupta','neha.gupta@indigo.co.in','9876543215',3,'Pilot','2018-04-15',TRUE),
('EMP007', 'Flight', 'Attendant Zara','zara.khan@indigo.co.in','9876543216',3,'Flight Attendant','2021-07-01',TRUE);

-- 3. AIRPORTS
INSERT IGNORE INTO airports
(iata_code, icao_code, airport_name, city, country, timezone, elevation_feet, is_hub) VALUES
('DEL', 'VIDP', 'Indira Gandhi International Airport', 'Delhi',    'IN', 'Asia/Kolkata', 777,  TRUE),
('BOM', 'VABB', 'Bombay High International Airport',   'Mumbai',   'IN', 'Asia/Kolkata', 40,   TRUE),
('BLR', 'VOBL', 'Kempegowda International Airport',    'Bangalore','IN', 'Asia/Kolkata', 2848, TRUE),
('HYD', 'VOHS', 'Rajiv Gandhi International Airport',  'Hyderabad','IN', 'Asia/Kolkata', 1714, FALSE),
('CCU', 'VECC', 'Netaji Subhas Chandra Bose International Airport','Kolkata','IN','Asia/Kolkata',21,FALSE),
('MAA', 'VOMM', 'Chennai International Airport',       'Chennai',  'IN', 'Asia/Kolkata', 52,   FALSE);

-- 4. AIRCRAFT TYPES
INSERT IGNORE INTO aircraft_types
(aircraft_code, manufacturer, model, max_capacity, cargo_capacity_kg, cruise_speed_kmh, range_km, fuel_capacity_liters) VALUES
('A320','Airbus', 'A320-200', 180, 8000, 840, 5950, 27000),
('A321','Airbus', 'A321-200', 220, 9000, 840, 6150, 32000),
('B738','Boeing', '737-800',  189, 8000, 910, 5400, 26730),
('B789','Boeing', '787-9',    296,21000, 913,13650,126372),
('E190','Embraer','E190-E2',  146, 4500, 825, 4815, 19200);

-- 5. AIRCRAFT (FLEET)
INSERT IGNORE INTO aircraft
(registration, aircraft_type_id, manufacture_year, total_flight_hours, total_cycles, is_active, last_maintenance_date, next_maintenance_due) VALUES
('VT-IJA', 1, 2018, 25000, 8500, TRUE, '2025-11-20', '2026-02-15'),
('VT-IJB', 1, 2019, 22000, 7800, TRUE, '2025-11-10', '2026-01-20'),
('VT-IJC', 2, 2020, 18000, 6200, TRUE, '2025-10-25', '2026-03-10'),
('VT-IJD', 3, 2017, 28000, 9200, TRUE, '2025-11-15', '2026-04-30'),
('VT-IJE', 4, 2021, 15000, 4500, TRUE, '2025-11-01', '2026-05-20'),
('VT-IJF', 5, 2022,  8000, 2800, TRUE, '2025-10-30', '2026-06-15');

-- 6. ROUTES
INSERT IGNORE INTO routes
(origin_airport_id, destination_airport_id, distance_km, estimated_flight_time_minutes) VALUES
(1, 2,  888, 120),  -- DEL -> BOM
(2, 3,  855, 115),  -- BOM -> BLR
(1, 3, 2153, 180),  -- DEL -> BLR
(1, 4, 1702, 150),  -- DEL -> HYD
(2, 4,  750, 100),  -- BOM -> HYD
(1, 5, 1473, 150),  -- DEL -> CCU
(3, 6,  345,  60),  -- BLR -> MAA
(1, 6, 2186, 195),  -- DEL -> MAA
(5, 2, 2063, 180),  -- CCU -> BOM
(4, 3,  710,  95);  -- HYD -> BLR

-- 7. FLIGHTS (FLIGHT TEMPLATES)
INSERT IGNORE INTO flights
(flight_number, route_id, aircraft_type_id, scheduled_departure_time, scheduled_arrival_time, is_active) VALUES
('6E101', 1, 1, '06:00:00', '07:40:00', TRUE),
('6E201', 1, 2, '14:30:00', '16:10:00', TRUE),
('6E301', 2, 1, '07:00:00', '08:55:00', TRUE),
('6E103', 3, 2, '09:00:00', '12:00:00', TRUE),
('6E104', 4, 3, '11:00:00', '13:30:00', TRUE),
('6E105', 5, 1, '13:00:00', '14:40:00', TRUE),
('6E107', 6, 1, '08:30:00', '10:20:00', TRUE),
('6E108', 7, 2, '15:00:00', '16:00:00', TRUE),
('6E109', 8, 3, '10:00:00', '13:15:00', TRUE),
('6E110',10, 1, '12:00:00', '13:35:00', TRUE);

-- 8. FLIGHT SCHEDULES (SCHEDULED INSTANCES - NEXT 30 DAYS)
INSERT IGNORE INTO flight_schedules
(flight_id, aircraft_id, flight_date, scheduled_departure, scheduled_arrival, status, total_capacity, available_seats) VALUES
-- November 27 flights
(1, 1, '2025-11-27', '2025-11-27 06:00:00', '2025-11-27 07:40:00', 'SCHEDULED', 180, 35),
(2, 3, '2025-11-27', '2025-11-27 14:30:00', '2025-11-27 16:10:00', 'SCHEDULED', 220, 68),
(3, 2, '2025-11-27', '2025-11-27 07:00:00', '2025-11-27 08:55:00', 'SCHEDULED', 180, 42),
(4, 5, '2025-11-27', '2025-11-27 09:00:00', '2025-11-27 12:00:00', 'SCHEDULED', 296, 95),
(5, 4, '2025-11-27', '2025-11-27 11:00:00', '2025-11-27 13:30:00', 'SCHEDULED', 189, 51),
-- November 28 flights
(1, 2, '2025-11-28', '2025-11-28 06:00:00', '2025-11-28 07:40:00', 'SCHEDULED', 180, 28),
(2, 1, '2025-11-28', '2025-11-28 14:30:00', '2025-11-28 16:10:00', 'SCHEDULED', 220, 72),
(3, 3, '2025-11-28', '2025-11-28 07:00:00', '2025-11-28 08:55:00', 'SCHEDULED', 180, 55),
-- November 29 flights
(1, 4, '2025-11-29', '2025-11-29 06:00:00', '2025-11-29 07:40:00', 'SCHEDULED', 189, 38),
(5, 2, '2025-11-29', '2025-11-29 11:00:00', '2025-11-29 13:30:00', 'SCHEDULED', 180, 44),
(6, 1, '2025-11-29', '2025-11-29 13:00:00', '2025-11-29 14:40:00', 'SCHEDULED', 180, 62),
(7, 3, '2025-11-29', '2025-11-29 08:30:00', '2025-11-29 10:20:00', 'SCHEDULED', 220, 88),
(8, 5, '2025-11-29', '2025-11-29 15:00:00', '2025-11-29 16:00:00', 'SCHEDULED', 296,110);

-- 9. FARE CLASSES
INSERT IGNORE INTO fare_classes
(class_code, class_name, seat_pitch_inches, baggage_allowance_kg, meals_included,
 priority_boarding, seat_selection_allowed) VALUES
('E', 'Economy',         31, 15, FALSE, FALSE, FALSE),
('P', 'Premium Economy', 34, 20, TRUE,  TRUE,  TRUE),
('B', 'Business',        38, 30, TRUE,  TRUE,  TRUE),
('F', 'First',           40, 40, TRUE,  TRUE,  TRUE);

-- 10. PASSENGERS
INSERT IGNORE INTO passengers
(title, first_name, last_name, date_of_birth, gender, email, phone,
 passport_number, nationality, is_active) VALUES
('Mr', 'Arjun',  'Verma',   '1990-05-15', 'M', 'arjun.verma@email.com',  '9998765432', 'K5789012', 'IN', TRUE),
('Ms', 'Deepika','Iyer',    '1988-03-22', 'F', 'deepika.iyer@email.com','9998765433', 'L2345678', 'IN', TRUE),
('Mr', 'Rohan',  'Desai',   '1995-11-10', 'M', 'rohan.desai@email.com', '9998765434', 'M1234567', 'IN', TRUE),
('Dr', 'Meera',  'Bansal',  '1985-07-18', 'F', 'meera.bansal@email.com','9998765435', 'N9876543', 'IN', TRUE),
('Mr', 'Karan',  'Chopra',  '1992-02-28', 'M', 'karan.chopra@email.com','9998765436', 'O3456789', 'IN', TRUE),
('Ms', 'Neha',   'Saxena',  '1991-09-05', 'F', 'neha.saxena@email.com', '9998765437', 'P5678901', 'IN', TRUE),
('Mr', 'Aditya', 'Malhotra','1987-12-12', 'M', 'aditya.malhotra@email.com','9998765438','Q7890123','IN', TRUE),
('Ms', 'Shruti', 'Gupta',   '1993-04-30', 'F', 'shruti.gupta@email.com','9998765439', 'R2345678','IN', TRUE),
('Mr', 'Vikram', 'Patel',   '1994-08-14', 'M', 'vikram.patel@email.com','9998765440', 'S1234567','IN', TRUE),
('Ms', 'Priya',  'Nair',    '1989-06-25', 'F', 'priya.nair@email.com',  '9998765441', 'T8901234','IN', TRUE);

-- 11. BOOKINGS (PNRs)
INSERT IGNORE INTO bookings
(pnr_code, passenger_id, booking_date, booking_status, total_fare, currency,
 payment_method, payment_status) VALUES
('ABC123', 1, '2025-11-25 10:30:00', 'CONFIRMED', 4500.00, 'INR', 'CREDIT_CARD', 'COMPLETED'),
('ABC124', 2, '2025-11-25 11:15:00', 'CONFIRMED', 5200.00, 'INR', 'DEBIT_CARD',  'COMPLETED'),
('ABC125', 3, '2025-11-25 14:45:00', 'CONFIRMED', 6800.00, 'INR', 'NET_BANKING', 'COMPLETED'),
('ABC126', 4, '2025-11-26 09:20:00', 'CONFIRMED', 7500.00, 'INR', 'CREDIT_CARD', 'COMPLETED'),
('ABC127', 5, '2025-11-26 13:50:00', 'CONFIRMED', 8200.00, 'INR', 'UPI',         'COMPLETED'),
('ABC128', 6, '2025-11-26 15:30:00', 'CONFIRMED', 4200.00, 'INR', 'CREDIT_CARD', 'COMPLETED'),
('ABC129', 7, '2025-11-27 08:10:00', 'CONFIRMED', 5800.00, 'INR', 'DEBIT_CARD',  'COMPLETED'),
('ABC130', 8, '2025-11-27 10:45:00', 'CONFIRMED', 6500.00, 'INR', 'NET_BANKING', 'COMPLETED'),
('ABC131', 9, '2025-11-27 12:20:00', 'CONFIRMED', 7200.00, 'INR', 'CREDIT_CARD', 'COMPLETED'),
('ABC132',10,'2025-11-27 14:55:00', 'CONFIRMED', 8900.00, 'INR', 'UPI',         'COMPLETED');

-- 12. TICKETS
INSERT IGNORE INTO tickets
(booking_id, flight_schedule_id, fare_class_id, seat_number, ticket_status,
 base_fare, tax_amount, discount_amount, total_amount, baggage_weight_allowed_kg) VALUES
(1, 1, 1, '12A', 'ISSUED', 4000.00,  500.00,   0.00, 4500.00, 15),
(2, 1, 2, '5C',  'ISSUED', 4800.00,  600.00, 200.00, 5200.00, 20),
(3, 2, 1, '22B', 'ISSUED', 6000.00,  800.00,   0.00, 6800.00, 15),
(4, 2, 3, '3A',  'ISSUED', 6800.00,  900.00, 200.00, 7500.00, 30),
(5, 3, 2, '18F', 'ISSUED', 7500.00, 1000.00, 300.00, 8200.00, 20),
(6, 3, 1, '32E', 'ISSUED', 3800.00,  500.00, 100.00, 4200.00, 15),
(7, 4, 1, '45D', 'ISSUED', 5200.00,  650.00,  50.00, 5800.00, 15),
(8, 4, 2, '15G', 'ISSUED', 5900.00,  750.00, 150.00, 6500.00, 20),
(9, 5, 1, '28C', 'ISSUED', 6500.00,  850.00, 150.00, 7200.00, 15),
(10,5, 3, '8B',  'ISSUED', 8000.00, 1100.00, 200.00, 8900.00, 30);

-- 13. CREW ROLES
INSERT IGNORE INTO crew_roles (role_code, role_name, description) VALUES
('CPT', 'Captain',          'Senior Pilot'),
('FO',  'First Officer',    'Co-Pilot'),
('FS',  'Flight Supervisor','Flight Attendant Supervisor'),
('FA',  'Flight Attendant', 'Cabin Crew Member');

-- 14. CREW
INSERT IGNORE INTO crew
(employee_id, crew_role_id, license_number, license_expiry_date, total_flight_hours, is_current) VALUES
(5, 1, 'ATPL-2015-001', '2026-12-31', 12000, TRUE),
(6, 2, 'CPL-2018-045',  '2027-06-30',  4500, TRUE),
(7, 4, 'FA-LIC-2021-156','2025-12-15',  800, TRUE);

-- 15. CREW ASSIGNMENTS
INSERT IGNORE INTO crew_assignments
(flight_schedule_id, crew_id, crew_role_id, is_active) VALUES
(1, 1, 1, TRUE),   -- Captain on flight 1
(1, 2, 2, TRUE),   -- First Officer on flight 1
(1, 3, 4, TRUE),   -- Flight Attendant on flight 1
(2, 1, 1, TRUE),   -- Captain on flight 2
(2, 2, 2, TRUE),   -- First Officer on flight 2
(3, 2, 1, TRUE),   -- Captain on flight 3
(4, 1, 1, TRUE),   -- Captain on flight 4
(5, 1, 1, TRUE);   -- Captain on flight 5

-- 16. MAINTENANCE RECORDS
INSERT IGNORE INTO maintenance_records
(aircraft_id, maintenance_type, start_date, end_date, technician_id,
 description, parts_replaced, cost_amount, status) VALUES
(1, 'SCHEDULED', '2025-11-20 08:00:00', '2025-11-20 16:30:00', 2,
 'C-Check (500 flight hours)', 'Air filters, engine oil',  45000.00, 'COMPLETED'),
(2, 'INSPECTION','2025-11-15 10:00:00', '2025-11-15 14:00:00', 2,
 'Pre-flight inspection',       'None',                     5000.00, 'COMPLETED'),
(3, 'UNSCHEDULED','2025-11-10 09:00:00','2025-11-10 17:00:00', 2,
 'Repair: Hydraulic leak',      'Hydraulic pump assembly', 75000.00, 'COMPLETED'),
(4, 'SCHEDULED','2025-10-25 08:00:00', '2025-10-30 16:00:00', 2,
 'D-Check (2000 flight hours)', 'Engine overhaul, landing gear service', 850000.00,'COMPLETED'),
(5, 'INSPECTION','2025-11-01 10:00:00', '2025-11-01 12:00:00', 2,
 'Post-flight walk-around',     'None',                     2500.00, 'COMPLETED'),
(6, 'SCHEDULED','2025-10-30 09:00:00', '2025-11-02 16:00:00', 2,
 'A-Check (200 flight hours)',  'Filters, fluids, belts',  15000.00, 'COMPLETED');

-- 17. BAGGAGE
INSERT IGNORE INTO baggage
(ticket_id, baggage_tag_number, weight_kg, baggage_type, status) VALUES
(1,  '6E101-001-BLR', 18.5, 'CHECKED', 'DELIVERED'),
(2,  '6E101-002-BLR', 22.0, 'CHECKED', 'DELIVERED'),
(3,  '6E102-001-DEL', 15.5, 'CHECKED', 'REGISTERED'),
(4,  '6E102-002-DEL', 28.0, 'CHECKED', 'REGISTERED'),
(5,  '6E103-001-BOM', 20.0, 'CHECKED', 'TAGGED'),
(6,  '6E103-002-BOM', 17.5, 'CHECKED', 'TAGGED'),
(7,  '6E201-001-HYD', 19.0, 'CHECKED', 'REGISTERED'),
(8,  '6E201-002-HYD', 24.5, 'CHECKED', 'REGISTERED'),
(9,  '6E301-001-MAA', 16.0, 'CHECKED', 'DELIVERED'),
(10, '6E301-002-MAA', 25.0, 'CHECKED', 'DELIVERED');

-- ============================================================================
-- OPERATIONAL REPORTS & QUERIES
-- ============================================================================

-- REPORT 1: DAILY FLIGHT MANIFEST (PASSENGERS PER FLIGHT)
SELECT
    fs.flight_schedule_id,
    f.flight_number,
    CONCAT(ap_origin.iata_code, ' → ', ap_dest.iata_code) AS route,
    fs.flight_date AS flight_date,
    fs.scheduled_departure AS departure_time,
    COUNT(t.ticket_id) AS total_passengers,
    fs.total_capacity,
    (fs.total_capacity - COUNT(t.ticket_id)) AS available_seats,
    ROUND(100.0 * COUNT(t.ticket_id) / fs.total_capacity, 2) AS load_factor_pct,
    GROUP_CONCAT(DISTINCT fc.class_name ORDER BY fc.class_name SEPARATOR ', ') AS fare_classes_booked
FROM
    flight_schedules fs
    INNER JOIN flights f ON fs.flight_id = f.flight_id
    INNER JOIN routes r ON f.route_id = r.route_id
    INNER JOIN airports ap_origin ON r.origin_airport_id = ap_origin.airport_id
    INNER JOIN airports ap_dest ON r.destination_airport_id = ap_dest.airport_id
    LEFT JOIN tickets t
        ON fs.flight_schedule_id = t.flight_schedule_id
       AND t.ticket_status <> 'VOIDED'
    LEFT JOIN fare_classes fc ON t.fare_class_id = fc.fare_class_id
WHERE
    fs.flight_date = CURRENT_DATE
    AND fs.status NOT IN ('CANCELLED', 'VOIDED')
GROUP BY
    fs.flight_schedule_id,
    f.flight_number,
    fs.flight_date,
    fs.scheduled_departure,
    ap_origin.iata_code,
    ap_dest.iata_code,
    fs.total_capacity
ORDER BY
    fs.scheduled_departure;

-- REPORT 2: LOAD FACTOR PER FLIGHT (CAPACITY UTILIZATION)
SELECT
    f.flight_number,
    CONCAT(ap_origin.iata_code, ' → ', ap_dest.iata_code) AS route,
    fs.flight_date AS flight_date,
    ac.registration AS aircraft_reg,
    at.model,
    fs.total_capacity,
    COUNT(DISTINCT t.ticket_id) AS passengers_booked,
    ROUND(100.0 * COUNT(DISTINCT t.ticket_id) / fs.total_capacity, 2) AS load_factor_pct,
    SUM(t.total_amount) AS revenue_generated,
    ROUND(SUM(t.total_amount) / NULLIF(COUNT(DISTINCT t.ticket_id), 0), 2) AS avg_fare_per_passenger,
    fs.status AS flight_status
FROM
    flight_schedules fs
    INNER JOIN flights f ON fs.flight_id = f.flight_id
    INNER JOIN aircraft ac ON fs.aircraft_id = ac.aircraft_id
    INNER JOIN aircraft_types at ON ac.aircraft_type_id = at.aircraft_type_id
    INNER JOIN routes r ON f.route_id = r.route_id
    INNER JOIN airports ap_origin ON r.origin_airport_id = ap_origin.airport_id
    INNER JOIN airports ap_dest ON r.destination_airport_id = ap_dest.airport_id
    LEFT JOIN tickets t
        ON fs.flight_schedule_id = t.flight_schedule_id
       AND t.ticket_status IN ('ISSUED', 'CHECKED_IN', 'BOARDED', 'USED')
WHERE
    fs.flight_date BETWEEN (CURRENT_DATE - INTERVAL 7 DAY) AND CURRENT_DATE
GROUP BY
    f.flight_number,
    fs.flight_date,
    ac.registration,
    at.model,
    fs.total_capacity,
    fs.status,
    ap_origin.iata_code,
    ap_dest.iata_code,
    fs.flight_schedule_id
ORDER BY
    fs.flight_date DESC,
    load_factor_pct DESC;

-- REPORT 3: UPCOMING MAINTENANCE DUE FOR EACH AIRCRAFT
SELECT
    ac.aircraft_id,
    ac.registration,
    CONCAT(at.manufacturer, ' ', at.model) AS aircraft_model,
    ac.total_flight_hours,
    ac.manufacture_year,
    ac.last_maintenance_date,
    ac.next_maintenance_due,
    CASE
        WHEN ac.next_maintenance_due <= CURRENT_DATE THEN 'OVERDUE'
        WHEN ac.next_maintenance_due <= CURRENT_DATE + INTERVAL 7 DAY THEN 'DUE WITHIN WEEK'
        WHEN ac.next_maintenance_due <= CURRENT_DATE + INTERVAL 30 DAY THEN 'DUE WITHIN MONTH'
        ELSE 'SCHEDULED'
    END AS maintenance_status,
    DATEDIFF(ac.next_maintenance_due, CURRENT_DATE) AS days_until_maintenance,
    ac.is_active,
    COUNT(DISTINCT fs.flight_schedule_id) AS flights_scheduled_next_7_days
FROM
    aircraft ac
    INNER JOIN aircraft_types at ON ac.aircraft_type_id = at.aircraft_type_id
    LEFT JOIN flight_schedules fs
        ON ac.aircraft_id = fs.aircraft_id
       AND fs.flight_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL 7 DAY
       AND fs.status NOT IN ('CANCELLED', 'VOIDED')
WHERE
    ac.is_active = TRUE
GROUP BY
    ac.aircraft_id,
    ac.registration,
    at.manufacturer,
    at.model,
    ac.total_flight_hours,
    ac.manufacture_year,
    ac.last_maintenance_date,
    ac.next_maintenance_due,
    ac.is_active
ORDER BY
    ac.next_maintenance_due ASC,
    maintenance_status ASC;

-- REPORT 4: REVENUE PER ROUTE PER MONTH
SELECT
    YEAR(fs.flight_date) AS year,
    MONTH(fs.flight_date) AS month,
    DATE_FORMAT(fs.flight_date, '%Y-%m') AS `year_month`,
    CONCAT(ap_origin.iata_code, ' → ', ap_dest.iata_code) AS route,
    r.distance_km,
    COUNT(DISTINCT fs.flight_schedule_id) AS flights_operated,
    COUNT(DISTINCT t.ticket_id) AS total_tickets_sold,
    SUM(fs.total_capacity) AS total_seat_capacity,
    COUNT(DISTINCT t.ticket_id) * 100.0 / NULLIF(SUM(fs.total_capacity), 0) AS avg_load_factor_pct,
    SUM(t.base_fare) AS base_fare_revenue,
    SUM(t.tax_amount) AS tax_revenue,
    SUM(t.discount_amount) AS total_discounts,
    SUM(t.total_amount) AS total_revenue,
    ROUND(SUM(t.total_amount) / NULLIF(COUNT(DISTINCT t.ticket_id), 0), 2) AS avg_fare_per_ticket
FROM flight_schedules fs
INNER JOIN flights f ON fs.flight_id = f.flight_id
INNER JOIN routes r ON f.route_id = r.route_id
INNER JOIN airports ap_origin ON r.origin_airport_id = ap_origin.airport_id
INNER JOIN airports ap_dest ON r.destination_airport_id = ap_dest.airport_id
LEFT JOIN tickets t
    ON fs.flight_schedule_id = t.flight_schedule_id
   AND t.ticket_status IN ('ISSUED', 'CHECKED_IN', 'BOARDED', 'USED')
WHERE
    fs.flight_date >= DATE_SUB(CURRENT_DATE, INTERVAL 3 MONTH)
    AND fs.status NOT IN ('CANCELLED', 'VOIDED')
GROUP BY
    YEAR(fs.flight_date),
    MONTH(fs.flight_date),
	DATE_FORMAT(fs.flight_date, '%Y-%m'),
    ap_origin.iata_code,
    ap_dest.iata_code,
    r.distance_km,
    r.route_id
ORDER BY
    year DESC,
    month DESC,
    total_revenue DESC;

/* 
(Your scaling recommendations, ER diagram, and schema overview comments can
stay exactly as you had them here.)
*/
