package models

import (
	"encoding/json"
	"testing"
	"time"
)

func TestLicenseValidationResponseJSON(t *testing.T) {
	exp := time.Date(2026, 12, 31, 0, 0, 0, 0, time.UTC)
	resp := LicenseValidationResponse{
		Valid:     true,
		Plan:      "pro",
		ExpiresAt: exp,
		Features:  []string{"procontent", "bibles"},
		Region:    "us-east-1",
	}

	b, err := json.Marshal(resp)
	if err != nil {
		t.Fatalf("marshal failed: %v", err)
	}

	var out LicenseValidationResponse
	if err := json.Unmarshal(b, &out); err != nil {
		t.Fatalf("unmarshal failed: %v", err)
	}

	if !out.Valid {
		t.Error("expected Valid=true")
	}
	if out.Plan != "pro" {
		t.Errorf("expected Plan=pro, got %q", out.Plan)
	}
	if len(out.Features) != 2 {
		t.Errorf("expected 2 features, got %d", len(out.Features))
	}
	if out.Region != "us-east-1" {
		t.Errorf("expected Region=us-east-1, got %q", out.Region)
	}
}

func TestLicenseValidationResponseInvalidOmitsFields(t *testing.T) {
	resp := LicenseValidationResponse{Valid: false, Reason: "expired_or_inactive", Region: "us-west-2"}
	b, _ := json.Marshal(resp)

	var m map[string]any
	json.Unmarshal(b, &m)

	if _, ok := m["plan"]; ok {
		t.Error("plan should be omitted when empty")
	}
	if _, ok := m["features"]; ok {
		t.Error("features should be omitted when nil")
	}
	if m["reason"] != "expired_or_inactive" {
		t.Errorf("unexpected reason: %v", m["reason"])
	}
}

func TestDeviceRegistrationRequestJSON(t *testing.T) {
	req := DeviceRegistrationRequest{
		LicenseKey: "RV-DEMO-1234",
		DeviceID:   "foh-imac",
		Hostname:   "foh-imac.local",
		OS:         "macOS",
		AppVersion: "7.18.0",
	}
	b, err := json.Marshal(req)
	if err != nil {
		t.Fatalf("marshal failed: %v", err)
	}
	var out DeviceRegistrationRequest
	if err := json.Unmarshal(b, &out); err != nil {
		t.Fatalf("unmarshal failed: %v", err)
	}
	if out.LicenseKey != req.LicenseKey {
		t.Errorf("LicenseKey mismatch: got %q", out.LicenseKey)
	}
}
