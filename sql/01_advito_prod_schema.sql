-- Advito Prod Database Schema
-- Models the primary Advito travel management application

-- Hotel properties dimension
CREATE TABLE hotels (
    hotel_id SERIAL PRIMARY KEY,
    property_name VARCHAR(200) NOT NULL,
    chain_code VARCHAR(10),
    chain_name VARCHAR(100),
    city VARCHAR(100) NOT NULL,
    state_province VARCHAR(100),
    country VARCHAR(3) NOT NULL,
    star_rating SMALLINT CHECK (star_rating BETWEEN 1 AND 5),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Corporate clients
CREATE TABLE clients (
    client_id SERIAL PRIMARY KEY,
    client_name VARCHAR(200) NOT NULL,
    industry VARCHAR(100),
    tier VARCHAR(20) DEFAULT 'standard',
    annual_travel_spend DECIMAL(15,2),
    contract_start DATE,
    contract_end DATE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Travelers (employees of corporate clients)
CREATE TABLE travelers (
    traveler_id SERIAL PRIMARY KEY,
    client_id INT REFERENCES clients(client_id),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    department VARCHAR(100),
    travel_tier VARCHAR(20) DEFAULT 'economy',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Hotel bookings
CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    traveler_id INT REFERENCES travelers(traveler_id),
    hotel_id INT REFERENCES hotels(hotel_id),
    client_id INT REFERENCES clients(client_id),
    check_in DATE NOT NULL,
    check_out DATE NOT NULL,
    room_nights INT GENERATED ALWAYS AS (check_out - check_in) STORED,
    rate_type VARCHAR(50),
    negotiated_rate DECIMAL(10,2),
    booked_rate DECIMAL(10,2),
    actual_rate DECIMAL(10,2),
    booking_channel VARCHAR(50),
    booking_status VARCHAR(20) DEFAULT 'confirmed',
    is_in_policy BOOLEAN DEFAULT TRUE,
    leakage_flag BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Rate programs (negotiated corporate rates)
CREATE TABLE rate_programs (
    program_id SERIAL PRIMARY KEY,
    client_id INT REFERENCES clients(client_id),
    hotel_id INT REFERENCES hotels(hotel_id),
    rate_code VARCHAR(20),
    negotiated_rate DECIMAL(10,2) NOT NULL,
    effective_start DATE NOT NULL,
    effective_end DATE NOT NULL,
    min_room_nights INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for common query patterns
CREATE INDEX idx_bookings_client ON bookings(client_id);
CREATE INDEX idx_bookings_hotel ON bookings(hotel_id);
CREATE INDEX idx_bookings_dates ON bookings(check_in, check_out);
CREATE INDEX idx_bookings_leakage ON bookings(leakage_flag) WHERE leakage_flag = TRUE;
CREATE INDEX idx_rate_programs_client ON rate_programs(client_id);
CREATE INDEX idx_rate_programs_dates ON rate_programs(effective_start, effective_end);
