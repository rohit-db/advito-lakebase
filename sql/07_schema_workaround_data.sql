-- =============================================================
-- Sample Data for Schema Workaround (advito_unified database)
-- =============================================================

-- PROD SCHEMA DATA
-- Hotels
INSERT INTO prod.hotels (property_name, chain_code, chain_name, city, state_province, country, star_rating, latitude, longitude) VALUES
('Marriott Marquis NYC', 'MC', 'Marriott', 'New York', 'NY', 'USA', 4, 40.758896, -73.985130),
('Hilton Chicago', 'HH', 'Hilton', 'Chicago', 'IL', 'USA', 4, 41.878113, -87.629799),
('Hyatt Regency Dallas', 'HY', 'Hyatt', 'Dallas', 'TX', 'USA', 4, 32.783058, -96.806671),
('IHG Crowne Plaza LAX', 'IC', 'IHG', 'Los Angeles', 'CA', 'USA', 3, 33.942791, -118.408009),
('Westin Atlanta Airport', 'WI', 'Marriott', 'Atlanta', 'GA', 'USA', 4, 33.640411, -84.427864),
('Novotel London Heathrow', 'AC', 'Accor', 'London', NULL, 'GBR', 4, 51.470020, -0.487890);

-- Clients
INSERT INTO prod.clients (client_name, industry, tier, annual_travel_spend, contract_start, contract_end) VALUES
('Acme Corp', 'Technology', 'platinum', 12500000.00, '2025-01-01', '2026-12-31'),
('Atlas Financial', 'Financial Services', 'platinum', 15800000.00, '2025-01-01', '2026-12-31'),
('Pacific Energy', 'Energy', 'gold', 6700000.00, '2025-01-01', '2025-12-31');

-- Travelers
INSERT INTO prod.travelers (client_id, first_name, last_name, email, department, travel_tier) VALUES
(1, 'Sarah', 'Chen', 'schen@acme.com', 'Engineering', 'business'),
(1, 'Mike', 'Johnson', 'mjohnson@acme.com', 'Sales', 'economy'),
(2, 'David', 'Martinez', 'dmartinez@atlas.com', 'Finance', 'business'),
(2, 'Rachel', 'Kim', 'rkim@atlas.com', 'Compliance', 'business'),
(3, 'Robert', 'Lee', 'rlee@pacific.com', 'Engineering', 'business');

-- Bookings (mix of in-policy and leakage)
INSERT INTO prod.bookings (traveler_id, hotel_id, client_id, check_in, check_out, rate_type, negotiated_rate, booked_rate, actual_rate, booking_channel, booking_status, is_in_policy, leakage_flag) VALUES
(1, 1, 1, '2025-09-15', '2025-09-18', 'corporate', 189.00, 189.00, 189.00, 'GDS', 'completed', TRUE, FALSE),
(2, 2, 1, '2025-09-20', '2025-09-22', 'corporate', 159.00, 159.00, 159.00, 'GDS', 'completed', TRUE, FALSE),
(2, 3, 1, '2025-10-10', '2025-10-12', 'BAR', NULL, 179.00, 179.00, 'OTA', 'completed', FALSE, TRUE),
(3, 1, 2, '2025-09-08', '2025-09-11', 'corporate', 199.00, 199.00, 199.00, 'GDS', 'completed', TRUE, FALSE),
(4, 4, 2, '2025-09-22', '2025-09-25', 'corporate', 169.00, 169.00, 169.00, 'GDS', 'completed', TRUE, FALSE),
(3, 6, 2, '2025-10-20', '2025-10-23', 'BAR', NULL, 209.00, 209.00, 'direct', 'completed', FALSE, TRUE),
(5, 3, 3, '2025-09-01', '2025-09-04', 'corporate', 155.00, 155.00, 155.00, 'GDS', 'completed', TRUE, FALSE),
(5, 5, 3, '2025-10-10', '2025-10-13', 'BAR', NULL, 175.00, 175.00, 'direct', 'completed', FALSE, TRUE);

-- Rate programs
INSERT INTO prod.rate_programs (client_id, hotel_id, rate_code, negotiated_rate, effective_start, effective_end, min_room_nights) VALUES
(1, 1, 'ACME-NYC', 189.00, '2025-01-01', '2026-12-31', 500),
(1, 2, 'ACME-CHI', 159.00, '2025-01-01', '2026-12-31', 300),
(2, 1, 'ATL-NYC', 199.00, '2025-01-01', '2026-12-31', 800),
(2, 4, 'ATL-LAX', 169.00, '2025-01-01', '2026-12-31', 400),
(3, 3, 'PAC-DAL', 155.00, '2025-01-01', '2025-12-31', 200);

-- QSI SCHEMA DATA
-- Market rates
INSERT INTO qsi.market_rates (city, country, star_rating, rate_date, avg_market_rate, median_rate, p25_rate, p75_rate, sample_size) VALUES
('New York', 'USA', 4, '2025-09-01', 275.00, 265.00, 220.00, 320.00, 1250),
('New York', 'USA', 4, '2025-10-01', 289.00, 279.00, 235.00, 340.00, 1180),
('Chicago', 'USA', 4, '2025-09-01', 195.00, 185.00, 155.00, 230.00, 890),
('Dallas', 'USA', 4, '2025-09-01', 175.00, 165.00, 135.00, 210.00, 650),
('Los Angeles', 'USA', 3, '2025-09-01', 195.00, 185.00, 150.00, 235.00, 1100),
('Atlanta', 'USA', 4, '2025-10-01', 172.00, 162.00, 130.00, 210.00, 750),
('London', 'GBR', 4, '2025-10-01', 225.00, 215.00, 175.00, 270.00, 1500);

-- Quality scores
INSERT INTO qsi.quality_scores (hotel_chain, city, country, quarter, overall_score, cleanliness_score, service_score, location_score, amenities_score, value_score, review_count) VALUES
('Marriott', 'New York', 'USA', '2025-Q3', 8.2, 8.5, 8.0, 9.1, 7.8, 7.5, 2340),
('Hilton', 'Chicago', 'USA', '2025-Q3', 8.0, 8.3, 7.8, 8.8, 7.6, 7.4, 1890),
('Hyatt', 'Dallas', 'USA', '2025-Q3', 7.9, 8.1, 7.7, 8.2, 7.5, 7.6, 1120),
('IHG', 'Los Angeles', 'USA', '2025-Q3', 7.2, 7.4, 7.0, 8.0, 6.8, 7.3, 980),
('Marriott', 'Atlanta', 'USA', '2025-Q3', 7.5, 7.8, 7.2, 8.0, 7.1, 7.5, 680),
('Accor', 'London', 'GBR', '2025-Q3', 7.4, 7.6, 7.2, 8.5, 7.0, 6.8, 1200);

-- Supplier performance
INSERT INTO qsi.supplier_performance (chain_name, region, quarter, avg_rate_compliance, avg_amenity_delivery, avg_response_time_hrs, complaint_rate, rebate_pct, total_room_nights) VALUES
('Marriott', 'North America', '2025-Q3', 94.5, 91.2, 2.3, 0.0125, 3.5, 45000),
('Hilton', 'North America', '2025-Q3', 93.8, 90.5, 2.5, 0.0130, 3.2, 38000),
('Hyatt', 'North America', '2025-Q3', 95.2, 92.0, 2.0, 0.0110, 3.8, 22000),
('IHG', 'North America', '2025-Q3', 91.0, 87.5, 3.2, 0.0170, 2.5, 28000),
('Accor', 'Europe', '2025-Q3', 90.5, 86.8, 3.8, 0.0180, 2.2, 15000);

-- Demand index
INSERT INTO qsi.demand_index (city, country, month, demand_score, occupancy_pct, adr, revpar, yoy_change_pct) VALUES
('New York', 'USA', '2025-09-01', 82.5, 85.3, 278.00, 237.13, 3.2),
('New York', 'USA', '2025-10-01', 88.1, 89.0, 292.00, 259.88, 4.1),
('Chicago', 'USA', '2025-09-01', 75.0, 78.2, 198.00, 154.84, 1.8),
('Dallas', 'USA', '2025-09-01', 70.2, 73.5, 178.00, 130.83, 2.0),
('Los Angeles', 'USA', '2025-09-01', 79.5, 82.0, 198.00, 162.36, 1.5),
('Atlanta', 'USA', '2025-10-01', 68.0, 71.5, 175.00, 125.13, 0.8),
('London', 'GBR', '2025-10-01', 85.0, 87.5, 228.00, 199.50, 2.2);
