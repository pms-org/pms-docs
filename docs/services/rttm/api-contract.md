## API contract — pms-rttm

This service exposes both HTTP REST APIs and WebSocket endpoints. Kafka topics are the primary ingestion mechanism.

REST endpoints (base path: `/api/rttm`)

- GET /api/rttm/metrics
  - Purpose: Return a list of metric cards (Current TPS, Peak TPS, Avg Latency, DLQ Count, Invalid Trades).
  - Authentication: None implemented in-service; must be protected at the API Gateway in production.

- GET /api/rttm/pipeline
  - Purpose: Return pipeline stage metrics (counts, latency, success rate) for each stage of the processing pipeline.
  - Query params: none.
  - Authentication: platform-level.

- GET /api/rttm/dlq
  - Purpose: Return DLQ overview (total count and breakdown by stage).
  - Authentication: platform-level.

- GET /api/rttm/telemetry-snapshot
  - Purpose: Return a snapshot of TPS trend and latency metrics (used by dashboards).
  - Authentication: platform-level.

- GET `/api/rttm/track-trade?tradeId=<uuid>`
  - Purpose: Returns the tracking/telemetry history for a single trade (by tradeId).
  - Query params: `tradeId` (UUID) — required.

- GET /api/rttm/alerts?status=ACTIVE&limit=10
  - Purpose: List latest alerts filtered by status (default: ACTIVE) and limited by `limit`.

WebSocket endpoints

The service registers WebSocket handlers (see `WebSocketConfig`) on these paths:

- /ws/rttm/metrics — live metrics (periodic pushes)
- /ws/rttm/pipeline — pipeline stage telemetry
- /ws/rttm/dlq — DLQ overview updates
- /ws/rttm/telemetry — combined telemetry feed (TPS trend, latency)
- /ws/rttm/alerts — live active alerts

Notes about WebSockets

- The WebSocket handlers send periodic JSON messages (every 2–3s). Connections are un-authenticated in the code and `setAllowedOrigins("*")` is configured — secure at ingress in production.
- Clients should reconnect on close and handle fallback messages (handlers send a minimal fallback payload on errors).

Kafka topics (ingress)

- Configured in `application.yml` under `kafka.topics` and `rttm.*`:
  - `trade-events` (e.g., `rttm.trade.events`) — trade events to ingest
  - `dlq-events` — DLQ events
  - `error-events` — error event notifications
  - `queue-metrics` — queue/lag metrics
  - `invalid-trades` — invalid trade events

Authentication

- The service does not add application-level HTTP auth. Protect all endpoints and websocket routes using the API Gateway or network controls. Kafka/DB/Redis auth should be configured and provided via Secrets.
