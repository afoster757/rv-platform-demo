package metrics

import "github.com/prometheus/client_golang/prometheus"

var (
	LicenseValidations = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "license_validation_total",
			Help: "Total license validation attempts by result.",
		},
		[]string{"result"},
	)

	HTTPRequestDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "HTTP request latency by route and method.",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "route", "status"},
	)
)

func Register() {
	prometheus.MustRegister(LicenseValidations, HTTPRequestDuration)
}
