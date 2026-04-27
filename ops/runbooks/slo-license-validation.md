# SLO: License Validation API

## User journey

A local production application must validate a license and continue operating without disrupting a live production environment.

## Service-level objectives

- Availability: 99.9% successful license validations over 30 days
- Latency: p95 under 250ms for `/api/v1/license/validate`
- Error budget: 43.2 minutes per 30 days

## SLIs

- Successful validation request ratio:
  - Good: HTTP 200 with `valid=true` or a business-valid `valid=false` result
  - Bad: 5xx, timeout, malformed service response
- Latency:
  - p95 request duration from ALB/API perspective

## Alerts

- Page: 5xx rate above 2% for 5 minutes
- Page: p95 latency above 500ms for 10 minutes
- Ticket: database connection saturation above 80% for 15 minutes
- Ticket: Redis unavailable for 15 minutes

## Design note

For real desktop production use, the app should have a short offline grace period so a transient cloud outage does not interrupt a live event.
