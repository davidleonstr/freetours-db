/*
Engine: PostgreSQL.
Version: 18.4.
*/

-- Author: David L.

-- ============================================================
-- Free Tours Booking Schema
-- PostgreSQL — UUID primary keys
--
-- Covers: tour catalog (free, with a Google-Maps meeting point plus
-- optional ordered route stops), tour photo galleries, the calendar
-- dates + departure times each tour is actually offered on, customers,
-- bookings (adults/children/babies/pets for a given date + departure),
-- and reviews. No pricing, no payment processing, and no
-- email-confirmation flow — registration and login are instant so
-- booking a tour is quick.
-- ============================================================

-- Extensions (gen_random_uuid needs pgcrypto on PG < 13; PG 13+
-- has it built in via the "uuid-ossp"-free pgcrypto core function,
-- but we enable it explicitly for portability).
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Enum types
\i types/booking_status.sql;

-- Functions
\i functions/updated_at.sql;

-- Tables (order matters: dependencies first)
-- NOTE: tour_schedules, tour_dates, and tour_stops all reference tours,
-- and bookings references tours + tour_dates + tour_schedules, so tours
-- must load before tour_schedules/tour_dates/tour_stops, and those
-- before bookings.
\i tables/images.sql;
\i tables/tours.sql;
\i tables/tour_schedules.sql;
\i tables/tour_dates.sql;
\i tables/tour_stops.sql;
\i tables/gallery.sql;
\i tables/customers.sql;
\i tables/bookings.sql;
\i tables/reviews.sql;

-- Triggers (depend on both the updated_at() function and the tables)
\i triggers/trg_tours_updated_at.sql;
\i triggers/trg_customers_updated_at.sql;
\i triggers/trg_bookings_updated_at.sql;
\i triggers/trg_tour_stops_updated_at.sql;

-- Indexes
\i indexes/idx_gallery_tour.sql;
\i indexes/idx_bookings_customer.sql;
\i indexes/idx_bookings_tour.sql;
\i indexes/idx_bookings_tour_schedule.sql;
\i indexes/idx_tour_schedules_tour_id_time.sql;
\i indexes/idx_reviews_tour_id.sql;
\i indexes/idx_bookings_tour_date_schedule.sql;
\i indexes/idx_tour_stops_tour_position.sql;

-- ============================================================
-- Example usage
-- ============================================================

-- Covers: tour catalog (free, with a Google-Maps meeting point plus
-- optional ordered route stops), tour photo galleries, the calendar
-- dates + departure times each tour is actually offered on, customers,
-- bookings (adults/children/babies/pets for a given date + departure),
-- and reviews. No pricing, no payment processing, and no
-- email-confirmation flow — registration and login are instant so
-- booking a tour is quick.

-- Create a tour with a fractional duration, e.g. 2.5 hours
-- INSERT INTO tours (name, description, meeting_point, meeting_point_lat, meeting_point_lng, duration_hours, capacity)
-- VALUES ('Dublin Castle Walk', 'A relaxed walk through old Dublin.', 'Dublin Castle main gate', 53.3431, -6.2674, 2.5, 25)
-- RETURNING id;

-- Add a departure time for that tour (replace with the real tour UUID)
-- INSERT INTO tour_schedules (time, tour_id)
-- VALUES ('05:30', '11111111-1111-1111-1111-111111111111')
-- RETURNING id;

-- Open up a calendar date for that tour (replace with the real tour UUID)
-- INSERT INTO tour_dates (tour_id, date)
-- VALUES ('11111111-1111-1111-1111-111111111111', '2026-09-01')
-- RETURNING id;

-- Add ordered route stops for that tour (replace with the real tour UUID)
-- INSERT INTO tour_stops (tour_id, name, description, lat, lng, position)
-- VALUES ('11111111-1111-1111-1111-111111111111', 'Christ Church Cathedral', 'Second stop on the route.', 53.3436, -6.2705, 0)
-- RETURNING id;
-- INSERT INTO tour_stops (tour_id, name, description, lat, lng, position)
-- VALUES ('11111111-1111-1111-1111-111111111111', 'Temple Bar', 'Third stop on the route.', 53.3454, -6.2637, 1)
-- RETURNING id;

-- Add photos to a tour's gallery (replace with real UUIDs)
-- INSERT INTO images (url, alt) VALUES ('https://example.com/photo1.jpg', 'Volcano crater at sunrise') RETURNING id;
-- INSERT INTO gallery (tour_id, image_id, position)
-- VALUES ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 0);

-- Register a customer — instant, no email confirmation required
-- INSERT INTO customers (full_name, email, phone)
-- VALUES ('Jane Doe', 'jane@example.com', '+503 7000 0000')
-- RETURNING id;

-- Book a free tour (a booking) — pins the chosen calendar date and
-- departure time via tour_date_id / tour_schedule_id, and records how
-- many adults/children/babies/pets are coming (replace with real tour_dates
-- and tour_schedules UUIDs that both belong to the same tour)
-- INSERT INTO bookings (customer_id, tour_id, tour_date_id, tour_schedule_id, quantity, number_of_children, number_of_babies, number_of_pets)
-- VALUES ('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', '66666666-6666-6666-6666-666666666666', 2, 1, 0, 0)
-- RETURNING id;

-- Fetch a customer's booking history with the scheduled date + departure
-- time for each booking
-- SELECT b.id, t.name AS tour_name, t.meeting_point, td.date AS tour_date, ts.time AS departure_time,
--        b.quantity, b.number_of_children, b.number_of_babies, b.number_of_pets, b.status AS booking_status
-- FROM bookings b
-- JOIN tours t ON t.id = b.tour_id
-- JOIN tour_dates td ON td.id = b.tour_date_id
-- JOIN tour_schedules ts ON ts.id = b.tour_schedule_id
-- WHERE b.customer_id = '33333333-3333-3333-3333-333333333333'
-- ORDER BY b.created_at DESC;

-- Fetch a tour with its gallery images and its ordered route stops
-- SELECT t.*,
--        json_agg(DISTINCT jsonb_build_object('id', i.id, 'url', i.url, 'alt', i.alt, 'position', g.position)) FILTER (WHERE i.id IS NOT NULL) AS gallery,
--        (SELECT json_agg(jsonb_build_object('id', s.id, 'name', s.name, 'description', s.description, 'lat', s.lat, 'lng', s.lng, 'position', s.position) ORDER BY s.position ASC)
--         FROM tour_stops s WHERE s.tour_id = t.id) AS stops
-- FROM tours t
-- LEFT JOIN gallery g ON g.tour_id = t.id
-- LEFT JOIN images i ON i.id = g.image_id
-- WHERE t.id = '11111111-1111-1111-1111-111111111111'
-- GROUP BY t.id;