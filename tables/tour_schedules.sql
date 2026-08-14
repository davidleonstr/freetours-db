-- This stores the available schedules for each tour.
CREATE TABLE tour_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    time TIME UNIQUE NOT NULL,
    tour_id UUID NOT NULL REFERENCES tours(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
