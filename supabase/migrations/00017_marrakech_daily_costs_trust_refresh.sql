-- =============================================================================
-- 00017 — Marrakech daily costs trust refresh (2026-08-11)
-- Additive only. Does not invent prices.
-- - Unpublish inwi SIM: official brochure PDF URLs return HTTP 404.
-- - Refresh last_updated_at for Orange nationals re-verified on boutique.orange.ma
-- =============================================================================

BEGIN;

UPDATE price_observations
SET
  is_published = false,
  verification_status = 'pending',
  updated_at = timezone('utc', now())
WHERE slug = 'mobilePlans-inwi-sim-prepaid-20';

UPDATE price_observations
SET
  last_updated_at = '2026-08-11T00:00:00+00',
  updated_at = timezone('utc', now())
WHERE slug IN (
  'mobilePlans-orange-sim-prepaid-20',
  'mobilePlans-orange-marhaba-7j-120',
  'mobilePlans-orange-marhaba-14j-220',
  'mobilePlans-orange-marhaba-30j-320',
  'mobilePlans-orange-forfait-yo-max-199',
  'internet-orange-dar-box-4g-199',
  'internet-orange-dar-box-4g-249',
  'internet-orange-dar-box-5g-299'
);

COMMIT;
