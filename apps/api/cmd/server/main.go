package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/example/rv-platform-demo/apps/api/internal/config"
	"github.com/example/rv-platform-demo/apps/api/internal/db"
	"github.com/example/rv-platform-demo/apps/api/internal/handlers"
	"github.com/example/rv-platform-demo/apps/api/internal/metrics"
	"github.com/go-chi/chi/v5"
	"github.com/go-redis/redis/v8"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
	cfg := config.Load()
	ctx := context.Background()

	store, err := db.New(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("database connection failed: %v", err)
	}
	defer store.Pool.Close()

	redisClient := redis.NewClient(&redis.Options{Addr: cfg.RedisAddr})
	metrics.Register()

	h := handlers.New(cfg, store, redisClient)
	r := chi.NewRouter()
	r.Use(requestMetrics)

	r.Get("/healthz", h.Healthz)
	r.Get("/readyz", h.Readyz)
	r.Handle("/metrics", promhttp.Handler())
	r.Post("/api/v1/license/validate", h.ValidateLicense)
	r.Post("/api/v1/device/register", h.RegisterDevice)
	r.Get("/api/v1/content/entitlements", h.ContentEntitlements)

	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      r,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	log.Printf("starting api env=%s port=%s pid=%d", cfg.Env, cfg.Port, os.Getpid())
	log.Fatal(srv.ListenAndServe())
}

func requestMetrics(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rw := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(rw, r)
		metrics.HTTPRequestDuration.WithLabelValues(r.Method, r.URL.Path, http.StatusText(rw.status)).Observe(time.Since(start).Seconds())
	})
}

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (r *statusRecorder) WriteHeader(code int) {
	r.status = code
	r.ResponseWriter.WriteHeader(code)
}
