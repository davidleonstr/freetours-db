CREATE TRIGGER trg_tour_stops_updated_at
BEFORE UPDATE ON tour_stops
FOR EACH ROW EXECUTE FUNCTION updated_at();