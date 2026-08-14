-- Specific calendar dates a tour actually runs. Bookings reference one of
-- these (bookings.tour_date_id) instead of an arbitrary date, the same
-- way they reference a tour_schedules row instead of an arbitrary time —
-- so a booking can only be made for a departure the tour operator has
-- actually opened up.
--
-- is_active lets a date be closed off (e.g. fully booked out well in
-- advance, or cancelled) without deleting it — deleting would be blocked
-- anyway once bookings reference it (see tables/bookings.sql), so this is
-- the same soft-archive pattern used by tours.is_active.
CREATE TABLE tour_dates (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tour_id    UUID NOT NULL REFERENCES tours(id) ON DELETE CASCADE,
    date       DATE NOT NULL,
    is_active  BOOLEAN NOT NULL DEFAULT true,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (tour_id, date)
);