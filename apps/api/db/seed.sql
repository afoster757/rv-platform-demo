INSERT INTO licenses (license_key, customer_name, plan, status, expires_at, max_devices, features)
VALUES
  ('RV-DEMO-1234', 'Demo Church', 'pro', 'active', '2026-12-31T23:59:59Z', 5, ARRAY['cloud_sync','procontent','bibles']),
  ('RV-EXPIRED-0000', 'Expired Demo', 'basic', 'expired', '2024-01-01T00:00:00Z', 1, ARRAY['bibles'])
ON CONFLICT (license_key) DO NOTHING;

INSERT INTO content_items (slug, title, category, required_plan, object_key, thumbnail_key)
VALUES
  ('easter-countdown', 'Easter Countdown', 'countdowns', 'pro', 'countdowns/easter-countdown.mp4', 'thumbs/easter-countdown.jpg'),
  ('worship-lower-third', 'Worship Lower Third', 'graphics', 'pro', 'graphics/worship-lower-third.mov', 'thumbs/worship-lower-third.jpg'),
  ('sermon-title-pack', 'Sermon Title Pack', 'slides', 'basic', 'slides/sermon-title-pack.zip', 'thumbs/sermon-title-pack.jpg')
ON CONFLICT (slug) DO NOTHING;
