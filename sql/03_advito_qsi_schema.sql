-- Advito QSI (Quality Score Index) Database Schema
-- Models the secondary analytics/benchmarking system
-- This is the DB that Advito uses FDW/dblink to query from prod

-- Market benchmark rates
CREATE TABLE market_rates (
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

-- Hotel quality scores
CREATE TABLE quality_scores (
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

-- City-level travel demand index
CREATE TABLE demand_index (
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

-- Supplier performance metrics
CREATE TABLE supplier_performance (
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
CREATE INDEX idx_market_rates_city ON market_rates(city, country, rate_date);
CREATE INDEX idx_quality_scores_chain ON quality_scores(hotel_chain, quarter);
CREATE INDEX idx_demand_index_city ON demand_index(city, country, month);
CREATE INDEX idx_supplier_perf_chain ON supplier_performance(chain_name, quarter);
