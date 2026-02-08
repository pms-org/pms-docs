## pms-rttm — RTTM (Real-Time Trade Monitoring) service

What this service does

- Ingests operational events related to trades (trade events, DLQ events, error events, queue metrics) from Kafka and stores/aggregates telemetry and metrics.
- Provides dashboards and query endpoints for RTTM metrics (TPS, latency, DLQ counts, pipeline depth) and trade tracking.
- Emits alerts based on configurable thresholds (latency, error rate, DLQ growth, queue depth).
- Exposes WebSocket endpoints for live telemetry to front-end dashboards.

Responsibilities in the PMS platform

- Collect and aggregate runtime telemetry for trade processing across services.
- Maintain DLQ and error visibility (persistence, counts and drill-downs).
- Provide near-real-time metrics to UIs via WebSockets and REST endpoints.
- Generate alerts for operational anomalies and surface them for on-call engineering.

Who consumes it

- Frontend dashboards and operations consoles (via WebSocket and REST APIs).
- Other backend services may query metrics and DLQ summaries via REST.
- On-call engineers and automated alerting systems consume generated alerts.

High-level dependencies

- Kafka (topics for trade events, DLQ, error events, queue metrics).
- PostgreSQL for persistence of events, alerts, and aggregated metrics.
- Redis (Sentinel) for in-memory queues / caching and short-lived state.
- WebSocket connections for live telemetry.
- Spring Boot Actuator for health checks.

This overview gives enough context to understand the service's purpose; see the other files for architecture, APIs, security, configuration and debugging guidance.
