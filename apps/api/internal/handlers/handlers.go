package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/example/rv-platform-demo/apps/api/internal/config"
	"github.com/example/rv-platform-demo/apps/api/internal/db"
	"github.com/example/rv-platform-demo/apps/api/internal/metrics"
	"github.com/example/rv-platform-demo/apps/api/internal/models"
	"github.com/go-redis/redis/v8"
	"github.com/jackc/pgx/v5"
)

type Handler struct {
	Cfg   config.Config
	Store *db.Store
	Redis *redis.Client
}

func New(cfg config.Config, store *db.Store, redisClient *redis.Client) *Handler {
	return &Handler{Cfg: cfg, Store: store, Redis: redisClient}
}

func (h *Handler) Healthz(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok", "service": "rv-platform-demo-api"})
}

func (h *Handler) Readyz(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()
	if err := h.Store.Ping(ctx); err != nil {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"status": "not_ready", "reason": "database_unavailable"})
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "ready"})
}

func (h *Handler) ValidateLicense(w http.ResponseWriter, r *http.Request) {
	var req models.LicenseValidationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid_json"})
		return
	}

	lic, err := h.Store.GetLicense(r.Context(), req.LicenseKey)
	if err != nil {
		if err == pgx.ErrNoRows {
			metrics.LicenseValidations.WithLabelValues("not_found").Inc()
			writeJSON(w, http.StatusOK, models.LicenseValidationResponse{Valid: false, Reason: "license_not_found", Region: region()})
			return
		}
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "license_lookup_failed"})
		return
	}

	if lic.Status != "active" || time.Now().After(lic.ExpiresAt) {
		metrics.LicenseValidations.WithLabelValues("expired_or_inactive").Inc()
		writeJSON(w, http.StatusOK, models.LicenseValidationResponse{Valid: false, Reason: "expired_or_inactive", Region: region()})
		return
	}

	if req.DeviceID != "" {
		_ = h.Store.UpsertDevice(r.Context(), lic.LicenseKey, req.DeviceID, req.DeviceID, "unknown", req.Version)
	}

	metrics.LicenseValidations.WithLabelValues("valid").Inc()
	writeJSON(w, http.StatusOK, models.LicenseValidationResponse{
		Valid:     true,
		Plan:      lic.Plan,
		ExpiresAt: lic.ExpiresAt,
		Features:  lic.Features,
		Region:    region(),
	})
}

func (h *Handler) RegisterDevice(w http.ResponseWriter, r *http.Request) {
	var req models.DeviceRegistrationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid_json"})
		return
	}

	lic, err := h.Store.GetLicense(r.Context(), req.LicenseKey)
	if err != nil {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "license_not_found"})
		return
	}

	count, err := h.Store.DeviceCount(r.Context(), req.LicenseKey)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "device_count_failed"})
		return
	}

	if count >= lic.MaxDevices {
		writeJSON(w, http.StatusConflict, map[string]string{"error": "device_limit_reached"})
		return
	}

	if err := h.Store.UpsertDevice(r.Context(), req.LicenseKey, req.DeviceID, req.Hostname, req.OS, req.AppVersion); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "device_registration_failed"})
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"status": "registered", "region": region()})
}

func (h *Handler) ContentEntitlements(w http.ResponseWriter, r *http.Request) {
	licenseKey := r.URL.Query().Get("license_key")
	if licenseKey == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "license_key_required"})
		return
	}

	lic, err := h.Store.GetLicense(r.Context(), licenseKey)
	if err != nil || lic.Status != "active" || time.Now().After(lic.ExpiresAt) {
		writeJSON(w, http.StatusForbidden, map[string]string{"error": "not_entitled"})
		return
	}

	items, err := h.Store.ContentForPlan(r.Context(), lic.Plan)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "content_lookup_failed"})
		return
	}

	resp := []models.ContentEntitlement{}
	for _, item := range items {
		resp = append(resp, models.ContentEntitlement{
			Slug:         item.Slug,
			Title:        item.Title,
			Category:     item.Category,
			DownloadURL:  fmt.Sprintf("%s/%s?signature=demo-signed-url", h.Cfg.ContentCDNBaseURL, item.ObjectKey),
			ThumbnailURL: fmt.Sprintf("%s/%s", h.Cfg.ContentCDNBaseURL, item.ThumbnailKey),
			ExpiresInSec: 900,
		})
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": resp, "region": region()})
}

func region() string {
	return "local-dfw"
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}
