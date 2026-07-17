-- Calendrier éditorial Maroc (événements publiés en lecture publique).

CREATE TABLE events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  title text NOT NULL,
  description text NOT NULL,
  category text NOT NULL,
  start_at date NOT NULL,
  end_at date,
  is_all_day boolean NOT NULL DEFAULT true,
  city_name text,
  source text NOT NULL,
  source_url text,
  last_verified_at timestamptz,
  reliability text NOT NULL CHECK (
    reliability IN ('confirmed', 'provisional', 'estimated')
  ),
  priority integer,
  audience_tags text[] NOT NULL DEFAULT '{}',
  is_published boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT events_end_not_before_start CHECK (
    end_at IS NULL OR end_at >= start_at
  )
);

CREATE TRIGGER events_set_updated_at
  BEFORE UPDATE ON events
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_events_start_at ON events(start_at);
CREATE INDEX idx_events_category ON events(category);
CREATE INDEX idx_events_city_name ON events(city_name);
CREATE INDEX idx_events_published_start ON events(is_published, start_at)
  WHERE is_published;

ALTER TABLE events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read published events"
  ON events FOR SELECT
  USING (is_published = true);
