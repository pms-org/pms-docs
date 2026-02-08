## pms-validation — Validation microservice

What this service does

- Validates incoming trade events using a Drools rules engine.
- Persists validation outcomes (valid and invalid) to database outbox tables.
- Publishes validated trade events to Kafka (downstream consumers) and persists poison messages to a DLQ table.
- Provides test-only HTTP endpoints to simulate trades (should be gated behind the API gateway in production).

Responsibilities in the PMS platform

- Consume trade messages from the ingestion Kafka topic (configured by `app.incoming-trades-topic`).
- Perform idempotent validation of trades and record outcomes.
- Publish validated trade events to the configured outbound Kafka topic(s) (`app.outgoing-valid-trades-topic` / `app.outgoing-invalid-trades-topic`).
- Emit operational events to the RTTM client (trade validated, DLQ/error events).

Who consumes it

- Downstream backend services (via Kafka valid/invalid topics).
- RTTM service (for operational / observability events).
- Not intended to be called directly by the frontend; the provided `/trade-simulator` endpoints are for test/dev only.

High-level dependencies

- Kafka (broker and Schema Registry). Protobuf-based messages are used.
- PostgreSQL (JPA/Hibernate) for persistence of outbox, invalid-trades, and DLQ.
- Redis (Sentinel) used for short-lived idempotency locks and caching.
- Drools (KIE) for the validation rules engine.
- RTTM client library (internal) to publish monitoring / DLQ events.
- Spring Boot Actuator for health metrics.

Read this file in ~5 minutes to get the gist; the other files describe architecture, configuration, deployment and how to debug common failures.
