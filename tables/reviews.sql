CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stars INT NOT NULL CHECK (stars BETWEEN 1 AND 5),
    content TEXT,
    tour_id UUID NOT NULL REFERENCES tours(id), 
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Unique
    CONSTRAINT uq_customer_tour UNIQUE (customer_id, tour_id)
);
