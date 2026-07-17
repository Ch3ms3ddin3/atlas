-- M11: Smart Itineraries — voyages multi-jours synchronisés (payload JSON).
-- Idempotent.

CREATE TABLE IF NOT EXISTS trips (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS trips_user_id_idx ON trips (user_id);
CREATE INDEX IF NOT EXISTS trips_user_updated_idx ON trips (user_id, updated_at DESC);

DROP TRIGGER IF EXISTS trips_set_updated_at ON trips;
CREATE TRIGGER trips_set_updated_at
  BEFORE UPDATE ON trips
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

ALTER TABLE trips ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "trips_select_own" ON trips;
CREATE POLICY "trips_select_own"
  ON trips FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "trips_insert_own" ON trips;
CREATE POLICY "trips_insert_own"
  ON trips FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "trips_update_own" ON trips;
CREATE POLICY "trips_update_own"
  ON trips FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "trips_delete_own" ON trips;
CREATE POLICY "trips_delete_own"
  ON trips FOR DELETE
  USING (auth.uid() = user_id);
