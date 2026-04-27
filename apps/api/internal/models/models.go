package models

import "time"

type LicenseValidationRequest struct {
	LicenseKey string `json:"license_key"`
	DeviceID   string `json:"device_id"`
	App        string `json:"app"`
	Version    string `json:"version"`
}

type LicenseValidationResponse struct {
	Valid     bool      `json:"valid"`
	Reason    string    `json:"reason,omitempty"`
	Plan      string    `json:"plan,omitempty"`
	ExpiresAt time.Time `json:"expires_at,omitempty"`
	Features  []string  `json:"features,omitempty"`
	Region    string    `json:"region"`
}

type DeviceRegistrationRequest struct {
	LicenseKey string `json:"license_key"`
	DeviceID   string `json:"device_id"`
	Hostname   string `json:"hostname"`
	OS         string `json:"os"`
	AppVersion string `json:"app_version"`
}

type ContentEntitlement struct {
	Slug         string `json:"slug"`
	Title        string `json:"title"`
	Category     string `json:"category"`
	DownloadURL  string `json:"download_url"`
	ThumbnailURL string `json:"thumbnail_url"`
	ExpiresInSec int    `json:"expires_in_sec"`
}
