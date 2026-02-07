## Internal design — pms-validation

### Main components

- Kafka consumer (batch listener)
  - Uses a protobuf-based Kafka listener (`protobufKafkaListenerContainerFactory`).
  - Receives batches of `TradeEventProto` and packages them into `PollBatch` objects.

- In-memory buffer (`LinkedBlockingDeque<PollBatch>`)
  - Buffers incoming poll batches to allow batching and backpressure handling.

- ValidationBatchProcessor
  - Collects buffered poll batches into a single logical batch (configurable `app.validation.batch.size`).
  - Executes batch processing in a thread-pool and schedules periodic flushes (`app.validation.flush-interval-ms`).
  - Pauses Kafka consumption on systemic failures (e.g., DB down) and resumes after recovery checks.

- ValidationBatchProcessingService
  - Transactional component that iterates each trade DTO in the batch:
    - Uses `TradeIdempotencyService` (Redis) to obtain a short processing reservation and to avoid duplicates.
    - Calls `ValidationCore` (Drools) to produce either a `ValidationOutboxEntity` (valid) or `InvalidTradeEntity` (invalid).
    - Persists outbox/invalid entities in the same transaction.
    - After commit, marks processed IDs as DONE in Redis and notifies RTTM.

- ValidationOutboxEventProcessor
  - Periodic dispatcher that reads pending `validation_outbox` rows (with portfolio-level advisory locks) and publishes them to the configured Kafka topic.
  - Marks outbox entries as SENT on success; on serialization/poison errors it persists to `validation_dlq_entry` and marks the outbox FAILED.

- Idempotency (TradeIdempotencyService)
  - Simple Redis key scheme: `trade:{tradeId}` with PROCESSING and DONE states.
  - PROCESSING TTL is short (5 minutes); DONE TTL is longer (7 days).

### Request / message flow (textual)

1. Producer (external system) publishes a TradeEvent (protobuf) to the ingestion topic.
2. `KafkaConsumerService` receives a batch of records and enqueues a `PollBatch` into the `validationBuffer`.
3. `ValidationBatchProcessor` picks buffered `PollBatch` items and assembles a larger batch.
4. `ValidationBatchProcessingService` (transactional):
   - For each trade DTO: idempotency reservation -> Drools validation -> build outbox or invalid entity.
   - Save all outbox / invalid rows in the DB transaction.
   - After commit, mark Redis keys DONE for successfully processed trades.
5. `ValidationOutboxEventProcessor` picks pending outbox rows, converts to protobuf, and sends to `app.outgoing-valid-trades-topic`.
6. On serialization or downstream errors, the message is persisted to DLQ table and RTTM is notified.

### State management

- Persistent stores:
  - PostgreSQL: tables used include `validation_outbox`, `validation_invalid_trades`, `validation_dlq_entry` and additional reference tables.
  - Redis (Sentinel): used for idempotency locks (`trade:{id}`).
- Transient/in-memory:
  - In-process `LinkedBlockingDeque` buffer for incoming poll batches.

### Scaling and deployment model

- The service is horizontally scalable: deploy multiple replicas.
- Kafka partitioning determines parallelism. Consumers use the configured consumer group (`spring.kafka.consumer.group-id`) to distribute partitions across replicas.
- Idempotency via Redis and portfolio-level advisory locks in the outbox minimize duplicate processing and conflicting outbox dispatches.
- Batch sizes and flush intervals are configurable (`app.validation.batch.size`, `app.validation.flush-interval-ms`, `app.buffer.size`).

### Diagrams (text)

Kafka ingestion topic
  -> KafkaConsumerService (batch) -> validationBuffer -> ValidationBatchProcessor -> ValidationBatchProcessingService
    -> (DB) validation_outbox / validation_invalid_trades
    -> ValidationOutboxEventProcessor -> Kafka valid/invalid topics
