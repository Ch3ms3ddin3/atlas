-- M4: signalements utilisateur (corrections de contenu éditorial).

CREATE TABLE content_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  entity_type text NOT NULL CHECK (entity_type IN ('price', 'procedure', 'place')),
  entity_slug text NOT NULL CHECK (char_length(entity_slug) > 0),
  report_type text NOT NULL CHECK (
    report_type IN ('outdated', 'incorrect', 'missing_info', 'other')
  ),
  details text NOT NULL CHECK (char_length(details) BETWEEN 1 AND 2000),
  status text NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'reviewed', 'dismissed')
  ),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER content_reports_set_updated_at
  BEFORE UPDATE ON content_reports
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_content_reports_user ON content_reports(user_id);
CREATE INDEX idx_content_reports_entity ON content_reports(entity_type, entity_slug);
CREATE INDEX idx_content_reports_status
  ON content_reports(status)
  WHERE status = 'pending';

ALTER TABLE content_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "content_reports_select_own"
  ON content_reports FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "content_reports_insert_own"
  ON content_reports FOR INSERT
  WITH CHECK (auth.uid() = user_id);
