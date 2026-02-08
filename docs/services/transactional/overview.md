**Service Purpose**

This service (pms-transactional) converts incoming trade events into persisted trades, matched transactions and outbox events that are published for downstream consumers. It implements the transactional piece of the trade pipeline: validate/persist trade messages, match SELLs to prior BUYs (FIFO by timestamp), and reliably publish resulting `Transaction` protobuf messages to Kafka using an outbox pattern.

**Responsibilities**

- Consume `Trade` protobuf messages from the trades topic and process them in batches.
- Persist `trades` and `transactions` into PostgreSQL.
- Produce `Transaction` protobuf messages to the publishing Kafka topic via an outbox dispatcher.
- Accept HTTP publish requests (two endpoints) to inject trades (useful for integration / tests).

**Who consumes it**

- Analytics/reporting services (via the `Transaction` Kafka topic).
- Internal telemetry (RTTM) receives lifecycle events about consumed and committed trades.

**High-level dependencies**

- PostgreSQL (JPA / JDBC) — tables: `trades`, `transactions`, `outbox_events`, `invalid_trades`.
- Apache Kafka + Confluent Schema Registry (protobuf serializers/deserializers).
- `pms-rttm-client` (telemetry client used to publish trade lifecycle events).
- Spring Boot, Spring Kafka, Hibernate.

Keep reading for architecture, API, configuration and operational runbook.
