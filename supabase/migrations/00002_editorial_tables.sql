-- M1: tables éditoriales en lecture seule (UUID + slug).

CREATE TABLE procedures (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  title text NOT NULL,
  summary text NOT NULL,
  category text NOT NULL,
  category_label text NOT NULL,
  estimated_duration text NOT NULL,
  documents text[] NOT NULL,
  steps text[] NOT NULL,
  icon_key text NOT NULL,
  official_url text,
  is_published boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER procedures_set_updated_at
  BEFORE UPDATE ON procedures
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_procedures_category ON procedures(category);
CREATE INDEX idx_procedures_published ON procedures(is_published) WHERE is_published;

CREATE TABLE places (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  name text NOT NULL,
  city_name text NOT NULL,
  category text NOT NULL,
  category_label text NOT NULL,
  neighborhood text NOT NULL,
  price_level text NOT NULL,
  is_editors_pick boolean NOT NULL DEFAULT false,
  image_color text NOT NULL,
  summary text NOT NULL,
  practical_tips text[] NOT NULL,
  best_time_to_visit text,
  maps_url text,
  is_published boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER places_set_updated_at
  BEFORE UPDATE ON places
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_places_city_name ON places(city_name);
CREATE INDEX idx_places_category ON places(category);
CREATE INDEX idx_places_editors_pick ON places(city_name, is_editors_pick)
  WHERE is_editors_pick AND is_published;

CREATE TABLE prices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  name text NOT NULL,
  city_name text NOT NULL,
  category text NOT NULL,
  category_label text NOT NULL,
  min_amount_mad integer NOT NULL,
  max_amount_mad integer NOT NULL,
  average_amount_mad integer NOT NULL,
  unit_label text NOT NULL,
  summary text NOT NULL,
  price_factors text[] NOT NULL,
  warning_signs text[] NOT NULL,
  negotiation_tips text[] NOT NULL,
  icon_key text NOT NULL,
  source_note text,
  is_tourist_trap boolean NOT NULL DEFAULT false,
  last_updated_at timestamptz NOT NULL,
  is_published boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER prices_set_updated_at
  BEFORE UPDATE ON prices
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_prices_city_name ON prices(city_name);
CREATE INDEX idx_prices_category ON prices(category);
CREATE INDEX idx_prices_published_city ON prices(is_published, city_name)
  WHERE is_published;

ALTER TABLE procedures ENABLE ROW LEVEL SECURITY;
ALTER TABLE places ENABLE ROW LEVEL SECURITY;
ALTER TABLE prices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read published procedures"
  ON procedures FOR SELECT
  USING (is_published = true);

CREATE POLICY "Public read published places"
  ON places FOR SELECT
  USING (is_published = true);

CREATE POLICY "Public read published prices"
  ON prices FOR SELECT
  USING (is_published = true);
