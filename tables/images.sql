CREATE TABLE images (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    url          TEXT NOT NULL,
    alt          VARCHAR(255),               -- optional accessibility/description text
    position     INTEGER NOT NULL DEFAULT 0, -- controls display order

    -- Audits
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
