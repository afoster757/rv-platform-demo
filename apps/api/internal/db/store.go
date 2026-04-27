package db

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type License struct {
	LicenseKey string
	Plan       string
	Status     string
	ExpiresAt  time.Time
	MaxDevices int
	Features   []string
}

type ContentItem struct {
	Slug         string
	Title        string
	Category     string
	RequiredPlan string
	ObjectKey    string
	ThumbnailKey string
}

type Store struct {
	Pool *pgxpool.Pool
}

func New(ctx context.Context, databaseURL string) (*Store, error) {
	pool, err := pgxpool.New(ctx, databaseURL)
	if err != nil {
		return nil, err
	}
	return &Store{Pool: pool}, nil
}

func (s *Store) Ping(ctx context.Context) error {
	return s.Pool.Ping(ctx)
}

func (s *Store) GetLicense(ctx context.Context, key string) (License, error) {
	var l License
	err := s.Pool.QueryRow(ctx, `
		SELECT license_key, plan, status, expires_at, max_devices, features
		FROM licenses
		WHERE license_key = $1
	`, key).Scan(&l.LicenseKey, &l.Plan, &l.Status, &l.ExpiresAt, &l.MaxDevices, &l.Features)
	return l, err
}

func (s *Store) UpsertDevice(ctx context.Context, licenseKey, deviceID, hostname, os, appVersion string) error {
	_, err := s.Pool.Exec(ctx, `
		INSERT INTO devices (license_key, device_id, hostname, os, app_version)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (license_key, device_id)
		DO UPDATE SET hostname = EXCLUDED.hostname,
		              os = EXCLUDED.os,
		              app_version = EXCLUDED.app_version,
		              last_seen_at = now()
	`, licenseKey, deviceID, hostname, os, appVersion)
	return err
}

func (s *Store) DeviceCount(ctx context.Context, licenseKey string) (int, error) {
	var count int
	err := s.Pool.QueryRow(ctx, `SELECT count(*) FROM devices WHERE license_key = $1`, licenseKey).Scan(&count)
	return count, err
}

func (s *Store) ContentForPlan(ctx context.Context, plan string) ([]ContentItem, error) {
	rows, err := s.Pool.Query(ctx, `
		SELECT slug, title, category, required_plan, object_key, thumbnail_key
		FROM content_items
		WHERE required_plan = 'basic' OR $1 = 'pro'
		ORDER BY category, title
	`, plan)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := []ContentItem{}
	for rows.Next() {
		var item ContentItem
		if err := rows.Scan(&item.Slug, &item.Title, &item.Category, &item.RequiredPlan, &item.ObjectKey, &item.ThumbnailKey); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}
