**Runtime Configuration**

Configuration is provided via `application.yml` which imports environment properties from `.env.properties` (see repo root). The service uses many `app.*` keys plus standard Spring `spring.*` settings.

Important environment variables / properties (names used in repo)

- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD` — PostgreSQL connection.
- `TRANSACTIONAL_SERVER_PORT` (defaults to 8084) or `SERVER_PORT` in `.env.properties`.
- `KAFKA_BOOTSTRAP_SERVERS` / `spring.kafka.bootstrap-servers` — Kafka brokers.
- `SCHEMA_REGISTRY_URL` — Confluent Schema Registry for protobuf serializers.
- `TRANSACTIONAL_TRANSACTIONS_PUBLISHING_TOPIC` — topic used for publishing `Transaction` protos (configured as `app.transactions.publishing-topic`).
- `TRANSACTIONAL_TRADES_CONSUMER_LISTENING_TOPIC` — topic from which this service consumes `Trade` protos.
- `TRANSACTIONAL_TRADES_CONSUMER_GROUP_ID` and `TRANSACTIONAL_TRADES_CONSUMER_CONSUMER_ID` — consumer group & listener id keys.

App-tunable parameters (defaults shown in `application.yml`)

- `app.batch.size` (default `${TRANSACTIONAL_BATCH_SIZE:5000}`) — number of trades to trigger a batch flush.
- `app.flush-interval-ms` (default `${TRANSACTIONAL_FLUSH_INTERVAL_MS:10000}`) — time-based flush interval for `BatchProcessor`.
- `app.buffer.size` (default `${TRANSACTIONAL_BUFFER_SIZE:50}`) — in-memory number of PollBatches the buffer should hold.
- Outbox tuning: `app.outbox.target-latency-ms`, `app.outbox.min-batch`, `app.outbox.max-batch`.

ConfigMaps and Secrets

- Put non-sensitive app config (tuning numbers, topic names) in a `ConfigMap`.
- Put secrets (DB username/password, schema-registry credentials if any, Kafka credentials) in Kubernetes `Secret` objects and mount as environment variables.

What happens if a value is missing

- Missing DB creds or `DB_HOST` -> datasource will fail to initialize; `BatchProcessor` will detect DB failures at runtime and pause consumption. Application startup may fail depending on Spring's datasource setup.
- Missing Kafka or Schema Registry info -> producers/consumers will fail at runtime; outbox dispatch will experience send errors and backoff.

Dev vs Prod

- Dev: `.env.properties` in repo contains local defaults for quick local runs (example values point at localhost). Do NOT copy secret values into repo for production.
- Prod: provide real endpoints through environment variables or Kubernetes Secrets and use private network access to Kafka and Postgres.
