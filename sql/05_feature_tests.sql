-- Lakebase Feature Tests for Advito RDS Migration POC
-- Run against advito_prod database on production branch

-- TEST 1: postgres_fdw (Expected: FAIL - not supported)
-- CREATE EXTENSION postgres_fdw;
-- Result: ERROR - extension "postgres_fdw" is not available

-- TEST 2: dblink (Expected: FAIL - not supported)
-- CREATE EXTENSION dblink;
-- Result: ERROR - extension "dblink" is not available

-- TEST 3: Cross-database references (Expected: FAIL)
-- SELECT * FROM advito_qsi.public.market_rates LIMIT 1;
-- Result: ERROR - cross-database references are not implemented

-- TEST 4: PG Version
SELECT version();
-- Result: PostgreSQL 17.8

-- TEST 5: Available extensions (62 total)
SELECT name, default_version FROM pg_available_extensions ORDER BY name;

-- TEST 6: Schema evolution - JSONB column
ALTER TABLE hotels ADD COLUMN IF NOT EXISTS amenities JSONB DEFAULT '{}'::jsonb;
UPDATE hotels SET amenities = '{"wifi": true, "pool": true, "gym": true}'::jsonb WHERE star_rating >= 4;

-- TEST 7: pgvector
CREATE EXTENSION IF NOT EXISTS vector;
ALTER TABLE hotels ADD COLUMN IF NOT EXISTS description_embedding vector(3);

-- TEST 8: JSONB GIN index + query
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_hotels_amenities ON hotels USING gin(amenities);
SELECT property_name, amenities->'wifi' as has_wifi FROM hotels WHERE amenities @> '{"wifi": true}'::jsonb;

-- TEST 9: Trigram fuzzy search
CREATE INDEX IF NOT EXISTS idx_hotels_name_trgm ON hotels USING gin(property_name gin_trgm_ops);
SELECT property_name, similarity(property_name, 'Mariott') as sim FROM hotels WHERE property_name % 'Mariott';

-- TEST 10: Complex analytics - leakage analysis
SELECT
    c.client_name,
    count(*) FILTER (WHERE b.leakage_flag) as leakage_bookings,
    count(*) as total_bookings,
    ROUND(100.0 * count(*) FILTER (WHERE b.leakage_flag) / count(*), 1) as leakage_pct,
    ROUND(SUM(b.booked_rate * (b.check_out - b.check_in)) FILTER (WHERE b.leakage_flag), 2) as leakage_spend
FROM bookings b
JOIN clients c ON b.client_id = c.client_id
GROUP BY c.client_name
ORDER BY leakage_pct DESC;
