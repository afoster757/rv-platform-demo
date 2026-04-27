# Incident Runbook: License API Elevated Errors

## Symptoms

- Users report failed activation or subscription validation
- Alert fires for API 5xx or high p95 latency
- Support tickets mention devices failing to register

## First checks

1. Check ALB target health.
2. Check ECS service desired vs running task count.
3. Check recent deploy SHA and rollback status.
4. Check RDS CPU, connections, and storage.
5. Check Redis availability.
6. Check CloudWatch logs for error spikes.

## Fast mitigation

1. Roll back the last API deployment.
2. Increase ECS desired count if CPU/memory pressure is high.
3. Temporarily increase RDS connection capacity if saturated.
4. Enable emergency cached validation mode if DB is impaired.
5. Communicate customer impact and estimated scope.

## Follow-up

- Add regression test if deploy-caused.
- Update SLO burn-rate alert if detection was delayed.
- Add dashboard panel if diagnosis required manual querying.
