**Internal Design**

Components

- HTTP controllers: `EventController` and `EventControllerMulti` expose two POST endpoints for publishing single or multiple trades. These convert DTOs to the `Trade` protobuf and forward to the `KafkaTradeMessagePublisher`.
- Kafka consumer: `KafkaTradeMessageListner` (batch listener) receives `Trade` protos and delegates to `BatchProcessor`.
- `BatchProcessor`: buffers incoming poll batches, groups trades, enforces buffer backpressure, and triggers `TransactionService` when batch size or time-based flush limit is reached. It pauses/resumes the Kafka consumer when DB/backpressure issues occur.
- `TransactionService`: core business logic. It:
  - Constructs `TradesEntity` and `TransactionsEntity` records.
  - Matches SELLs to eligible BUYs (ordered by buy timestamp) and calculates matched `Transaction` entries.
  - Produces outbox `OutboxEventEntity` payloads (serialized `Transaction` protos) with status `PENDING`.
- Outbox: `OutboxDispatcher` picks pending outbox rows with a portfolio-level advisory lock (see DAO), then `OutboxEventProcessor` sends `Transaction` protos to Kafka and marks rows SENT or FAILED. Poison-pill events are moved into `invalid_trades` (DLQ).

Request flow (textual)

1. Trade message is published to the trades topic (either via HTTP endpoints or by upstream producers).
2. `KafkaTradeMessageListner` receives a batch of ConsumerRecords and forwards them to `BatchProcessor`.
3. `BatchProcessor` groups BUY and SELL trades and calls `TransactionService.processUnifiedBatch(...)`.
4. `TransactionService` creates `trades` rows, matching `transactions` rows and `outbox_events` rows (status=PENDING) in a single batch write.
5. `OutboxDispatcher` reads pending outbox events (portfolio-ordered using `pg_try_advisory_lock`), sends messages to the publishing Kafka topic and marks rows SENT; failures trigger backoff or DLQ movement.

State management

- Durable state in PostgreSQL tables: `trades`, `transactions`, `outbox_events`, `invalid_trades`.
- In-memory buffering: `LinkedBlockingDeque<PollBatch>` in `BatchProcessor` (size controlled by `app.buffer.size`).
- Kafka topics: trades (input), transactions (output), RTTM topics for telemetry.

Scaling assumptions

- Kafka consumers configured concurrency = 5 (see `tradekafkaListenerContainerFactory()`), so the application may run with multiple replicas; ordering guarantees are preserved per-portfolio by the outbox advisory-lock approach and by partitioning the Kafka producer sends using portfolioId as the key.
- Batch sizes (default 5000) and buffer size are configurable; CPU-bound processing is done in a `batchExecutor` thread pool and outbox dispatch uses an `outboxExecutor`.

Notes

- The system is sensitive to DB availability; `BatchProcessor` will pause consumption and run a DB-recovery probe when the DB is unavailable.
- Outbox processing uses portfolio-level locks to avoid concurrent dispatch for the same portfolio.
