## Internal design — pms-rttm

### Main components

- Kafka Consumers
  - `TradeEventConsumer`, `DlqEventConsumer`, `ErrorEventConsumer`, `QueueMetricConsumer`: listen to configured topics and enqueue events into the in-memory `BatchQueueService`.

- BatchQueueService
  - Central in-memory queue and batching facility. Accepts events and exposes them to downstream services for aggregation and persistence. Offers backpressure (enqueue returns false when full/timeouts).

- Processing / Aggregation Services
  - `TpsMetricsService`, `LatencyMetricsService`, `InvalidTradeMetricsService`, `DlqMetricsService`, `PipelineDepthService`: calculate and aggregate metrics used by REST and WebSocket handlers.

- Alerting
  - `AlertGenerationService` and `AlertScheduler` evaluate thresholds defined in configuration and persist / surface alerts.

- REST controllers
  - `RttmController`, `TelemetrySnapshotController`, `TradeTrackingController`, `AlertsController` provide synchronous access to metrics, DLQ summaries, pipeline stage metrics and trade tracking.

- WebSocket handlers
  - Multiple `TextWebSocketHandler` implementations expose live telemetry and DLQ/alerts to the frontend on routes under `/ws/rttm/*`.

### Message and request flow (text)

1. External producers write protobuf messages to Kafka topics (trade events, dlq, error-events, queue-metrics).
2. Kafka consumers pick up messages and call `BatchQueueService.enqueue*`. If enqueue succeeds, consumer acknowledges the message; otherwise it leaves the message unacknowledged so Kafka will retry.
3. BatchQueueService drains events to internal processors which update DB tables and in-memory metrics stores.
4. Aggregation services compute TPS, latency P95/P99, pipeline depth and DLQ counts, storing aggregates in DB or cache for short-term retention.
5. REST endpoints expose snapshots; WebSocket handlers push periodic telemetry to connected clients.

### State management

- Persistent: PostgreSQL stores raw/aggregated events, alerts, DLQ entries and pipeline state.
- Ephemeral/fast-access: Redis Sentinel used for caching and temporary queue metadata.
- In-process memory: BatchQueueService keeps bounded in-memory queues which must be sized carefully.

### Scaling assumptions

- The service is horizontally scalable for consumers and processing workers. Kafka topic partitions provide parallelism for ingestion consumers.
- The in-memory queue introduces a per-instance memory limit: increase replicas or queue capacity to handle higher throughput.
- Alert evaluation and aggregation jobs can be scaled independently if needed.

### Textual diagram

Kafka topics (trade, dlq, error, metrics)
  -> Kafka consumers (TradeEventConsumer, DlqEventConsumer, ErrorEventConsumer, QueueMetricConsumer)
  -> BatchQueueService (in-memory queues)
  -> Aggregation services (Tps, Latency, DLQ, Pipeline)
  -> PostgreSQL + Redis
  -> REST controllers and WebSocket handlers (serve dashboards and APIs)
