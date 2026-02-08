## Runtime configuration — pms-validation

Configuration sources

- The service reads configuration from Spring `application.yml` and environment variables. Production deployments should provide values via Kubernetes `ConfigMap`s and `Secret`s.

Important environment variables and Spring properties

- Database
  - DB_HOST (required) — database host
  - DB_PORT (required) — database port
  - DB_NAME (default: `pms_db`) — database name
  - DB_USERNAME (required) — database user (Secret)
  - DB_PASSWORD (required) — database password (Secret)
  - DB_DRIVER (default: `org.postgresql.Driver`)
  - DB_DDL_AUTO (default: `validate`) — Hibernate DDL behaviour

- Redis (Sentinel)
  - REDIS_SENTINEL_MASTER (default: `redis-master`)
  - REDIS_SENTINEL_NODES (default: `sentinel-1:26379,sentinel-2:26379,sentinel-3:26379`)
  - REDIS_PASSWORD (optional, Secret)
  - REDIS_SENTINEL_PASSWORD (optional, Secret)
  - REDIS_TIMEOUT (default: `2s`)

- Kafka & Schema Registry
  - KAFKA_BOOTSTRAP_SERVERS (default: `localhost:9092`) — broker list
  - KAFKA_CONSUMER_GROUP_ID (no default; required for consumer grouping)
  - SCHEMA_REGISTRY_URL (required when using protobuf serialization)

- Topics / behavior
  - INCOMING_TRADES_TOPIC -> `app.incoming-trades-topic` (required)
  - OUTGOING_VALID_TRADES_TOPIC -> `app.outgoing-valid-trades-topic` (required)
  - OUTGOING_INVALID_TRADES_TOPIC -> `app.outgoing-invalid-trades-topic` (required)

- Service tuning
  - VALIDATION_BUFFER_SIZE / app.buffer.size (default: 50) — in-memory poll-batch buffer capacity
  - VALIDATION_BATCH_SIZE / app.validation.batch.size (default: 1000) — number of trades to collect for processing
  - VALIDATION_FLUSH_INTERVAL_MS / app.validation.flush-interval-ms (default: 5000) — periodic flush interval in ms
  - SERVER_PORT (default: 8083)

- RTTM client
  - RTTM_MODE, RTTM-related Kafka topics and timeouts (see `rttm.client` in `application.yml`). Configure these per-platform requirements.

What happens if values are missing

- Required missing values will typically cause Spring to fail startup (e.g., missing DB credentials) or the runtime to misbehave (e.g., missing topic names or Schema Registry URL will cause Kafka serialization/deserialization failures).
- Defaults exist for many non-sensitive values (batch sizes, ports, sentinel defaults). Do not rely on defaults for production (explicitly set all platform envs).

ConfigMaps vs Secrets

- Put non-sensitive tuning parameters in a `ConfigMap`.
- Put credentials (DB_USERNAME, DB_PASSWORD, KAFKA credentials, Redis passwords, Schema Registry credentials) in a `Secret`.

Dev vs Prod differences

- Locally you can use the `docker/docker-compose.yml` for quick startups; it uses local service addresses and does not mirror the hardened production configuration (TLS/SASL on Kafka, secured Schema Registry, private DB).
- In production:
  - Use secured Kafka (TLS + SASL or mTLS) and a protected Schema Registry.
  - Do not expose the `/trade-simulator` endpoints publicly.
  - Configure health & liveness probes pointing to the actuator endpoints.
