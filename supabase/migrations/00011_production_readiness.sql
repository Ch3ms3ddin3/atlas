-- M12 Phase 0: server-side AI daily usage for rate limiting.
-- Idempotent.

CREATE TABLE IF NOT EXISTS ai_daily_usage (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  day date NOT NULL,
  request_count integer NOT NULL DEFAULT 0 CHECK (request_count >= 0),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, day)
);

CREATE INDEX IF NOT EXISTS ai_daily_usage_day_idx ON ai_daily_usage (day);

ALTER TABLE ai_daily_usage ENABLE ROW LEVEL SECURITY;

-- Users may read their own usage; writes only via SECURITY DEFINER RPC.
DROP POLICY IF EXISTS "ai_daily_usage_select_own" ON ai_daily_usage;
CREATE POLICY "ai_daily_usage_select_own"
  ON ai_daily_usage FOR SELECT
  USING (auth.uid() = user_id);

-- Atomically check limit and increment. Returns allowed + new count + limit.
CREATE OR REPLACE FUNCTION public.consume_ai_request()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  uid uuid := auth.uid();
  today date := (timezone('utc', now()))::date;
  is_anon boolean;
  daily_limit integer;
  current_count integer;
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'reason', 'unauthenticated',
      'count', 0,
      'limit', 0
    );
  END IF;

  -- Anonymous Supabase sessions only (signInAnonymously).
  SELECT
    COALESCE(u.is_anonymous, false)
    OR COALESCE((u.raw_app_meta_data ->> 'provider') = 'anonymous', false)
  INTO is_anon
  FROM auth.users u
  WHERE u.id = uid;

  IF NOT FOUND OR is_anon IS NULL THEN
    is_anon := false;
  END IF;

  daily_limit := CASE WHEN is_anon THEN 5 ELSE 20 END;

  INSERT INTO ai_daily_usage (user_id, day, request_count)
  VALUES (uid, today, 0)
  ON CONFLICT (user_id, day) DO NOTHING;

  SELECT request_count INTO current_count
  FROM ai_daily_usage
  WHERE user_id = uid AND day = today
  FOR UPDATE;

  IF current_count >= daily_limit THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'reason', 'rate_limited',
      'count', current_count,
      'limit', daily_limit
    );
  END IF;

  UPDATE ai_daily_usage
  SET request_count = current_count + 1,
      updated_at = now()
  WHERE user_id = uid AND day = today;

  RETURN jsonb_build_object(
    'allowed', true,
    'count', current_count + 1,
    'limit', daily_limit
  );
END;
$$;

REVOKE ALL ON FUNCTION public.consume_ai_request() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.consume_ai_request() TO authenticated;

-- Harden content_reports inserts: status must be pending.
DROP POLICY IF EXISTS "content_reports_insert_own" ON content_reports;
CREATE POLICY "content_reports_insert_own"
  ON content_reports FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND status = 'pending'
  );
