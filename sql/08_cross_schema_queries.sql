-- =============================================================
-- Cross-Schema Queries: FDW Replacement Demo
-- =============================================================
-- These queries demonstrate that cross-SCHEMA joins work natively
-- in a single database — replacing the need for postgres_fdw/dblink
-- that Advito currently uses for cross-DATABASE queries in RDS.
--
-- Before (RDS with FDW):
--   SELECT * FROM advito_qsi.market_rates  -- via postgres_fdw
--   JOIN advito_prod.bookings ON ...        -- local table
--
-- After (Lakebase with schemas):
--   SELECT * FROM qsi.market_rates          -- same DB, different schema
--   JOIN prod.bookings ON ...               -- same DB, different schema
-- =============================================================

-- ---------------------------------------------------------
-- QUERY 1: Rate Savings Analysis
-- Join bookings (prod) with market rates (qsi) to show
-- how much below market rate corporate bookings achieve.
-- This REQUIRED FDW in the old RDS architecture.
-- ---------------------------------------------------------
SELECT
    c.client_name,
    h.city,
    h.chain_name,
    b.booked_rate,
    mr.avg_market_rate,
    ROUND(mr.avg_market_rate - b.booked_rate, 2) AS savings_vs_market,
    ROUND(100.0 * (mr.avg_market_rate - b.booked_rate) / mr.avg_market_rate, 1) AS savings_pct
FROM prod.bookings b
JOIN prod.hotels h ON b.hotel_id = h.hotel_id
JOIN prod.clients c ON b.client_id = c.client_id
JOIN qsi.market_rates mr
    ON h.city = mr.city
    AND h.country = mr.country
    AND h.star_rating = mr.star_rating
    AND mr.rate_date = DATE_TRUNC('month', b.check_in)
WHERE b.rate_type = 'corporate'
ORDER BY savings_pct DESC;

-- ---------------------------------------------------------
-- QUERY 2: Leakage Impact vs Market Benchmark
-- Show leakage bookings and how they compare to both
-- the negotiated rate AND the market rate.
-- Combines prod.bookings + prod.rate_programs + qsi.market_rates
-- ---------------------------------------------------------
SELECT
    c.client_name,
    h.property_name,
    b.booked_rate AS leakage_rate,
    rp.negotiated_rate AS missed_corp_rate,
    mr.avg_market_rate,
    ROUND(b.booked_rate - rp.negotiated_rate, 2) AS overpay_vs_corp,
    ROUND(b.booked_rate - mr.avg_market_rate, 2) AS vs_market,
    b.booking_channel
FROM prod.bookings b
JOIN prod.hotels h ON b.hotel_id = h.hotel_id
JOIN prod.clients c ON b.client_id = c.client_id
LEFT JOIN prod.rate_programs rp
    ON b.client_id = rp.client_id
    AND b.hotel_id = rp.hotel_id
    AND b.check_in BETWEEN rp.effective_start AND rp.effective_end
LEFT JOIN qsi.market_rates mr
    ON h.city = mr.city
    AND h.country = mr.country
    AND h.star_rating = mr.star_rating
    AND mr.rate_date = DATE_TRUNC('month', b.check_in)
WHERE b.leakage_flag = TRUE
ORDER BY overpay_vs_corp DESC NULLS LAST;

-- ---------------------------------------------------------
-- QUERY 3: Supplier Scorecard with Booking Volume
-- Join supplier performance (qsi) with actual booking
-- volumes (prod) to create a supplier scorecard.
-- This was a dblink use case in the old architecture.
-- ---------------------------------------------------------
SELECT
    sp.chain_name,
    sp.region,
    sp.avg_rate_compliance,
    sp.avg_amenity_delivery,
    sp.complaint_rate,
    sp.rebate_pct,
    COUNT(b.booking_id) AS our_bookings,
    ROUND(SUM(b.booked_rate * b.room_nights), 2) AS our_spend,
    qs.overall_score AS quality_score
FROM qsi.supplier_performance sp
LEFT JOIN prod.hotels h ON h.chain_name = sp.chain_name
LEFT JOIN prod.bookings b ON b.hotel_id = h.hotel_id
LEFT JOIN qsi.quality_scores qs
    ON qs.hotel_chain = sp.chain_name
    AND qs.quarter = sp.quarter
WHERE sp.quarter = '2025-Q3'
GROUP BY sp.chain_name, sp.region, sp.avg_rate_compliance,
         sp.avg_amenity_delivery, sp.complaint_rate, sp.rebate_pct,
         qs.overall_score
ORDER BY our_spend DESC NULLS LAST;

-- ---------------------------------------------------------
-- QUERY 4: City Demand vs Booking Activity
-- Correlate city-level demand index (qsi) with actual
-- booking patterns (prod) to identify opportunities.
-- ---------------------------------------------------------
SELECT
    di.city,
    di.month,
    di.demand_score,
    di.occupancy_pct,
    di.adr AS market_adr,
    COUNT(b.booking_id) AS our_bookings_that_month,
    ROUND(AVG(b.booked_rate), 2) AS our_avg_rate,
    ROUND(di.adr - AVG(b.booked_rate), 2) AS our_savings_vs_adr
FROM qsi.demand_index di
LEFT JOIN prod.hotels h ON h.city = di.city AND h.country = di.country
LEFT JOIN prod.bookings b
    ON b.hotel_id = h.hotel_id
    AND DATE_TRUNC('month', b.check_in) = di.month
GROUP BY di.city, di.month, di.demand_score, di.occupancy_pct, di.adr
HAVING COUNT(b.booking_id) > 0
ORDER BY di.demand_score DESC;

-- ---------------------------------------------------------
-- QUERY 5: Full Pipeline View
-- A single query spanning ALL schemas — this is the kind
-- of query that previously required multiple FDW connections
-- or a dblink-based function to assemble.
-- ---------------------------------------------------------
SELECT
    c.client_name,
    h.property_name,
    h.city,
    b.check_in,
    b.booked_rate,
    b.leakage_flag,
    rp.negotiated_rate AS corp_rate,
    mr.avg_market_rate,
    qs.overall_score AS hotel_quality,
    di.demand_score AS city_demand,
    di.occupancy_pct,
    CASE
        WHEN b.leakage_flag THEN 'LEAKAGE'
        WHEN b.booked_rate > mr.avg_market_rate THEN 'ABOVE MARKET'
        WHEN b.booked_rate <= rp.negotiated_rate THEN 'AT/BELOW CORP RATE'
        ELSE 'IN POLICY'
    END AS booking_classification
FROM prod.bookings b
JOIN prod.clients c ON b.client_id = c.client_id
JOIN prod.hotels h ON b.hotel_id = h.hotel_id
LEFT JOIN prod.rate_programs rp
    ON b.client_id = rp.client_id AND b.hotel_id = rp.hotel_id
    AND b.check_in BETWEEN rp.effective_start AND rp.effective_end
LEFT JOIN qsi.market_rates mr
    ON h.city = mr.city AND h.country = mr.country
    AND h.star_rating = mr.star_rating
    AND mr.rate_date = DATE_TRUNC('month', b.check_in)
LEFT JOIN qsi.quality_scores qs
    ON h.chain_name = qs.hotel_chain AND h.city = qs.city
LEFT JOIN qsi.demand_index di
    ON h.city = di.city AND h.country = di.country
    AND di.month = DATE_TRUNC('month', b.check_in)
ORDER BY b.check_in;
