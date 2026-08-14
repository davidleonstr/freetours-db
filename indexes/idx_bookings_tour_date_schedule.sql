CREATE INDEX idx_bookings_tour_date_schedule
ON bookings (tour_id, tour_date_id, tour_schedule_id)
WHERE status NOT IN ('cancelled');