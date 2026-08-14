-- ------------------------------------------------------------
-- Keep updated_at fresh on posts automatically
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
