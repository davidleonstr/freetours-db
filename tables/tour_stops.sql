-- Intermediate stops/waypoints along a tour's route — distinct from the
-- single required meeting point on tours (tours.meeting_point*), which
-- is where participants gather to start the tour. A tour can have zero
-- or many stops, each pinned to a specific OSM location the same way the
-- meeting point is (lat/lng required, human-readable name/description,
-- optional osm_id for round-tripping a Nominatim node/way/relation id).
--
-- `position` controls the order stops are visited in (0-based), the same
-- pattern used by gallery.position for photo ordering.
CREATE TABLE tour_stops (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tour_id      UUID NOT NULL REFERENCES tours(id) ON DELETE CASCADE,

    name         VARCHAR(255) NOT NULL,
    description  TEXT,

    lat          DOUBLE PRECISION NOT NULL,
    lng          DOUBLE PRECISION NOT NULL,
    osm_id       VARCHAR(255),

    position     INTEGER NOT NULL DEFAULT 0,

    -- Audits
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);