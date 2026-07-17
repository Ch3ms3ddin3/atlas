-- M9: Authentication & Cloud Sync — profil étendu, préférences, AT, suppression compte.
-- Idempotent : peut être ré-appliquée sans conflit.

-- Profil : types utilisateur étendus + avatar / display name.
ALTER TABLE profiles
  DROP CONSTRAINT IF EXISTS profiles_user_type_check;

ALTER TABLE profiles
  ADD CONSTRAINT profiles_user_type_check
  CHECK (user_type IN (
    'resident', 'mre', 'visitor', 'tourist', 'expatriate', 'student', 'business'
  ));

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS display_name text,
  ADD COLUMN IF NOT EXISTS avatar_url text;

-- Préférences utilisateur synchronisées (notifications + filtres Explorer).
CREATE TABLE IF NOT EXISTS user_preferences (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  prayer_notification_lead_time text NOT NULL DEFAULT 'disabled',
  at_notifications_enabled boolean NOT NULL DEFAULT false,
  explorer_city text,
  explorer_category text,
  explorer_favorites_only boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS user_preferences_set_updated_at ON user_preferences;
CREATE TRIGGER user_preferences_set_updated_at
  BEFORE UPDATE ON user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_preferences_select_own" ON user_preferences;
CREATE POLICY "user_preferences_select_own"
  ON user_preferences FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_preferences_insert_own" ON user_preferences;
CREATE POLICY "user_preferences_insert_own"
  ON user_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_preferences_update_own" ON user_preferences;
CREATE POLICY "user_preferences_update_own"
  ON user_preferences FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Véhicules Admission Temporaire.
CREATE TABLE IF NOT EXISTS at_vehicles (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  label text NOT NULL,
  plate text NOT NULL,
  country_code text NOT NULL,
  country_label text NOT NULL,
  vehicle_type text NOT NULL,
  entry_date date NOT NULL,
  expiry_date date NOT NULL,
  duration_days integer NOT NULL CHECK (duration_days > 0),
  notes text,
  notification_slot integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS at_vehicles_user_id_idx ON at_vehicles (user_id);

DROP TRIGGER IF EXISTS at_vehicles_set_updated_at ON at_vehicles;
CREATE TRIGGER at_vehicles_set_updated_at
  BEFORE UPDATE ON at_vehicles
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

ALTER TABLE at_vehicles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "at_vehicles_select_own" ON at_vehicles;
CREATE POLICY "at_vehicles_select_own"
  ON at_vehicles FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "at_vehicles_insert_own" ON at_vehicles;
CREATE POLICY "at_vehicles_insert_own"
  ON at_vehicles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "at_vehicles_update_own" ON at_vehicles;
CREATE POLICY "at_vehicles_update_own"
  ON at_vehicles FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "at_vehicles_delete_own" ON at_vehicles;
CREATE POLICY "at_vehicles_delete_own"
  ON at_vehicles FOR DELETE
  USING (auth.uid() = user_id);

-- Suppression de compte (cascade via FK).
CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;

REVOKE ALL ON FUNCTION public.delete_own_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;
