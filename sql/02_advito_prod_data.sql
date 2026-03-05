-- Sample data for advito_prod

-- Hotels
INSERT INTO hotels (property_name, chain_code, chain_name, city, state_province, country, star_rating, latitude, longitude) VALUES
('Marriott Marquis NYC', 'MC', 'Marriott', 'New York', 'NY', 'USA', 4, 40.758896, -73.985130),
('Hilton Chicago', 'HH', 'Hilton', 'Chicago', 'IL', 'USA', 4, 41.878113, -87.629799),
('Hyatt Regency Dallas', 'HY', 'Hyatt', 'Dallas', 'TX', 'USA', 4, 32.783058, -96.806671),
('IHG Crowne Plaza LAX', 'IC', 'IHG', 'Los Angeles', 'CA', 'USA', 3, 33.942791, -118.408009),
('Westin Atlanta Airport', 'WI', 'Marriott', 'Atlanta', 'GA', 'USA', 4, 33.640411, -84.427864),
('Hampton Inn Denver', 'HH', 'Hilton', 'Denver', 'CO', 'USA', 3, 39.739235, -104.990250),
('Courtyard Boston', 'MC', 'Marriott', 'Boston', 'MA', 'USA', 3, 42.361145, -71.057083),
('Holiday Inn Express Miami', 'IC', 'IHG', 'Miami', 'FL', 'USA', 3, 25.761680, -80.191790),
('Novotel London Heathrow', 'AC', 'Accor', 'London', NULL, 'GBR', 4, 51.470020, -0.487890),
('Ibis Berlin Mitte', 'AC', 'Accor', 'Berlin', NULL, 'DEU', 3, 52.520008, 13.404954),
('NH Collection Frankfurt', 'NH', 'NH Hotels', 'Frankfurt', NULL, 'DEU', 4, 50.110924, 8.682127),
('Radisson Blu Amsterdam', 'RD', 'Radisson', 'Amsterdam', NULL, 'NLD', 4, 52.370216, 4.895168),
('Best Western Plus Tokyo', 'BW', 'Best Western', 'Tokyo', NULL, 'JPN', 3, 35.689487, 139.691711),
('Melia Barcelona', 'ME', 'Melia', 'Barcelona', NULL, 'ESP', 4, 41.385063, 2.173404),
('InterContinental Singapore', 'IC', 'IHG', 'Singapore', NULL, 'SGP', 5, 1.296568, 103.852520);

-- Clients
INSERT INTO clients (client_name, industry, tier, annual_travel_spend, contract_start, contract_end) VALUES
('Acme Corp', 'Technology', 'platinum', 12500000.00, '2025-01-01', '2026-12-31'),
('GlobalTech Industries', 'Manufacturing', 'gold', 8200000.00, '2025-03-01', '2026-02-28'),
('Atlas Financial', 'Financial Services', 'platinum', 15800000.00, '2025-01-01', '2026-12-31'),
('Meridian Consulting', 'Professional Services', 'silver', 3400000.00, '2025-06-01', '2026-05-31'),
('Pacific Energy', 'Energy', 'gold', 6700000.00, '2025-01-01', '2025-12-31');

-- Travelers
INSERT INTO travelers (client_id, first_name, last_name, email, department, travel_tier) VALUES
(1, 'Sarah', 'Chen', 'schen@acme.com', 'Engineering', 'business'),
(1, 'Mike', 'Johnson', 'mjohnson@acme.com', 'Sales', 'economy'),
(1, 'Lisa', 'Park', 'lpark@acme.com', 'Executive', 'first'),
(2, 'James', 'Wilson', 'jwilson@globaltech.com', 'Operations', 'economy'),
(2, 'Emily', 'Brown', 'ebrown@globaltech.com', 'Sales', 'business'),
(3, 'David', 'Martinez', 'dmartinez@atlas.com', 'Finance', 'business'),
(3, 'Rachel', 'Kim', 'rkim@atlas.com', 'Compliance', 'business'),
(3, 'Tom', 'Anderson', 'tanderson@atlas.com', 'Executive', 'first'),
(4, 'Anna', 'Taylor', 'ataylor@meridian.com', 'Consulting', 'economy'),
(5, 'Robert', 'Lee', 'rlee@pacific.com', 'Engineering', 'business');

-- Rate Programs
INSERT INTO rate_programs (client_id, hotel_id, rate_code, negotiated_rate, effective_start, effective_end, min_room_nights) VALUES
(1, 1, 'ACME-NYC', 189.00, '2025-01-01', '2026-12-31', 500),
(1, 2, 'ACME-CHI', 159.00, '2025-01-01', '2026-12-31', 300),
(1, 7, 'ACME-BOS', 175.00, '2025-01-01', '2026-12-31', 200),
(2, 3, 'GT-DAL', 145.00, '2025-03-01', '2026-02-28', 400),
(2, 5, 'GT-ATL', 139.00, '2025-03-01', '2026-02-28', 250),
(3, 1, 'ATL-NYC', 199.00, '2025-01-01', '2026-12-31', 800),
(3, 4, 'ATL-LAX', 169.00, '2025-01-01', '2026-12-31', 400),
(3, 9, 'ATL-LHR', 185.00, '2025-01-01', '2026-12-31', 300),
(4, 6, 'MER-DEN', 129.00, '2025-06-01', '2026-05-31', 150),
(5, 3, 'PAC-DAL', 155.00, '2025-01-01', '2025-12-31', 200);

-- Bookings (mix of in-policy, out-of-policy, and leakage)
INSERT INTO bookings (traveler_id, hotel_id, client_id, check_in, check_out, rate_type, negotiated_rate, booked_rate, actual_rate, booking_channel, booking_status, is_in_policy, leakage_flag) VALUES
-- Acme Corp bookings
(1, 1, 1, '2025-09-15', '2025-09-18', 'corporate', 189.00, 189.00, 189.00, 'GDS', 'completed', TRUE, FALSE),
(1, 1, 1, '2025-10-02', '2025-10-05', 'corporate', 189.00, 189.00, 195.00, 'GDS', 'completed', TRUE, FALSE),
(2, 2, 1, '2025-09-20', '2025-09-22', 'corporate', 159.00, 159.00, 159.00, 'GDS', 'completed', TRUE, FALSE),
(2, 3, 1, '2025-10-10', '2025-10-12', 'BAR', NULL, 179.00, 179.00, 'OTA', 'completed', FALSE, TRUE),
(3, 1, 1, '2025-11-01', '2025-11-04', 'corporate', 189.00, 189.00, 189.00, 'direct', 'completed', TRUE, FALSE),
(1, 7, 1, '2025-11-15', '2025-11-17', 'corporate', 175.00, 175.00, 175.00, 'GDS', 'completed', TRUE, FALSE),
(2, 8, 1, '2025-12-01', '2025-12-03', 'BAR', NULL, 149.00, 149.00, 'OTA', 'completed', FALSE, TRUE),
-- GlobalTech bookings
(4, 3, 2, '2025-09-05', '2025-09-08', 'corporate', 145.00, 145.00, 145.00, 'GDS', 'completed', TRUE, FALSE),
(5, 5, 2, '2025-10-01', '2025-10-03', 'corporate', 139.00, 139.00, 139.00, 'GDS', 'completed', TRUE, FALSE),
(4, 5, 2, '2025-10-15', '2025-10-18', 'corporate', 139.00, 139.00, 145.00, 'GDS', 'completed', TRUE, FALSE),
(5, 10, 2, '2025-11-10', '2025-11-13', 'BAR', NULL, 119.00, 119.00, 'OTA', 'completed', FALSE, TRUE),
-- Atlas Financial bookings
(6, 1, 3, '2025-09-08', '2025-09-11', 'corporate', 199.00, 199.00, 199.00, 'GDS', 'completed', TRUE, FALSE),
(7, 4, 3, '2025-09-22', '2025-09-25', 'corporate', 169.00, 169.00, 169.00, 'GDS', 'completed', TRUE, FALSE),
(8, 9, 3, '2025-10-05', '2025-10-08', 'corporate', 185.00, 185.00, 185.00, 'GDS', 'completed', TRUE, FALSE),
(6, 11, 3, '2025-10-20', '2025-10-23', 'BAR', NULL, 209.00, 209.00, 'direct', 'completed', FALSE, TRUE),
(7, 1, 3, '2025-11-05', '2025-11-07', 'corporate', 199.00, 199.00, 205.00, 'GDS', 'completed', TRUE, FALSE),
(8, 12, 3, '2025-11-18', '2025-11-21', 'BAR', NULL, 245.00, 245.00, 'OTA', 'completed', FALSE, TRUE),
-- Meridian Consulting bookings
(9, 6, 4, '2025-08-10', '2025-08-13', 'corporate', 129.00, 129.00, 129.00, 'GDS', 'completed', TRUE, FALSE),
(9, 6, 4, '2025-09-15', '2025-09-18', 'corporate', 129.00, 129.00, 135.00, 'GDS', 'completed', TRUE, FALSE),
(9, 13, 4, '2025-10-01', '2025-10-04', 'BAR', NULL, 189.00, 189.00, 'OTA', 'completed', FALSE, TRUE),
-- Pacific Energy bookings
(10, 3, 5, '2025-09-01', '2025-09-04', 'corporate', 155.00, 155.00, 155.00, 'GDS', 'completed', TRUE, FALSE),
(10, 14, 5, '2025-10-10', '2025-10-13', 'BAR', NULL, 175.00, 175.00, 'direct', 'completed', FALSE, TRUE),
(10, 3, 5, '2025-11-05', '2025-11-08', 'corporate', 155.00, 155.00, 155.00, 'GDS', 'completed', TRUE, FALSE);
