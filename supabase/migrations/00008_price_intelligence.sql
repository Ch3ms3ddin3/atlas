-- Morocco Price Intelligence — observations vérifiées uniquement.
-- Pas de prix inventés côté client : seules les lignes published + verified sont lues.

CREATE TABLE price_observations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  category text NOT NULL,
  city_name text NOT NULL,
  district text,
  item_name text NOT NULL,
  unit_label text NOT NULL,
  current_amount_mad numeric(12, 2) NOT NULL CHECK (current_amount_mad >= 0),
  min_amount_mad numeric(12, 2) CHECK (min_amount_mad IS NULL OR min_amount_mad >= 0),
  avg_amount_mad numeric(12, 2) CHECK (avg_amount_mad IS NULL OR avg_amount_mad >= 0),
  max_amount_mad numeric(12, 2) CHECK (max_amount_mad IS NULL OR max_amount_mad >= 0),
  currency text NOT NULL DEFAULT 'MAD',
  last_updated_at timestamptz NOT NULL,
  source text NOT NULL,
  source_url text,
  confidence text NOT NULL CHECK (
    confidence IN ('high', 'medium', 'low')
  ),
  verification_status text NOT NULL CHECK (
    verification_status IN ('verified', 'unverified', 'pending')
  ),
  user_reports_count integer NOT NULL DEFAULT 0 CHECK (user_reports_count >= 0),
  atlas_score integer,
  is_published boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT price_observations_range_ok CHECK (
    (min_amount_mad IS NULL OR max_amount_mad IS NULL OR min_amount_mad <= max_amount_mad)
    AND (avg_amount_mad IS NULL OR min_amount_mad IS NULL OR avg_amount_mad >= min_amount_mad)
    AND (avg_amount_mad IS NULL OR max_amount_mad IS NULL OR avg_amount_mad <= max_amount_mad)
  )
);

CREATE TRIGGER price_observations_set_updated_at
  BEFORE UPDATE ON price_observations
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_price_observations_city ON price_observations(city_name);
CREATE INDEX idx_price_observations_category ON price_observations(category);
CREATE INDEX idx_price_observations_updated ON price_observations(last_updated_at DESC);
CREATE INDEX idx_price_observations_verified_published
  ON price_observations(is_published, verification_status, city_name)
  WHERE is_published AND verification_status = 'verified';

ALTER TABLE price_observations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read verified published price observations"
  ON price_observations FOR SELECT
  USING (
    is_published = true
    AND verification_status = 'verified'
  );

-- Historique futur (tendances) — non consommé par l'UI v1.
CREATE TABLE price_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  observation_slug text NOT NULL REFERENCES price_observations(slug)
    ON DELETE CASCADE,
  recorded_at timestamptz NOT NULL DEFAULT now(),
  amount_mad numeric(12, 2) NOT NULL CHECK (amount_mad >= 0),
  source text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_price_history_slug_recorded
  ON price_history(observation_slug, recorded_at DESC);

ALTER TABLE price_history ENABLE ROW LEVEL SECURITY;

-- Pas de lecture publique de l'historique en v1 (modération / agrégation futures).
