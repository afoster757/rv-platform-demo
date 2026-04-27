CREATE TABLE IF NOT EXISTS licenses (
  license_key TEXT PRIMARY KEY,
  customer_name TEXT NOT NULL,
  plan TEXT NOT NULL,
  status TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  max_devices INT NOT NULL DEFAULT 3,
  features TEXT[] NOT NULL DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS devices (
  id BIGSERIAL PRIMARY KEY,
  license_key TEXT NOT NULL REFERENCES licenses(license_key),
  device_id TEXT NOT NULL,
  hostname TEXT,
  os TEXT,
  app_version TEXT,
  registered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (license_key, device_id)
);

CREATE TABLE IF NOT EXISTS content_items (
  id BIGSERIAL PRIMARY KEY,
  slug TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  required_plan TEXT NOT NULL,
  object_key TEXT NOT NULL,
  thumbnail_key TEXT NOT NULL
);
