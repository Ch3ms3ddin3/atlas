-- M13 Private Beta: in-app feedback from testers.
-- Idempotent.

CREATE TABLE IF NOT EXISTS beta_feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  screen_name text NOT NULL CHECK (char_length(screen_name) BETWEEN 1 AND 80),
  message text NOT NULL CHECK (char_length(message) BETWEEN 1 AND 4000),
  app_version text NOT NULL CHECK (char_length(app_version) BETWEEN 1 AND 40),
  build_number text NOT NULL CHECK (char_length(build_number) BETWEEN 1 AND 40),
  platform text NOT NULL CHECK (char_length(platform) BETWEEN 1 AND 40),
  include_screenshot boolean NOT NULL DEFAULT false,
  screenshot_base64 text CHECK (
    screenshot_base64 IS NULL OR char_length(screenshot_base64) <= 900000
  ),
  status text NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'reviewed', 'dismissed')
  ),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS beta_feedback_set_updated_at ON beta_feedback;
CREATE TRIGGER beta_feedback_set_updated_at
  BEFORE UPDATE ON beta_feedback
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE INDEX IF NOT EXISTS idx_beta_feedback_user ON beta_feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_beta_feedback_status
  ON beta_feedback(status)
  WHERE status = 'pending';

ALTER TABLE beta_feedback ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "beta_feedback_select_own" ON beta_feedback;
CREATE POLICY "beta_feedback_select_own"
  ON beta_feedback FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "beta_feedback_insert_own" ON beta_feedback;
CREATE POLICY "beta_feedback_insert_own"
  ON beta_feedback FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND status = 'pending'
  );
