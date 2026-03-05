-- =============================================================
-- Schema Workaround: Single DB with Multiple Schemas
-- =============================================================
-- Problem: postgres_fdw and dblink are NOT available in Lakebase.
--          Cross-database references (db.schema.table) also fail.
--
-- Solution: Consolidate multiple databases into a SINGLE database
--           using separate schemas. This enables native SQL joins
--           across what were previously separate databases.
--
-- Before (RDS):   advito_prod DB  <--fdw/dblink-->  advito_qsi DB
-- After (Lakebase): advito_unified DB
--                     ├── prod schema  (was advito_prod)
--                     └── qsi schema   (was advito_qsi)
-- =============================================================

-- Create the unified database
CREATE DATABASE advito_unified;

-- Connect to advito_unified, then run:
-- \c advito_unified

-- =============================================================
-- PROD SCHEMA (was advito_prod database)
-- =============================================================
CREATE SCHEMA prod;

CREATE TABLE prod.hotels (
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

CREATE TABLE prod.clients (
    client_id SERIAL PRIMARY KEY,
    client_name VARCHAR(200) NOT NULL,
    industry VARCHAR(100),
    tier VARCHAR(20) DEFAULT 'standard',
    annual_travel_spend DECIMAL(15,2),
    contract_start DATE,
    contract_end DATE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE prod.travelers (
    traveler_id SERIAL PRIMARY KEY,
    client_id INT REFERENCES prod.clients(client_id),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    department VARCHAR(100),
    travel_tier VARCHAR(20) DEFAULT 'economy',
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE prod.bookings (
    booking_id SERIAL PRIMARY KEY,
    traveler_id INT REFERENCES prod.travelers(traveler_id),
    hotel_id INT REFERENCES prod.hotels(hotel_id),
    client_id INT REFERENCES prod.clients(client_id),
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

CREATE TABLE prod.rate_programs (
    program_id SERIAL PRIMARY KEY,
    client_id INT REFERENCES prod.clients(client_id),
    hotel_id INT REFERENCES prod.hotels(hotel_id),
    rate_code VARCHAR(20),
    negotiated_rate DECIMAL(10,2) NOT NULL,
    effective_start DATE NOT NULL,
    effective_end DATE NOT NULL,
    min_room_nights INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_prod_bookings_client ON prod.bookings(client_id);
CREATE INDEX idx_prod_bookings_hotel ON prod.bookings(hotel_id);
CREATE INDEX idx_prod_bookings_dates ON prod.bookings(check_in, check_out);
CREATE INDEX idx_prod_bookings_leakage ON prod.bookings(leakage_flag) WHERE leakage_flag = TRUE;

-- =============================================================
-- QSI SCHEMA (was advito_qsi database)
-- =============================================================
CREATE SCHEMA qsi;

CREATE TABLE qsi.market_rates (
    rate_id SERIAL PRIMARY KEY,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(3) NOT NULL,
    star_rating SMALLINT CHECK (star_rating BETWEEN 1 AND 5),
    rate_date DATE NOT NULL,
    avg_market_rate DECIMAL(10,2) NOT NULL,
    median_rate DECIMAL(10,2),
    p25_rate DECIMAL(10,2),
    p75_rate DECIMAL(10,2),
    sample_size INT,
    source VARCHAR(50) DEFAULT 'QSI',
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE qsi.quality_scores (
    score_id SERIAL PRIMARY KEY,
    hotel_chain VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(3) NOT NULL,
    quarter VARCHAR(7) NOT NULL,
    overall_score DECIMAL(4,2) CHECK (overall_score BETWEEN 0 AND 10),
    cleanliness_score DECIMAL(4,2),
    service_score DECIMAL(4,2),
    location_score DECIMAL(4,2),
    amenities_score DECIMAL(4,2),
    value_score DECIMAL(4,2),
    review_count INT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE qsi.demand_index (
    demand_id SERIAL PRIMARY KEY,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(3) NOT NULL,
    month DATE NOT NULL,
    demand_score DECIMAL(5,2),
    occupancy_pct DECIMAL(5,2),
    adr DECIMAL(10,2),
    revpar DECIMAL(10,2),
    yoy_change_pct DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE qsi.supplier_performance (
    perf_id SERIAL PRIMARY KEY,
    chain_name VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL,
    quarter VARCHAR(7) NOT NULL,
    avg_rate_compliance DECIMAL(5,2),
    avg_amenity_delivery DECIMAL(5,2),
    avg_response_time_hrs DECIMAL(5,2),
    complaint_rate DECIMAL(5,4),
    rebate_pct DECIMAL(5,2),
    total_room_nights INT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_qsi_market_rates_city ON qsi.market_rates(city, country, rate_date);
CREATE INDEX idx_qsi_quality_scores_chain ON qsi.quality_scores(hotel_chain, quarter);
CREATE INDEX idx_qsi_demand_city ON qsi.demand_index(city, country, month);
