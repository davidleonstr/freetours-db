-- These tours are free — no price/currency fields. A meeting point is
-- required so participants know where to show up for the departure. The
-- meeting point is a specific OpenStreetMap location: meeting_point is a
-- human-readable label/address, and meeting_point_lat/meeting_point_lng
-- are the actual coordinates (source of truth for the OSM-tile map
-- rendered in booking emails — see plugins/mailer.js).
-- meeting_point_osm_id is optional, for round-tripping an OSM
-- node/way/relation id (e.g. from Nominatim) if the caller has one.
--
-- Beyond the single required meeting point, a tour can also have any
-- number of intermediate stops/waypoints along its route — see
-- tables/tour_stops.sql.
--
-- duration_hours is DOUBLE PRECISION (not an integer) so tours can be
-- scheduled in fractional lengths, e.g. 2.5 hours, not just whole hours.
CREATE TABLE tours (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                     VARCHAR(255) UNIQUE NOT NULL,
    description              TEXT NOT NULL,
    image                    UUID REFERENCES images(id),   -- cover image

    meeting_point            TEXT NOT NULL,                 -- label / address / notes
    meeting_point_lat        DOUBLE PRECISION NOT NULL,
    meeting_point_lng        DOUBLE PRECISION NOT NULL,
    meeting_point_osm_id     VARCHAR(255),

    duration_hours           DOUBLE PRECISION CHECK (duration_hours > 0),
    capacity                 INTEGER CHECK (capacity > 0),  -- max participants per departure
    is_active                BOOLEAN NOT NULL DEFAULT true,

    -- Audits
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);