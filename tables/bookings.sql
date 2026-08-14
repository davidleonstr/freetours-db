-- A free-tour reservation: one customer booking spots on one tour for a
-- given departure. No pricing/payment fields — tours are free. Party
-- composition (adults, children, babies, pets) is tracked so guides know
-- who and what is actually showing up.
-- tour_date_id pins the booking to a specific tour_dates row (one of the
-- calendar dates the tour operator has actually opened up for that tour),
-- the same way tour_schedule_id pins it to a specific departure time —
-- rather than accepting an arbitrary DATE value.
CREATE TABLE bookings (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id        UUID NOT NULL REFERENCES customers(id),
    tour_id            UUID NOT NULL REFERENCES tours(id),

    tour_date_id       UUID NOT NULL REFERENCES tour_dates(id),
    tour_schedule_id   UUID NOT NULL REFERENCES tour_schedules(id),

    quantity           INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),            -- number of adults
    number_of_children INTEGER NOT NULL DEFAULT 0 CHECK (number_of_children >= 0), -- children counted against capacity
    number_of_babies   INTEGER NOT NULL DEFAULT 0 CHECK (number_of_babies >= 0),   -- babies/infants, not counted against capacity
    number_of_pets   INTEGER NOT NULL DEFAULT 0 CHECK (number_of_pets >= 0),   -- pets, not counted against capacity

    status             booking_status NOT NULL DEFAULT 'pending',

    -- Audits
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);