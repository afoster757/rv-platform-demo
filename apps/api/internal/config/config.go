package config

import "os"

type Config struct {
	Env               string
	Port              string
	Region            string
	DatabaseURL       string
	RedisAddr         string
	ContentCDNBaseURL string
}

func Load() Config {
	return Config{
		Env:               value("APP_ENV", "local"),
		Port:              value("PORT", "8080"),
		Region:            value("AWS_REGION", value("FLY_REGION", "local")),
		DatabaseURL:       value("DATABASE_URL", "postgres://rv_demo:rv_demo@localhost:5432/rv_demo?sslmode=disable"),
		RedisAddr:         value("REDIS_ADDR", "localhost:6379"),
		ContentCDNBaseURL: value("CONTENT_CDN_BASE_URL", "https://cdn.example.com/content"),
	}
}

func value(key string, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
