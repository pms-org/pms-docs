---
sidebar_position: 7
title: Failure Modes
---

# Analytics Service — Failure Modes & Debugging

## Kafka Consumer Lag

Symptoms:

- Delayed dashboard updates

Diagnosis:

- Check Kafka lag metrics
- Inspect consumer logs

Resolution:

- Scale pods
- Increase partition count

---

## Market Price Fetch Failure

Symptoms:

- Unrealised PnL becomes stale

Diagnosis:

- Finnhub API errors
- Missing Redis keys

Expected Behavior:

- > 30 second delay acceptable

Abnormal Behavior:

- > 2 minute delay

---

## Unrealised PnL Not Updating

Symptoms:

- Dashboard frozen

Diagnosis:

- Finnhub rate limit exceeded
- Redis cache empty
- Scheduler logs missing

---

## Database Connectivity Issues

Symptoms:

- HTTP 500 errors
- Readiness probe failures

Resolution:

- Verify DB credentials
- Check network connectivity

---

## Redis Unavailable

Symptoms:

- Increased response latency

Behavior:

- Service continues without cache
- Unrealised PnL updates slow down

---

## Risk Metrics Not Updating

Symptoms:

- Leaderboard stale

Diagnosis:

- Midnight snapshot job failure
- Kafka outbox publishing errors

---

## Observability

- Structured logs include portfolioId and symbol
- Prometheus metrics exported
- Alerts configured for Kafka lag and DB errors
