-- Join table: lets a tour have many photos (beyond its single cover image)
CREATE TABLE gallery (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tour_id    UUID NOT NULL REFERENCES tours(id) ON DELETE CASCADE,
    image_id   UUID NOT NULL REFERENCES images(id) ON DELETE CASCADE,
    position   INTEGER NOT NULL DEFAULT 0,

    -- Audits
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (tour_id, image_id)
);
