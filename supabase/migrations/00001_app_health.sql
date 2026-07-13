-- M0: table minimale pour vérifier la connectivité Supabase depuis l'app.
-- Clés primaires UUID ; slug stable pour les requêtes client.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE app_health (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  ok boolean NOT NULL DEFAULT true,
  checked_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER app_health_set_updated_at
  BEFORE UPDATE ON app_health
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

INSERT INTO app_health (slug, ok)
VALUES ('ping', true)
ON CONFLICT (slug) DO NOTHING;

ALTER TABLE app_health ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read app_health"
  ON app_health
  FOR SELECT
  USING (true);
