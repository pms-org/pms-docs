## Runtime configuration — pms-rttm

Configuration sources

- The service uses Spring Boot `application.yml` and environment variables. Runtime values should be provided via Kubernetes `ConfigMap`s and `Secret`s.

Important environment variables and properties (from `application.yml`)

- Database
  - `DB_HOST`, `DB_PORT`, `DB_NAME` (default `pmsdb`), `DB_USERNAME`, `DB_PASSWORD` — Postgres connection. Missing DB credentials will prevent startup or meaningful operation.

- Redis (Sentinel)
  - `REDIS_SENTINEL_MASTER`, `REDIS_SENTINEL_NODES` (comma separated), `REDIS_PASSWORD`, `REDIS_SENTINEL_PASSWORD`, `REDIS_TIMEOUT` (default `2s`).

- Kafka & Schema Registry
  - `KAFKA_BOOTSTRAP_SERVERS` (required), `KAFKA_CONSUMER_GROUP_ID` (required for consumers), `SCHEMA_REGISTRY_URL` (required for protobuf deserialization).

- RTTM tuning and topics
  - `KAFKA_TOPIC_TRADE_EVENTS` (default `rttm.trade.events`)
  - `KAFKA_TOPIC_DLQ_EVENTS`, `KAFKA_TOPIC_ERROR_EVENTS`, `KAFKA_TOPIC_QUEUE_METRICS`, `KAFKA_TOPIC_INVALID_TRADES`
  - `RTTM_BATCH_SIZE` (default 100), `RTTM_BATCH_POLL_MS` (default 2000)
  - `RTTM_QUEUE_CAPACITY` (default 10000) — capacity of in-process queues; setting this too low will cause enqueue to fail and leave messages unacked.

- Alert thresholds and retention
  - A number of alert thresholds and retention settings exist under `rttm.queue-metrics` and `rttm.alerts` (latency warning/critical, error-rate, dlq thresholds, queue-depth thresholds, TPS thresholds). These are tuned per environment.

What happens if values are missing

- Missing Kafka or Schema Registry configuration will result in consumer/producer failures and protobuf deserialization errors.
- Missing DB credentials will either fail startup (if required by Spring) or cause runtime failures when services attempt to persist aggregates.
- If `RTTM_QUEUE_CAPACITY` is too small for traffic, consumers will not acknowledge messages (enqueue fails) and Kafka will re-deliver until the backlog persists; monitor consumer lag.

ConfigMaps vs Secrets

- Keep non-sensitive tuning parameters in a `ConfigMap`.
- Keep credentials (DB, Kafka, Redis, Schema Registry auth) in `Secret`s.

Dev vs Prod differences

- Local/dev: `docker-compose` files in the repository provide a quick environment; these use defaults and often do not enforce TLS or auth for Kafka/Schema Registry.
- Production: ensure secure Kafka setup (TLS/SASL), restricted WebSocket origins, Secrets for all credentials, and proper readiness/liveness probes.
